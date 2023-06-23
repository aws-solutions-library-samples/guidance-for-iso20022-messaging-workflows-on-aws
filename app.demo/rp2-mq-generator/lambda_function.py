# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, json
from datetime import datetime, timezone
from env import Variables
from joblib import Parallel, delayed
from util import connect2rmq, publish2rmq

LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)

if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def _parallel(thread=1):
    LOGGER.debug('started executing _parallel()')
    LOGGER.debug(f'received thread: {thread}')

    with open('pacs.008.xml', 'r', encoding='utf-8') as fp:
        data = fp.read()
    LOGGER.debug(f'file loaded: {data}')

    LOGGER.debug('opening connection...')
    connection = connect2rmq(
        VARIABLES.get_rp2_secrets('RP2_SECRETS_MQ', 'RP2_RMQ_HOST'),
        VARIABLES.get_rp2_secrets('RP2_SECRETS_MQ', 'RP2_RMQ_PORT'),
        VARIABLES.get_rp2_secrets('RP2_SECRETS_MQ', 'RP2_RMQ_USER'),
        VARIABLES.get_rp2_secrets('RP2_SECRETS_MQ', 'RP2_RMQ_PASS'))

    LOGGER.debug('publishing to rmq...')
    publish2rmq(connection, data,
        VARIABLES.get_rp2_env('RP2_RMQ_COUNT'),
        VARIABLES.get_rp2_env('RP2_RMQ_EXCHANGE'),
        VARIABLES.get_rp2_env('RP2_RMQ_ROUTING_KEY'))

    LOGGER.debug('closing connection...')
    connection.close()

def lambda_handler(event, context):
    # log time, event and context
    TIME = datetime.now(timezone.utc)
    LOGGER.debug(f'got event: {event}')
    LOGGER.debug(f'got context: {context}')

    num = int(VARIABLES.get_rp2_env('RP2_RMQ_THREAD'))
    Parallel(n_jobs=num)(
        delayed(_parallel)(thread) for thread in range(num)
    )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'code': 200,
            'message': 'message generated successfully',
            'request_duration': (datetime.now(timezone.utc)-TIME).total_seconds(),
        })
    }

if __name__ == '__main__':
    lambda_handler(event=None, context=None)
