# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, multiprocessing, logging, json, requests
from datetime import datetime
from env import Variables
from joblib import Parallel, delayed
from util import auth2token, connect2rmq

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)
TOKEN: dict = {}

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def _rmq2api(channel, method_frame, header_frame, body, thread=1):
    LOGGER.debug('started executing _rmq2api()')
    LOGGER.debug(f'thread {thread} received data: {body}')
    url = VARIABLES.get_rp2_env('RP2_API_URL')
    if not url.startswith('http'):
        url = f'https://{url}'
    LOGGER.debug(f'api url: {url}')
    uuid = VARIABLES.get_rp2_env('RP2_API_UUID')
    LOGGER.debug(f'uuid api: {uuid}')
    inbox = VARIABLES.get_rp2_env('RP2_API_INBOX')
    LOGGER.debug(f'inbox api: {inbox}')
    headers = {
        'Authorization': f'Bearer {TOKEN["access_token"]}',
        'Content-Type': 'application/json',
        'X-Message-Type': 'pacs.008',
    }
    LOGGER.debug(f'making requests to `{uuid}` api')
    response = requests.get(f'{url}/{uuid}', headers=headers, timeout=15)
    LOGGER.debug(f'response from `{uuid}` api: {response.status_code} {response.text}')
    if hasattr(response, 'status_code') and response.status_code == 200:
        LOGGER.debug(f'making requests to `{inbox}` api')
        headers['X-Transaction-Id'] = response.json()['transaction_id']
        response = requests.post(f'{url}/{inbox}', data=body, headers=headers, timeout=15)
        LOGGER.debug(f'response from `{inbox}` api: {response.status_code} {response.text}')
        channel.basic_ack(delivery_tag=method_frame.delivery_tag)
        LOGGER.debug(f'message delivery acknowledged: {method_frame.delivery_tag}')
    LOGGER.debug('finished executing _rmq2api()')

def _parallel(thread=1):
    LOGGER.debug('started executing _parallel()')
    LOGGER.debug(f'received thread: {thread}')
    connection = connect2rmq(
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_HOST'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_PORT'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_USER'),
        VARIABLES.get_rp2_secret('RP2_SECRETS_MQ', 'RP2_RMQ_PASS'))
    LOGGER.debug(f'established rmq connection: {connection}')
    main_channel = connection.channel()
    LOGGER.debug(f'initialized channel: {main_channel}')
    main_channel.basic_qos(prefetch_count = 10)
    LOGGER.debug(f'prefetching basic qos: 10')
    queue = VARIABLES.get_rp2_env('RP2_RMQ_QUEUE')
    LOGGER.debug(f'basic consuming from {queue}')
    main_channel.basic_consume(queue, _rmq2api)
    try:
        LOGGER.debug('start consuming...')
        main_channel.start_consuming()
    except KeyboardInterrupt:
        LOGGER.debug('stop consuming...')
        main_channel.stop_consuming()
    LOGGER.debug('closing connection...')
    main_channel.close()
    LOGGER.debug('finished executing _parallel()')

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

    num = int(VARIABLES.get_rp2_env('RP2_RMQ_THREAD'))
    if num == 0:
        num = multiprocessing.cpu_count()
    Parallel(n_jobs=num)(
        delayed(_parallel)(thread) for thread in range(num)
    )

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
