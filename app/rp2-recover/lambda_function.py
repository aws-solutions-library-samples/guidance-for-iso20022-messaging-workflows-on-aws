# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime, timedelta, timezone
from env import Variables
from util import get_request_arn, request_health_check, s3_move_object, dynamodb_recover_cross_region, lambda_response

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
    region = VARIABLES.get_rp2_region()
    table = VARIABLES.get_rp2_ddb_tnx()
    region2 = VARIABLES.get_rp2_check_region()
    api_url = VARIABLES.get_rp2_api_url().replace(region, region2)
    auth = {
        'auth_url': VARIABLES.get_rp2_auth_url().replace(region, region2),
        'client_id': VARIABLES.get_rp2_check_client_id(),
        'client_secret': VARIABLES.get_rp2_check_client_secret(),
    }

    # step 1: initialize variables
    metadata = {
        'RequestId': request_id,
        'RegionId': region,
        'ApiEndpoint': VARIABLES.get_rp2_api_url(),
    }

    # step 2: check the health of the opposite region
    req_count = int(VARIABLES.get_rp2_check_recover())
    if req_count > 0:
        health_check = request_health_check(api_url, auth)
        response = health_check['health_check']
        LOGGER.debug(f'got response: {response.status_code} {response.text}')
        auth = {'access_token': health_check['access_token']}
        if hasattr(response, 'status_code') and response.status_code == 200:
            msg = 'successful health check - 1 attempt'
            LOGGER.info(f'{msg}: {health_check["health_check"]}')
            return lambda_response(200, msg, metadata, TIME)

    iter = 1
    while iter < req_count:
        iter += 1
        health_check = request_health_check(api_url, auth)
        response = health_check['health_check']
        LOGGER.debug(f'got response: {response.status_code} {response.text}')
        if hasattr(response, 'status_code') and response.status_code == 200:
            msg = f'successful health check - {iter} attempts'
            LOGGER.info(f'{msg}: {health_check["health_check"]}')
            return lambda_response(200, msg, metadata, TIME)

    # step 3: initiate recover, force route53 failover
    try:
        bucket = VARIABLES.get_rp2_bucket()
        old_key = VARIABLES.get_rp2_check_s3()
        new_key = f'{region}/{old_key}'
        response = s3_move_object(region2, bucket, old_key, new_key)
        LOGGER.debug(f'got response: {response.status_code} {response.text}')

    except Exception as e:
        msg = 'moving object in s3 failed'
        LOGGER.error(f'{msg}: {str(e)}')
        # return lambda_response(500, msg, metadata, TIME)

    # step 4: continue to recover, cancel in-flight payments from affected region
    result = []
    item = {**request_arn, 'created_at': TIME - timedelta(minutes=60), 'transaction_status': 'CANC', 'transaction_code': 'RCVR'}
    result += dynamodb_recover_cross_region(region, table, item, region2)
    item = {**request_arn, 'created_at': TIME, 'transaction_status': 'CANC', 'transaction_code': 'RCVR'}
    result += dynamodb_recover_cross_region(region, table, item, region2)

    # step 5: trigger response
    msg = f'successful recover of {len(result)} transactions'
    LOGGER.info(f'{msg}: {result}')
    return lambda_response(200, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
