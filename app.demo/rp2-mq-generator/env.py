# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, multiprocessing, logging, requests, json
from dotenv import dotenv_values

LOGGER: str = logging.getLogger(__name__)
if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel('DEBUG')
else:
    logging.basicConfig(level='DEBUG')

class Variables:
    def __init__(self, DOTENV):
        LOGGER.debug(f'DOTENV: {DOTENV}')
        self.env = dotenv_values(DOTENV)
        LOGGER.debug(f'ENV: {self.env}')

    def _retrieve_from_secretsmanager(self, secret, port='2773'):
        LOGGER.debug(f'secret: {secret}')
        try:
            headers = {'X-Aws-Parameters-Secrets-Token': os.environ.get('AWS_SESSION_TOKEN')}
            LOGGER.debug(f'headers: {headers}')
            r = requests.get(f'http://localhost:{port}/secretsmanager/get?secretId={secret}', headers=headers, timeout=15)
            LOGGER.debug(f'request: {r}')
            response = json.loads(r.text)["SecretString"]
            LOGGER.debug(f'response: {response}')
        except Exception as e:
            response = None
            LOGGER.debug(f'exception: {e}')
        return response

    def get_rp2_env(self, value) -> str:
        if os.getenv(value):
            return os.getenv(value)
        elif value in self.env:
            return self.env[value]
        else:
            return None

    def get_rp2_secret(self, secret, value) -> str:
        response = None
        if os.getenv(secret):
            response = self._retrieve_from_secretsmanager(os.getenv(secret))
            if value in response:
                response = response[value]
        if not response:
            response = self.get_rp2_env(value)
        return response

    def get_rp2_logging(self) -> str:
        result = self.get_rp2_env('RP2_LOGGING')
        if result == 'DEBUG':
            return logging.DEBUG
        elif result == 'INFO':
            return logging.INFO
        elif result == 'WARNING':
            return logging.WARNING
        elif result == 'ERROR':
            return logging.ERROR
        elif result == 'CRITICAL':
            return logging.CRITICAL
        else:
            return logging.NOTSET
