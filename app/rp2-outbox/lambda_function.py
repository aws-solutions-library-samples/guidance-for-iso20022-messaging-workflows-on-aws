# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime, timezone
from env import Variables
from util import get_request_arn, dynamodb_put_item, dynamodb_get_by_item, s3_get_object, lambda_validate, lambda_response

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
    if 'headers' in event and event['headers'] and 'X-Transaction-Id' in event['headers'] and event['headers']['X-Transaction-Id']:
        id = event['headers']['X-Transaction-Id']
    LOGGER.debug(f'computed id: {id}')
    msg = None
    if 'headers' in event and event['headers'] and 'X-Message-Type' in event['headers'] and event['headers']['X-Message-Type']:
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
    elif 'identity' in event:
        identity = event['identity']
    LOGGER.debug(f'computed identity: {identity}')
    region = VARIABLES.get_rp2_region()
    bucket = VARIABLES.get_rp2_bucket()
    table = VARIABLES.get_rp2_ddb_tnx()
    replicated = None
    check_ddb = int(VARIABLES.get_rp2_check_ddb())
    if check_ddb > 0:
        region2 = VARIABLES.get_rp2_check_region()
        replicated = {
            'api_url': VARIABLES.get_rp2_api_url().replace(region, region2),
            'auth': {
                'auth_url': VARIABLES.get_rp2_auth_url().replace(region, region2),
                'client_id': VARIABLES.get_rp2_check_client_id(),
                'client_secret': VARIABLES.get_rp2_check_client_secret(),
            },
            'count': check_ddb
        }
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

    # step 2: validate event
    response = lambda_validate(event, request_id)
    if response:
        LOGGER.warning(f'got validate: {response}')
        item['transaction_code'] = 'TECH'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'got response: {response}')
        return response

    # step 3: initialize variables
    metadata = {
        'ErrorCode': 'NARR',
        'ErrorMessage': 'rejected (see narrative reason)',
        'TransactionId': id,
        'RequestId': request_id,
    }

    try:
        LOGGER.debug(f'sent request: ACSC {id}')
        response = dynamodb_get_by_item(region, table, {**item, 'transaction_status': 'ACSC'})
        LOGGER.debug(f'response: {response}')
        if 'Item' in response and response['Item'] and 'storage_path' in response['Item']:
            object = response['Item']['storage_path']
            item['transaction_id'] = response['Item']['transaction_id']
            item['message_id'] = response['Item']['message_id']

        else:
            item['transaction_status'] = 'MISS'
            response = dynamodb_put_item(region, table, item, replicated)
            LOGGER.error(f'got response: {response}')
            metadata['ErrorCode'] = 'MISS'
            metadata['ErrorMessage'] = 'missing object in s3'
            return lambda_response(400, msg, metadata, TIME)

    except Exception as e:
        msg = str(e)
        LOGGER.warning(f'{msg}: {event}')
        return lambda_response(400, msg, {'RequestId': request_id}, TIME)

    # step 4: retrieve file
    try:
        del item['transaction_code']
        item['transaction_status'] = 'RCVD'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'got response: {response}')

        response = s3_get_object(region, bucket, object)
        LOGGER.debug(f'got response: {response}')

    except Exception as e:
        msg = 'retrieving message from s3 failed'
        LOGGER.warning(f'attempted to save item: {item}')
        LOGGER.warning(f'attempted to retrieve object: {object}')
        LOGGER.error(f'{msg}: {str(e)}')
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'got response: {response}')
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata, TIME)

    # step 5: trigger response
    LOGGER.info(f'successful execution: {item}')
    return {
        'statusCode': 200,
        'body': response['object'],
        # @TODO: Refactor response to include duration time
        # 'body': {
        #     'code': 200,
        #     'message': response['object'],
        #     'request_duration': (datetime.now(timezone.utc)-TIME).total_seconds()
        # },
        'headers': {
            'Content-Type': 'application/json'
        }
    }

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
