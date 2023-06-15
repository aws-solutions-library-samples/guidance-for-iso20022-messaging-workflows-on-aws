# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging
from datetime import datetime, timezone
from env import Variables
from util import dynamodb_timeout_items, lambda_response

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
    request_id = None
    if context and context.aws_request_id:
        request_id = context.aws_request_id
    LOGGER.debug(f'computed request_id: {request_id}')
    region = VARIABLES.get_rp2_region()
    table = VARIABLES.get_rp2_ddb_tnx()
    range = VARIABLES.get_rp2_timestamp_partition()

    # step 2: initialize variables
    metadata = {
        'RequestId': request_id,
        'RegionId': region,
        'ApiEndpoint': VARIABLES.get_rp2_api_url(),
    }

    # step 3: continue to timeout in-flight payments
    result = dynamodb_timeout_items(region, table, range)

    # step 4: trigger response
    msg = f'successful timeout of {len(result)} transactions'
    LOGGER.info(f'{msg}: {result}')
    return lambda_response(200, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
