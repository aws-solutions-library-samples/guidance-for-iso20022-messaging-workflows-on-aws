# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, uuid, logging
from datetime import datetime
from env import Variables
from util import get_request_arn, dynamodb_query_by_item, dynamodb_put_item, lambda_response

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
    elif 'identity' in event and event['identity']:
        identity = event['identity']
    LOGGER.debug(f'computed identity: {identity}')

    rp2_id = VARIABLES.get_rp2_env('RP2_ID')
    region = VARIABLES.get_rp2_env('RP2_REGION')
    region2 = VARIABLES.get_rp2_env('RP2_CHECK_REGION')
    api_url = VARIABLES.get_rp2_env('RP2_API_URL')
    table = VARIABLES.get_rp2_env('RP2_DDB_TNX')
    table = f'{table}-{rp2_id}'
    health = VARIABLES.get_rp2_env('RP2_HEALTH')
    health = f'{health}-{rp2_id}'
    replicated = None
    ddb_retry = int(VARIABLES.get_rp2_env('RP2_DDB_RETRY'))
    if ddb_retry > 0:
        replicated = {'region': region, 'region2': region2, 'health': health, 'identity': identity, 'count': ddb_retry}
    LOGGER.debug(f'computed replicated: {replicated}')
    item = {
        'created_by': identity,
        'message_id': type[:8] if type else None,
        'request_timestamp': TIME,
        'transaction_status': 'ACCP',
    }
    item = {**item, **request_arn}
    LOGGER.debug(f'computed item: {item}')

    # step 2: initialize variables
    metadata = {
        'ErrorCode': 'NARR',
        'ErrorMessage': 'rejected (see narrative reason)',
        'RequestId': request_id,
        'RequestTimestamp': TIME,
    }

    # step 3: create and validate transaction_id
    count = 0
    limit = 3
    while count < limit:
        count += 1
        item['transaction_id'] = str(uuid.uuid4())
        LOGGER.debug(f'dynamodb_query_by_item item: {item}')
        response = dynamodb_query_by_item(region, table, item)
        LOGGER.debug(f'dynamodb_query_by_item response: {response}')
        if int(response['Count']) == 0:
            count = limit
        elif count > limit:
            msg = 'transaction initialization failed'
            LOGGER.error(f'{msg}: {request_id}')
            return lambda_response(500, msg, metadata)

    # step 4: save item into dynamodb
    try:
        response = dynamodb_put_item(region, table, item, replicated)
        msg = 'transaction initialized successfully'
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')

    except Exception as e:
        msg = 'saving item to dynamodb failed'
        LOGGER.warning(f'attempted to save item: {item}')
        LOGGER.error(f'{msg}: {str(e)}')
        item['transaction_status'] = 'FAIL'
        item['transaction_code'] = 'NARR'
        response = dynamodb_put_item(region, table, item, replicated)
        LOGGER.debug(f'dynamodb_put_item msg: {msg}')
        LOGGER.debug(f'dynamodb_put_item response: {response}')
        metadata['ErrorMessage'] = str(e)
        return lambda_response(500, msg, metadata)

    # step 5: trigger response
    metadata = {
        'RequestId': request_id,
        'RequestTimestamp': TIME,
        'TransactionId': item['transaction_id'],
        'RegionId': region,
        'ApiEndpoint': api_url,
    }
    if 'replicated' in response and response['replicated']:
        metadata['DynamodbReplicated'] = response['replicated']
    LOGGER.info(f'{msg}: {item}')
    return lambda_response(200, msg, metadata)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
