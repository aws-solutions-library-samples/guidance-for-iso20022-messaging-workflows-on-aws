# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, json, re, requests
from datetime import datetime
from env import Variables
from util import auth2token, connect2rmq, publish2rmq, dynamodb_query_by_item

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)
TOKEN: dict = {}

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def lambda_handler(event, context):
    # log time, event and context
    TIME = datetime.utcnow()
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

    global TOKEN
    TOKEN = auth2token(
        VARIABLES.get_rp2_env('RP2_AUTH_URL'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_API', 'RP2_AUTH_CLIENT_ID'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_API', 'RP2_AUTH_CLIENT_SECRET'))

    if not (TOKEN and 'access_token' in TOKEN):
        LOGGER.error(f'access token is missing: {TOKEN}')
        return {
            'statusCode': 400,
            'body': json.dumps({
                'code': 400,
                'message': 'API authentication failed',
                'request_duration': (datetime.utcnow() - TIME).total_seconds(),
            })
        }

    if 'Records' in event:
        data = json.dumps(event)
    elif 'Records' in event['body']:
        data = json.dumps(event['body'])
    else:
        msg = 'records are missing'
        LOGGER.warning(f'{msg}: {event}')
        return {
            'statusCode': 400,
            'body': json.dumps({
                'code': 400,
                'message': msg,
                'request_duration': (datetime.utcnow() - TIME).total_seconds(),
            })
        }

    headers = {
        'Authorization': f'Bearer {TOKEN["access_token"]}',
        'Content-Type': 'application/json',
    }

    try:
        id = None
        if isinstance(data, str):
            data = json.loads(data)
        LOGGER.debug(f'got data: {data}')

        if data['Records'][0]['eventSource'] == 'aws:s3':
            pattern = r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
            LOGGER.debug(f'search pattern: {pattern}')
            object = data['Records'][0]['s3']['object']['key']
            match = re.compile(pattern, re.I).findall(object)
            LOGGER.debug(f'search result pattern: {match}')
            if match:
                id = match[0]

        elif data['Records'][0]['eventSource'] == 'aws:sqs':
            payload = json.loads(data['Records'][0]['body'])
            LOGGER.debug(f'got payload: {payload}')
            if 'Message' in payload and payload['Message']:
                id = payload['Message']

        if id:
            headers['X-Transaction-Id'] = id

    except Exception as e:
        LOGGER.warning(f'getting transaction id failed: {str(e)}')

    url = VARIABLES.get_rp2_env('RP2_API_URL')
    if not url.startswith('http'):
        url = f'https://{url}'
    outbox = VARIABLES.get_rp2_env('RP2_API_OUTBOX')
    LOGGER.debug(f'making requests to `{outbox}` api')
    LOGGER.debug(f'request headers: {headers}')
    response = requests.post(f'{url}/{outbox}', headers=headers, timeout=15)
    LOGGER.debug(f'response from `{outbox}` api: {response.status_code} {response.text}')

    if not(hasattr(response, 'status_code') and response.status_code == 200):
        return {
            'statusCode': response.status_code,
            'body': {
                'code': response.status_code,
                'message': response.text,
                'request_duration': (datetime.utcnow() - TIME).total_seconds(),
            }
        }

    data = response.text
    LOGGER.debug('opening connection...')
    connection = connect2rmq(
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_HOST'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_PORT'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_USER'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_PASS'))

    LOGGER.debug('publishing to rmq...')
    publish2rmq(connection, data, 1,
        VARIABLES.get_rp2_env('RP2_RMQ_EXCHANGE'),
        VARIABLES.get_rp2_env('RP2_RMQ_ROUTING_KEY'))

    LOGGER.debug('closing connection...')
    connection.close()

    # trigger response
    LOGGER.info(f'successful execution: {data}')
    return {
        'statusCode': 200,
        'body': json.dumps({
            'code': 200,
            'message': 'message consumed successfully',
            'request_duration': (datetime.utcnow() - TIME).total_seconds(),
        })
    }

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
