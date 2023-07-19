# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime
from env import Variables
from util import get_request_arn, get_filtered_statuses, dynamodb_put_item, dynamodb_query_by_item, s3_get_object, lambda_validate, lambda_response

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def lambda_handler(event, context):
    # log time, event and context
    TIME = datetime.utcnow()
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

    # step 1: get headers and context
    id = None
    if 'headers' in event and event['headers'] and 'X-Transaction-Id' in event['headers'] and event['headers']['X-Transaction-Id']:
        id = event['headers']['X-Transaction-Id']
    LOGGER.debug(f'computed transaction_id: {id}')
    type = None
    if 'headers' in event and event['headers'] and 'X-Message-Type' in event['headers'] and event['headers']['X-Message-Type']:
        type = event['headers']['X-Message-Type']
    LOGGER.debug(f'computed type: {type}')
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
    elif 'identity' in event:
        identity = event['identity']
    LOGGER.debug(f'computed identity: {identity}')

    rp2_id = VARIABLES.get_rp2_env('RP2_ID')
    region = VARIABLES.get_rp2_env('RP2_REGION')
    region2 = VARIABLES.get_rp2_env('RP2_CHECK_REGION')
    runtime = VARIABLES.get_rp2_env('RP2_RUNTIME')
    table = VARIABLES.get_rp2_env('RP2_DDB_TNX')
    table = f'{table}-{rp2_id}'
    bucket = f'{runtime}-{region}-{rp2_id}'
    replicated = None
    ddb_retry = int(VARIABLES.get_rp2_env('RP2_DDB_RETRY'))
    if ddb_retry > 0:
        replicated = {'region': region, 'region2': region2, 'count': ddb_retry, 'identity': identity}
    LOGGER.debug(f'computed replicated: {replicated}')
    item = {
        'created_by': identity,
        'message_id': type[:8] if type else None,
        'request_timestamp': TIME,
        'transaction_id': id,
        'transaction_status': 'RJCT',
        'transaction_code': 'NARR',
    }
    item = {**item, **request_arn}
    LOGGER.debug(f'computed item: {item}')

    # step 2: validate event
    response = lambda_validate(event, request_id)
    if response:
        msg = 'lambda validation failed'
        LOGGER.warning(f'{msg}: {response}')
        item['transaction_code'] = 'TECH'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        return response

    # step 3: initialize variables
    object = ''
    metadata = {
        'ErrorCode': 'NARR',
        'ErrorMessage': 'rejected (see narrative reason)',
        'RequestId': request_id,
        'RequestTimestamp': TIME,
        'TransactionId': id,
    }

    try:
        LOGGER.debug(f'dynamodb_query_by_item: {item}')
        response = dynamodb_query_by_item(region, table, item)
        LOGGER.debug(f'dynamodb_query_by_item: {response}')

        statuses = get_filtered_statuses(response['Statuses'], 'ACSC')
        if statuses['filtered'] != ['ACSC', 'ACSP', 'ACTC', 'ACCP']:
            item['transaction_status'] = 'MISS'
            msg = 'missing object in s3'
            metadata['ErrorCode'] = item['transaction_status']
            metadata['ErrorMessage'] = msg
            response = dynamodb_put_item(region, table, item, replicated)
            LOGGER.debug(f'dynamodb_put_item msg: {msg}')
            LOGGER.debug(f'dynamodb_put_item response: {response}')
            return lambda_response(400, msg, metadata)

        if statuses['index'] >= 0:
            object = response['Items'][statuses['index']]['storage_path']
            item['transaction_id'] = response['Items'][statuses['index']]['transaction_id']
            item['message_id'] = response['Items'][statuses['index']]['message_id']

    except Exception as e:
        msg = str(e)
        LOGGER.warning(f'{msg}: {event}')
        return lambda_response(400, msg, {'RequestId': request_id})

    # step 4: retrieve file
    try:
        del item['transaction_code']
        item['transaction_status'] = 'RCVD'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        response = s3_get_object(region, bucket, object)
        LOGGER.debug(f's3_get_object response: {response}')

    except Exception as e:
        msg = 'retrieving message from s3 failed'
        LOGGER.warning(f'attempted to save item: {item}')
        LOGGER.warning(f'attempted to retrieve object: {object}')
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata)

    # step 5: trigger response
    LOGGER.info(f'successful execution: {item}')
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': response['object'],
    }

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
