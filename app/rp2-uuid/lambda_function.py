# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, uuid, logging
from datetime import datetime, timezone
from env import Variables
from util import get_request_arn, dynamodb_get_by_item, dynamodb_put_item, lambda_response

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
        'transaction_status': 'ACCP',
    }
    item = {**item, **request_arn}
    LOGGER.debug(f'computed item: {item}')

    # step 2: initialize variables
    metadata = {
        'ErrorCode': 'NARR',
        'ErrorMessage': 'rejected (see narrative reason)',
        'RequestId': request_id,
    }

    # step 3: create and validate transaction_id
    count = 0
    limit = 3
    while count < limit:
        count += 1
        item['transaction_id'] = str(uuid.uuid4())
        LOGGER.debug(f'dynamodb_get_by_item item: {item}')
        response = dynamodb_get_by_item(region, table, item)
        LOGGER.debug(f'dynamodb_get_by_item response: {response}')
        if int(response['Count']) == 0:
            count = limit
        elif count > limit:
            msg = 'transaction initialization failed'
            LOGGER.error(f'{msg}: {request_id}')
            return lambda_response(500, msg, metadata, TIME)

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
        return lambda_response(500, msg, metadata, TIME)

    # step 5: trigger response
    metadata = {
        'TransactionId': item['transaction_id'],
        'RequestId': request_id,
        'RegionId': VARIABLES.get_rp2_region(),
        'ApiEndpoint': VARIABLES.get_rp2_api_url(),
    }
    if 'replicated' in response and response['replicated']:
        metadata['DynamodbReplicated'] = response['replicated']
    LOGGER.info(f'{msg}: {item}')
    return lambda_response(200, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
