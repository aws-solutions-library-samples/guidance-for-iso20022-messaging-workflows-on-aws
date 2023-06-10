# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, json, xmltodict
from datetime import datetime, timezone
from env import Variables
from util import get_request_arn, dynamodb_put_item, dynamodb_get_by_item, lambda_validate, lambda_response, s3_put_object, sqs_send_message

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def lambda_handler(event, context):
    # log time, event and context
    TIME = datetime.now(timezone.utc)
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

    # step 1: get headers and context
    id = None
    if 'Records' in event and 'attributes' in event['Records'][0] and 'MessageDeduplicationId' in event['Records'][0]['attributes']:
        id = event['Records'][0]['attributes']['MessageDeduplicationId']
    elif 'headers' in event and event['headers'] and 'X-Transaction-Id' in event['headers'] and event['headers']['X-Transaction-Id']:
        id = event['headers']['X-Transaction-Id']
    LOGGER.debug(f'computed id: {id}')
    msg = None
    if 'Records' in event and 'attributes' in event['Records'][0] and 'MessageGroupId' in event['Records'][0]['attributes']:
        msg = event['Records'][0]['attributes']['MessageGroupId']
    elif 'headers' in event and event['headers'] and 'X-Message-Type' in event['headers'] and event['headers']['X-Message-Type']:
        msg = event['headers']['X-Message-Type']
    LOGGER.debug(f'computed msg: {msg}')
    request_id = None
    if context and context.aws_request_id:
        request_id = context.aws_request_id
    LOGGER.debug(f'computed request_id: {request_id}')
    request_arn = {}
    if context and context.invoked_function_arn:
        request_arn = get_request_arn(context.invoked_function_arn)
    LOGGER.debug(f'computed request_arn: {request_arn}')
    identity = None
    if 'requestContext' in event and event['requestContext']:
        if 'authorizer' in event['requestContext'] and event['requestContext']['authorizer']:
            identity = event['requestContext']['authorizer']['claims']['sub']
        elif 'identity' in event['requestContext'] and event['requestContext']['identity']:
            identity = event['requestContext']['identity']['userArn']
    elif 'identity' in event and event['identity']:
        identity = event['identity']
    LOGGER.debug(f'computed identity: {identity}')
    region = VARIABLES.get_rp2_region()
    table = VARIABLES.get_rp2_ddb_tnx()
    replicated = None
    check_ddb = int(VARIABLES.get_rp2_check_ddb())
    if check_ddb > 0:
        region2 = VARIABLES.get_rp2_check_region()
        replicated = {'region': region, 'region2': region2, 'count': check_ddb, 'identity': identity}
    LOGGER.debug(f'computed replicated: {replicated}')
    item = {
        'created_at': TIME,
        'created_by': identity,
        'message_id': msg[:8] if msg else None,
        'transaction_id': id,
        'transaction_status': 'RJCT',
        'transaction_code': 'NARR',
    }
    item = {**item, **request_arn}
    LOGGER.debug(f'computed item: {item}')

    body = ""
    if 'Records' in event and 'body' in event['Records'][0]:
        body = event['Records'][0]['body']
    elif 'body' in event:
        body = event['body']

    # step 2: validate event
    response = lambda_validate(event, request_id)
    if response:
        msg = 'lambda validation failed'
        LOGGER.warning(f'{msg}: {response}')
        item['transaction_code'] = 'TECH'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
        return response

    # step 3: initialize variables
    metadata = {
        'ErrorCode': 'NARR',
        'ErrorMessage': 'rejected (see narrative reason)',
        'TransactionId': id,
        'RequestId': request_id,
    }

    object_name = str(id) if msg == None else str(id) + '-' + msg
    if 'headers' in event and event['headers'] and 'Content-Type' in event['headers'] and event['headers']['Content-Type']:
        object_ext = event['headers']['Content-Type'].split('/')[1]
    else:
        object_ext = 'xml'

    # step 4: backup message to s3
    try:
        bucket = VARIABLES.get_rp2_bucket()
        response = s3_put_object(region, bucket, 'inbox', object_name, object_ext, body, TIME)
        item['storage_path'] = response['path']
        item['storage_type'] = object_ext

    except Exception as e:
        msg = 'saving message to s3 failed'
        LOGGER.warning(f'attempted to save object: {body}')
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata, TIME)

    # step 5: check previous transaction statuses
    try:
        LOGGER.debug(f'dynamodb_get_by_item: {item}')
        response = dynamodb_get_by_item(region, table, item)
        LOGGER.debug(f'dynamodb_get_by_item: {response}')
        if response['Statuses'] != ['FLAG', 'ACCP']:
            metadata['ErrorMessage'] = 'transaction statuses are out of order'
            LOGGER.warning(f'{metadata["ErrorMessage"]}: {response}')
            item['transaction_code'] = 'FF02'
            response = dynamodb_put_item(region, table, item, replicated)
            LOGGER.debug(f'dynamodb_put_item msg: {metadata["ErrorMessage"]}')
            LOGGER.debug(f'dynamodb_put_item response: {response}')
            sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
            return lambda_response(400, metadata['ErrorMessage'], metadata, TIME)
        else:
            item['created_by'] = response['Items'][0]['created_by']

    except Exception as e:
        msg = 'retrieving item from dynamodb failed'
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata, TIME)

    # step 6: parse inbox message
    # try:
    #     if object_ext == 'json':
    #         body = json.loads(body)
    #     else:
    #         body = xmltodict.parse(body)

    # except Exception as e:
    #     msg = f'parsing {object_ext} failed'
    #     LOGGER.error(f'{msg}: {str(e)}')
    #     response = dynamodb_put_item(region, table, item, replicated)
    #     LOGGER.debug(f'dynamodb_put_item msg: {msg}')
    #     LOGGER.debug(f'dynamodb_put_item response: {response}')
    #     sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
    #     metadata['ErrorMessage'] = str(e)
    #     return lambda_response(400, msg, metadata, TIME)

    # step 7: send the message to next sqs queue
    try:
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)

    except Exception as e:
        msg = 'sending sqs message failed'
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata, TIME)

    # step 8: save item into dynamodb
    try:
        del item['transaction_code']
        msg = 'transaction received successfully'
        item['transaction_status'] = 'ACTC'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')

    except Exception as e:
        msg = 'saving item to dynamodb failed'
        LOGGER.warning(f'attempted to save item: {item}')
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        sqs_send_message(region, 'rp2-process.fifo', item['request_account'], body, msg, id)
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata, TIME)

    # step 9: trigger response
    metadata = {
        'TransactionId': id,
        'RequestId': request_id,
        'RegionId': VARIABLES.get_rp2_region(),
        'ApiEndpoint': VARIABLES.get_rp2_api_url(),
    }
    if 'replicated' in response and response['replicated']:
        metadata['DynamodbReplicated'] = response['replicated']
    LOGGER.info(f'{msg}: {item}')
    return lambda_response(201, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
