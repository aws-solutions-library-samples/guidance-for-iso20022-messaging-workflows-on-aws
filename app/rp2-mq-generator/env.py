# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, multiprocessing, logging
from dotenv import load_dotenv

class Variables:
    def __init__(self, DOTENV):
        self.env = load_dotenv(DOTENV)
        self.RP2_LOGGING = self.get_rp2_logging()
        self.RP2_ID = self.get_rp2_id()
        self.RP2_ACCOUNT = self.get_rp2_account()
        self.RP2_REGION = self.get_rp2_region()
        self.RP2_RUNTIME = self.get_rp2_runtime()
        self.RP2_HEALTH = self.get_rp2_health()
        self.RP2_API_URL = self.get_rp2_api_url()
        self.RP2_API_UUID = self.get_rp2_api_uuid()
        self.RP2_API_INBOX = self.get_rp2_api_inbox()
        self.RP2_API_OUTBOX = self.get_rp2_api_outbox()
        self.RP2_AUTH_URL = self.get_rp2_auth_url()
        self.RP2_AUTH_CLIENT_ID = self.get_rp2_auth_client_id()
        self.RP2_AUTH_CLIENT_SECRET = self.get_rp2_auth_client_secret()
        self.RP2_CHECK_RECOVER = self.get_rp2_check_recover()
        self.RP2_CHECK_REGION = self.get_rp2_check_region()
        self.RP2_CHECK_CLIENT_ID = self.get_rp2_check_client_id()
        self.RP2_CHECK_CLIENT_SECRET = self.get_rp2_check_client_secret()
        self.RP2_DDB_RETRY = self.get_rp2_ddb_retry()
        self.RP2_DDB_TNX = self.get_rp2_ddb_tnx()
        self.RP2_DDB_LIQ = self.get_rp2_ddb_liq()
        self.RP2_TIMESTAMP_PARTITION = self.get_rp2_timestamp_partition()
        self.RP2_TIMEOUT_TRANSACTION = self.get_rp2_timeout_transaction()
        self.RP2_RMQ_COUNT = self.get_rp2_rmq_count()
        self.RP2_RMQ_THREAD = self.get_rp2_rmq_thread()
        self.RP2_RMQ_HOST = self.get_rp2_rmq_host()
        self.RP2_RMQ_PORT = self.get_rp2_rmq_port()
        self.RP2_RMQ_USER = self.get_rp2_rmq_user()
        self.RP2_RMQ_PASS = self.get_rp2_rmq_pass()
        self.RP2_RMQ_EXCHANGE = self.get_rp2_rmq_exchange()
        self.RP2_RMQ_QUEUE = self.get_rp2_rmq_queue()
        self.RP2_RMQ_ROUTING_KEY = self.get_rp2_rmq_routing_key()

    def get_rp2_logging(self) -> str:
        result = ''
        if os.getenv('RP2_LOGGING') is not None:
            result = os.getenv('RP2_LOGGING')
        elif self.env.get_rp2_logging() is not None:
            result = self.env.get_rp2_logging()

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

    def get_rp2_id(self) -> str:
        if os.getenv('RP2_ID') is not None:
            return os.getenv('RP2_ID')
        elif self.env.get_rp2_id() is not None:
            return self.env.get_rp2_id()
        else:
            return 'abcd1234'

    def get_rp2_account(self) -> str:
        if os.getenv('RP2_ACCOUNT') is not None:
            return os.getenv('RP2_ACCOUNT')
        elif self.env.get_rp2_account() is not None:
            return self.env.get_rp2_account()
        else:
            return None

    def get_rp2_region(self) -> str:
        if os.getenv('RP2_REGION') is not None:
            return os.getenv('RP2_REGION')
        elif self.env.get_rp2_region() is not None:
            return self.env.get_rp2_region()
        else:
            return 'us-east-1'

    def get_rp2_runtime(self) -> str:
        if os.getenv('RP2_RUNTIME') is not None:
            return os.getenv('RP2_RUNTIME')
        elif self.env.get_rp2_runtime() is not None:
            return self.env.get_rp2_runtime()
        else:
            return 'rp2-runtime'

    def get_rp2_health(self) -> str:
        if os.getenv('RP2_HEALTH') is not None:
            return os.getenv('RP2_HEALTH')
        elif self.env.get_rp2_health() is not None:
            return self.env.get_rp2_health()
        else:
            return 'rp2-health'

    def get_rp2_api_url(self) -> str:
        if os.getenv('RP2_API_URL') is not None:
            return os.getenv('RP2_API_URL')
        elif self.env.get_rp2_api_url() is not None:
            return self.env.get_rp2_api_url()
        else:
            return 'http://localhost/api'

    def get_rp2_api_uuid(self) -> str:
        if os.getenv('RP2_API_UUID') is not None:
            return os.getenv('RP2_API_UUID')
        elif self.env.get_rp2_api_uuid() is not None:
            return self.env.get_rp2_api_uuid()
        else:
            return 'uuid'

    def get_rp2_api_inbox(self) -> str:
        if os.getenv('RP2_API_INBOX') is not None:
            return os.getenv('RP2_API_INBOX')
        elif self.env.get_rp2_api_inbox() is not None:
            return self.env.get_rp2_api_inbox()
        else:
            return 'inbox'

    def get_rp2_api_outbox(self) -> str:
        if os.getenv('RP2_API_OUTBOX') is not None:
            return os.getenv('RP2_API_OUTBOX')
        elif self.env.get_rp2_api_outbox() is not None:
            return self.env.get_rp2_api_outbox()
        else:
            return 'outbox'

    def get_rp2_auth_url(self) -> str:
        if os.getenv('RP2_AUTH_URL') is not None:
            return os.getenv('RP2_AUTH_URL')
        elif self.env.get_rp2_auth_url() is not None:
            return self.env.get_rp2_auth_url()
        else:
            return 'http://localhost/auth'

    def get_rp2_auth_client_id(self) -> str:
        if os.getenv('RP2_AUTH_CLIENT_ID') is not None:
            return os.getenv('RP2_AUTH_CLIENT_ID')
        elif self.env.get_rp2_auth_client_id() is not None:
            return self.env.get_rp2_auth_client_id()
        else:
            return 'rp2_auth_client_id'

    def get_rp2_auth_client_secret(self) -> str:
        if os.getenv('RP2_AUTH_CLIENT_SECRET') is not None:
            return os.getenv('RP2_AUTH_CLIENT_SECRET')
        elif self.env.get_rp2_auth_client_secret() is not None:
            return self.env.get_rp2_auth_client_secret()
        else:
            return 'rp2_auth_client_secret'

    def get_rp2_check_recover(self) -> str:
        if os.getenv('RP2_CHECK_RECOVER') is not None:
            return os.getenv('RP2_CHECK_RECOVER')
        elif self.env.get_rp2_check_recover() is not None:
            return self.env.get_rp2_check_recover()
        else:
            return 0

    def get_rp2_check_region(self) -> str:
        if os.getenv('RP2_CHECK_REGION') is not None:
            return os.getenv('RP2_CHECK_REGION')
        elif self.env.get_rp2_check_region() is not None:
            return self.env.get_rp2_check_region()
        else:
            return 'us-east-1'

    def get_rp2_check_client_id(self) -> str:
        if os.getenv('RP2_CHECK_CLIENT_ID') is not None:
            return os.getenv('RP2_CHECK_CLIENT_ID')
        elif self.env.get_rp2_check_client_id() is not None:
            return self.env.get_rp2_check_client_id()
        else:
            return 'rp2_check_client_id'

    def get_rp2_check_client_secret(self) -> str:
        if os.getenv('RP2_CHECK_CLIENT_SECRET') is not None:
            return os.getenv('RP2_CHECK_CLIENT_SECRET')
        elif self.env.get_rp2_check_client_secret() is not None:
            return self.env.get_rp2_check_client_secret()
        else:
            return 'rp2_check_client_secret'

    def get_rp2_ddb_retry(self) -> str:
        if os.getenv('RP2_DDB_RETRY') is not None:
            return os.getenv('RP2_DDB_RETRY')
        elif self.env.get_rp2_ddb_retry() is not None:
            return self.env.get_rp2_ddb_retry()
        else:
            return 0

    def get_rp2_ddb_tnx(self) -> str:
        if os.getenv('RP2_DDB_TNX') is not None:
            return os.getenv('RP2_DDB_TNX')
        elif self.env.get_rp2_ddb_tnx() is not None:
            return self.env.get_rp2_ddb_tnx()
        else:
            return None

    def get_rp2_ddb_liq(self) -> str:
        if os.getenv('RP2_DDB_LIQ') is not None:
            return os.getenv('RP2_DDB_LIQ')
        elif self.env.get_rp2_ddb_liq() is not None:
            return self.env.get_rp2_ddb_liq()
        else:
            return None

    def get_rp2_timestamp_partition(self) -> str:
        if os.getenv('RP2_TIMESTAMP_PARTITION') is not None:
            return os.getenv('RP2_TIMESTAMP_PARTITION')
        elif self.env.get_rp2_timestamp_partition() is not None:
            return self.env.get_rp2_timestamp_partition()
        else:
            return 0

    def get_rp2_timeout_transaction(self) -> str:
        if os.getenv('RP2_TIMEOUT_TRANSACTION') is not None:
            return os.getenv('RP2_TIMEOUT_TRANSACTION')
        elif self.env.get_rp2_timeout_transaction() is not None:
            return self.env.get_rp2_timeout_transaction()
        else:
            return 0

    def get_rp2_rmq_count(self) -> int:
        if os.getenv('RP2_RMQ_COUNT') is not None:
            return int(os.getenv('RP2_RMQ_COUNT'))
        elif self.env.get_rp2_rmq_count() is not None:
            return int(self.env.get_rp2_rmq_count())
        else:
            return 500

    def get_rp2_rmq_thread(self) -> int:
        if os.getenv('RP2_RMQ_THREAD') is not None:
            return int(os.getenv('RP2_RMQ_THREAD'))
        elif self.env.get_rp2_rmq_thread() is not None:
            return int(self.env.get_rp2_rmq_thread())
        else:
            return multiprocessing.cpu_count()

    def get_rp2_rmq_host(self) -> str:
        if os.getenv('RP2_RMQ_HOST') is not None:
            return os.getenv('RP2_RMQ_HOST')
        elif self.env.get_rp2_rmq_host() is not None:
            return self.env.get_rp2_rmq_host()
        else:
            return 'localhost'

    def get_rp2_rmq_port(self) -> str:
        if os.getenv('RP2_RMQ_PORT') is not None:
            return os.getenv('RP2_RMQ_PORT')
        elif self.env.get_rp2_rmq_port() is not None:
            return self.env.get_rp2_rmq_port()
        else:
            return '5671'

    def get_rp2_rmq_user(self) -> str:
        if os.getenv('RP2_RMQ_USER') is not None:
            return os.getenv('RP2_RMQ_USER')
        elif self.env.get_rp2_rmq_user() is not None:
            return self.env.get_rp2_rmq_user()
        else:
            return 'rabbitmq_username'

    def get_rp2_rmq_pass(self) -> str:
        if os.getenv('RP2_RMQ_PASS') is not None:
            return os.getenv('RP2_RMQ_PASS')
        elif self.env.get_rp2_rmq_pass() is not None:
            return self.env.get_rp2_rmq_pass()
        else:
            return 'rabbitmq_p@ssw0rd'

    def get_rp2_rmq_queue(self) -> str:
        if os.getenv('RP2_RMQ_QUEUE') is not None:
            return os.getenv('RP2_RMQ_QUEUE')
        elif self.env.get_rp2_rmq_queue() is not None:
            return self.env.get_rp2_rmq_queue()
        else:
            return None

    def get_rp2_rmq_exchange(self) -> str:
        if os.getenv('RP2_RMQ_EXCHANGE') is not None:
            return os.getenv('RP2_RMQ_EXCHANGE')
        elif self.env.get_rp2_rmq_exchange() is not None:
            return self.env.get_rp2_rmq_exchange()
        else:
            return None

    def get_rp2_rmq_routing_key(self) -> str:
        if os.getenv('RP2_RMQ_ROUTING_KEY') is not None:
            return os.getenv('RP2_RMQ_ROUTING_KEY')
        elif self.env.get_rp2_rmq_routing_key() is not None:
            return self.env.get_rp2_rmq_routing_key()
        else:
            return None
