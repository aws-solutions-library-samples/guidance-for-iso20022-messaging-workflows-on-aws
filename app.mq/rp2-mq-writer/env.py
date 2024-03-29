# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, json, requests, backoff
from dotenv import dotenv_values

class Variables:
    def __init__(self, DOTENV):
        self.env = dotenv_values(DOTENV)

    @backoff.on_exception(backoff.expo,
        requests.exceptions.HTTPError, max_time=15)
    @backoff.on_exception(backoff.expo,
        requests.exceptions.Timeout, max_time=60)
    def _retrieve_from_secretsmanager(self, secret, port='2773'):
        headers = {'X-Aws-Parameters-Secrets-Token': os.environ.get('AWS_SESSION_TOKEN')}
        r = requests.get(f'http://localhost:{port}/secretsmanager/get?secretId={secret}', headers=headers, timeout=15)
        if r.status_code == 200:
            response = r.json()
            if response and 'SecretString' in response:
                return json.loads(response['SecretString'])
        return None

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
            if response and value in response:
                return response[value]
        return self.get_rp2_env(value)

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
