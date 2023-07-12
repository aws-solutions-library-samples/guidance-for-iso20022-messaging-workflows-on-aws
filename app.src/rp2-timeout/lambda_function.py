# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime
from env import Variables
from util import get_request_arn, get_timestamp_shift, dynamodb_batch_items, lambda_response

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
    request_id = None
    if context and context.aws_request_id:
        request_id = context.aws_request_id
    LOGGER.debug(f'computed request_id: {request_id}')
    request_arn = {}
    if context and context.invoked_function_arn:
        request_arn = get_request_arn(context.invoked_function_arn)
    LOGGER.debug(f'computed request_arn: {request_arn}')

    rp2_id = VARIABLES.get_rp2_env('RP2_ID')
    region = VARIABLES.get_rp2_env('RP2_REGION')
    api_url = VARIABLES.get_rp2_env('RP2_API_URL')
    table = VARIABLES.get_rp2_env('RP2_DDB_TNX')
    timeout = VARIABLES.get_rp2_env('RP2_TIMEOUT_TRANSACTION')
    range = VARIABLES.get_rp2_env('RP2_TIMESTAMP_PARTITION')

    # step 2: initialize variables
    metadata = {
        'RequestId': request_id,
        'RequestTimestamp': TIME,
        'RegionId': region,
        'ApiEndpoint': api_url,
    }

    # step 3: continue to timeout in-flight payments
    item = {**request_arn, 'request_timestamp': TIME, 'transaction_status': 'RJCT', 'transaction_code': 'TOUT'}
    filter = {'request_timestamp': get_timestamp_shift(item['request_timestamp'], timeout), 'transaction_status': 'FLAG'}
    result = dynamodb_batch_items(region, table, item, filter, range)

    # step 4: trigger response
    msg = f'successful timeout of {len(result)} transactions'
    LOGGER.info(f'{msg}: {result}')
    return lambda_response(200, msg, metadata)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
