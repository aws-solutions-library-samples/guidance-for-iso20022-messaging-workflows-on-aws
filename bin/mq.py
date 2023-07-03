# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os, boto3, json, ssl, pika

# predefined variables
secret_name = 'rp2-service-mq'
region_name = 'us-east-1'
rp2_id = 'abcd1234'
resources = ['inbox.pacs.002', 'inbox.pacs.008', 'outbox.pacs.002', 'outbox.pacs.008']

# overwrite variables
if os.getenv("RP2_REGION"):
    region_name = os.getenv("RP2_REGION")
elif os.getenv("AWS_REGION"):
    region_name = os.getenv("AWS_REGION")
elif os.getenv("AWS_DEFAULT_REGION"):
    region_name = os.getenv("AWS_DEFAULT_REGION")
if os.getenv("RP2_ID"):
    rp2_id = os.getenv("RP2_ID")

# retrieve secrets
print('[INFO] Connecting to AWS Secrets Manager...')
session = boto3.session.Session()
client = session.client(service_name='secretsmanager', region_name=region_name)
print('[INFO] Retrieving RabbitMQ secret from AWS Secrets Manager...')
response = client.get_secret_value(SecretId=f'{secret_name}-{region_name}-{rp2_id}')
r = json.loads(response['SecretString'])

# create rabbitmq resources
print('[INFO] Connecting to RabbitMQ...')
credentials = pika.PlainCredentials(r['RP2_RMQ_USER'], r['RP2_RMQ_PASS'])
context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
parameters = pika.ConnectionParameters(r['RP2_RMQ_HOST'], r['RP2_RMQ_PORT'], '/', credentials, ssl_options=pika.SSLOptions(context))
connection = pika.BlockingConnection(parameters)
print('[INFO] Retrieving connection channel from RabbitMQ...')
channel = connection.channel()

print('[INFO] Creating RabbitMQ resources...')
for index in range(len(resources)):
    channel.queue_declare(queue=resources[index])
    print(f'[INFO] {resources[index]} queue created successfully...')
    channel.exchange_declare(exchange=resources[index], exchange_type='topic')
    print(f'[INFO] {resources[index]} exchange created successfully...')
    channel.queue_bind(exchange=resources[index], queue=resources[index], routing_key=resources[index])
    print(f'[INFO] {resources[index]} binding created successfully...')
