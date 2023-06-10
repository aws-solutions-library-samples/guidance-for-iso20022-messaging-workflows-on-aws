# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, uuid, logging
from datetime import datetime, timezone
from env import Variables
from util import get_request_arn, dynamodb_get_by_item, s3_get_object, sqs_receive_message, lambda_response

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

    # step 1: initialize variables
    error = {}
    if 'headers' in event and event['headers'] and 'X-Transaction-Id' in event['headers'] and event['headers']['X-Transaction-Id']:
        id = event['headers']['X-Transaction-Id']
    else:
        id = str(uuid.uuid4())
    LOGGER.debug(f'computed id: {id}')
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
    item = {
        'created_at': TIME,
        'created_by': identity,
        'transaction_id': id,
    }
    item = {**item, **request_arn}
    LOGGER.debug(f'computed item: {item}')

    metadata = {
        'TransactionId': id,
        'RequestId': request_id,
        'RegionId': VARIABLES.get_rp2_region(),
        'ApiEndpoint': VARIABLES.get_rp2_api_url(),
    }

    account = VARIABLES.get_rp2_account()
    region = VARIABLES.get_rp2_region()
    bucket = VARIABLES.get_rp2_bucket()
    key = VARIABLES.get_rp2_check_s3()
    queue = VARIABLES.get_rp2_check_sqs()
    table = VARIABLES.get_rp2_ddb_tnx()

    # step 2: get sqs message
    if not ('headers' in event and event['headers'] and 'X-SQS-Skip' in event['headers']):
        try:
            response = sqs_receive_message(region, queue, account)
            LOGGER.debug(f'sqs_receive_message: {response}')
            metadata['SqsCount'] = len(response)
        except Exception as e:
            error['sqs'] = str(e)

    # step 3: get s3 object
    if not ('headers' in event and event['headers'] and 'X-S3-Skip' in event['headers']):
        try:
            response = s3_get_object(region, bucket, key)
            LOGGER.debug(f's3_get_object: {response}')
            metadata['S3Count'] = int(response['path'] == key)
        except Exception as e:
            error['s3'] = str(e)

    # step 4: get dynamodb item
    if not('headers' in event and event['headers'] and 'X-DynamoDB-Skip' in event['headers']):
        try:
            if 'headers' in event and event['headers'] and 'X-Transaction-Status' in event['headers'] and event['headers']['X-Transaction-Status']:
                item['transaction_status'] = event['headers']['X-Transaction-Status']
            if 'headers' in event and event['headers'] and 'X-Transaction-Region' in event['headers'] and event['headers']['X-Transaction-Region']:
                item['request_region'] = event['headers']['X-Transaction-Region']
            response = dynamodb_get_by_item(region, table, item)
            LOGGER.debug(f'dynamodb_get_by_item: {response}')
            metadata['DynamodbCount'] = response['Count'] if 'Count' in response else 0
        except Exception as e:
            error['dynamodb'] = str(e)

    # step 5: trigger response
    if error:
        msg = 'execution failed'
        LOGGER.warning(f'{msg}: {error}')
        return lambda_response(500, msg, metadata, TIME)

    msg = 'execution successful'
    LOGGER.info(f'{msg}: {item}')
    return lambda_response(200, msg, metadata, TIME)

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
