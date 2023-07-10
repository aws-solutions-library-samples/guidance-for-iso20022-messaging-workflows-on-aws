# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime, timedelta, timezone
from env import Variables
from util import get_request_arn, lambda_health_check, s3_move_object, dynamodb_batch_items, lambda_response, apigateway_base_path_mapping

DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)
LOGGER: str = logging.getLogger(__name__)

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def lambda_handler(event, context):
    # log time, event and context
    TIME = datetime.now(timezone.utc)
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

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
    health = VARIABLES.get_rp2_env('RP2_HEALTH')
    range = VARIABLES.get_rp2_env('RP2_TIMESTAMP_PARTITION')

    # step 1: initialize variables
    metadata = {
        'RequestId': request_id,
        'RegionId': region,
        'ApiEndpoint': api_url,
    }

    # step 2: check the health of the opposite region
    # @TODO: exponential back-off
    iter = 0
    req_count = int(VARIABLES.get_rp2_env('RP2_CHECK_RECOVER'))
    headers = {'X-Transaction-Region': region}
    payload = {'identity': identity}

    while iter < req_count:
        iter += 1
        response = lambda_health_check(region2, headers, payload)
        LOGGER.debug(f'lambda_health_check response: {response}')
        if 'StatusCode' in response and response['StatusCode'] == 200:
            msg = f'successful health check - {iter} attempt(s)'
            LOGGER.info(f'{msg}: {response}')
            return lambda_response(200, msg, metadata, TIME)

    # step 3: force route53 failover and initiate recovery in healthy region
    try:
        bucket = f'{health}-{region}-{rp2_id}'
        old_key = f'{health}-{region2}.txt'
        new_key = f'{health}-{region2}.NOT'
        response = s3_move_object(region2, bucket, old_key, new_key)
        LOGGER.debug(f'got response: {response.status_code} {response.text}')

    except Exception as e:
        msg = 'moving object in s3 failed'
        LOGGER.error(f'{msg}: {str(e)}')

    # step 4: switch rest api base path mapping: (v1, none) to (v1, healthy)
    try:
        api_id = VARIABLES.get_rp2_secret('RP2_SECRETS_REST', 'RP2_API_ID')
        if api_id:
            apigateway_base_path_mapping(region2, api_id, 'v1', 'healthy')
            LOGGER.info(f'RP2_SECRETS_REST: {api_id} base path mapping updated')
    except Exception as e:
        msg = 'update to apigateway rest api base path mapping failed'
        LOGGER.error(f'{msg}: {str(e)}')

    # step 5: switch mock api base path mapping: (v0, unhealthy) to (v0, none)
    try:
        api_id = VARIABLES.get_rp2_secret('RP2_SECRETS_MOCK', 'RP2_API_ID')
        if api_id:
            apigateway_base_path_mapping(region2, api_id, 'v0')
            LOGGER.info(f'RP2_SECRETS_MOCK: {api_id} base path mapping updated')
    except Exception as e:
        msg = 'update to apigateway mock api base path mapping failed'
        LOGGER.error(f'{msg}: {str(e)}')

    # step 6: continue to recover, cancel in-flight payments from affected region
    item = {**request_arn, 'created_at': TIME, 'transaction_status': 'CANC', 'transaction_code': 'RCVR'}
    filter = {'request_region': region2, 'transaction_status': 'FLAG'}
    result = dynamodb_batch_items(region, table, item, filter, range)

    # step 7: trigger response
    msg = f'successful recover of {len(result)} transactions'
    LOGGER.info(f'{msg}: {result}')
    return lambda_response(200, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
