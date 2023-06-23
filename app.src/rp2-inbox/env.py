# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, logging, requests, json
from dotenv import dotenv_values

class Variables:
    def __init__(self, DOTENV):
        self.env = dotenv_values(DOTENV)

    def _retrieve_from_secretsmanager(self, secret, port='2773'):
        try:
            headers = {'X-Aws-Parameters-Secrets-Token': os.environ.get('AWS_SESSION_TOKEN')}
            r = requests.get(f'http://localhost:{port}/secretsmanager/get?secretId={secret}', headers=headers, timeout=15)
            if r.status_code == 200:
                response = json.loads(r.text)["SecretString"]
                if response:
                    return json.loads(response)
        except Exception as e:
            return None
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
