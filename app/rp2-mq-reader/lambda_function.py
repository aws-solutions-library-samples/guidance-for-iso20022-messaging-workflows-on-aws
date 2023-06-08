# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, json, requests
from datetime import datetime, timezone
from env import Variables
from joblib import Parallel, delayed
from util import auth2token, connect2rmq

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)
TOKEN: str = auth2token(
    VARIABLES.get_rp2_auth_url(),
    VARIABLES.get_rp2_auth_client_id(),
    VARIABLES.get_rp2_auth_client_secret())

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def _rmq2api(channel, method_frame, header_frame, body, thread=1):
    LOGGER.debug('started executing _rmq2api()')
    LOGGER.debug(f'thread {thread} received data: {body}')
    url = VARIABLES.get_rp2_api_url()
    if not url.startswith('http'):
        url = f'https://{url}'
    LOGGER.debug(f'api url: {url}')
    uuid = VARIABLES.get_rp2_api_uuid()
    LOGGER.debug(f'uuid api: {uuid}')
    inbox = VARIABLES.get_rp2_api_inbox()
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
        VARIABLES.get_rp2_rmq_host(),
        VARIABLES.get_rp2_rmq_port(),
        VARIABLES.get_rp2_rmq_user(),
        VARIABLES.get_rp2_rmq_pass())
    LOGGER.debug(f'established rmq connection: {connection}')
    main_channel = connection.channel()
    LOGGER.debug(f'initialized channel: {main_channel}')
    main_channel.basic_qos(prefetch_count = 10)
    LOGGER.debug(f'prefetching basic qos: 10')
    queue = VARIABLES.get_rp2_rmq_queue()
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
    TIME = datetime.now(timezone.utc)
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

    if TOKEN is None:
        LOGGER.warning('token is missing')
        return {
            'statusCode': 400,
            'body': json.dumps({
                'code': 400,
                'message': 'API authentication failed',
                'request_duration': (datetime.now(timezone.utc)-TIME).total_seconds(),
            })
        }

    num = int(VARIABLES.get_rp2_rmq_thread())
    Parallel(n_jobs=num)(
        delayed(_parallel)(thread) for thread in range(num)
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'code': 200,
            'message': 'message consumed successfully',
            'request_duration': (datetime.now(timezone.utc)-TIME).total_seconds(),
        })
    }

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
