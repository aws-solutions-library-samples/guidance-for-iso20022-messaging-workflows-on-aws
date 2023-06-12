# Copyright (C) Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import boto3, uuid, re, json, base64, requests
from boto3.dynamodb.conditions import Key
from datetime import datetime, timedelta, timezone
from math import floor

import logging, os
from env import Variables
LOGGER: str = logging.getLogger(__name__)
DOTENV: str = os.path.join(os.path.dirname(__file__), 'dotenv.txt')
VARIABLES: str = Variables(DOTENV)
if logging.getLogger().hasHandlers():
    logging.getLogger().setLevel(VARIABLES.get_rp2_logging())
else:
    logging.basicConfig(level=VARIABLES.get_rp2_logging())

def get_iso20022_mapping(msg):
    if msg is None:
        return None
    if msg[:8] == 'pacs.008':
        return 'pacs.002'
    elif msg[:8] == 'pain.013':
        return 'pain.014'
    else:
        return None

def get_timestamp(time, range=60):
    if isinstance(time, str):
        time = datetime.fromisoformat(time)
    minute = floor(time.minute / range) * range if int(range) > 1 else time.minute
    return str(datetime(time.year, time.month, time.day,
        hour=time.hour, minute=minute, second=0, tzinfo=time.tzinfo).timestamp())

def get_request_arn(arn):
    result = {}
    if isinstance(arn, str):
        arn = arn.split(":")
        result['request_partition'] = arn[1]
        result['request_service'] = arn[2]
        result['request_region'] = arn[3]
        result['request_account'] = arn[4]
        result['request_resource'] = arn[6]
    return result

def get_partition_key(item):
    # @TODO: distribute partitioning even further by tenant_id, worker_id, etc
    result = ""
    if 'created_at' in item and item['created_at']:
        result += get_timestamp(item['created_at'])
    # if 'created_by' in item and item['created_by']:
    #     result += item['created_by']
    if 'request_region' in item and item['request_region']:
        result += item['request_region']
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, result + '.com'))

def get_sort_key(item):
    time = str(item["created_at"]).replace(" ", "+")
    return f'{item["transaction_id"]}|{time}|{item["transaction_status"]}'

def s3_get_object(region, bucket, key):
    s3 = boto3.resource('s3', region_name=region)
    obj = s3.Object(bucket, key)
    return {
        'path': key,
        'object': obj.get()['Body'].read().decode('utf-8'),
    }

def s3_put_object(region, bucket, prefix, name, ext, body, time):
    s3 = boto3.resource('s3', region_name=region)
    key = f'{prefix}/{time.year}/{time.month:02d}/{time.day:02d}'
    key += f'/{time.hour:02d}/{time.minute:02d}/{time.second:02d}'
    key += f'/{name}.{ext}'
    retain = datetime(time.year+10, time.month, time.day)
    object = s3.Object(bucket, key)
    return {
        'path': key,
        'object': object.put(Body=body, ContentType=f'application/{ext}',
            ObjectLockMode='GOVERNANCE', ObjectLockRetainUntilDate=retain)
    }

def s3_move_object(region, bucket, old_key, new_key):
    s3 = boto3.resource('s3', region_name=region)
    obj = s3.Object(bucket, new_key).copy_from(CopySource=f'{bucket}/{old_key}')
    s3.Object(bucket, old_key).delete()
    return {
        'path': new_key,
        'object': obj.get()['Body'].read().decode('utf-8'),
    }

def sns_publish_message(region, topic, account, message, attributes=None):
    sns = boto3.client("sns", region_name=region)
    kwargs = {
        'TopicArn': f'arn:aws:sns:{region}:{account}:{topic}',
        'Message': message,
    }
    if attributes:
        att_dict = {}
        for key, value in attributes.items():
            if isinstance(value, str):
                att_dict[key] = {'DataType': 'String', 'StringValue': value}
            elif isinstance(value, bytes):
                att_dict[key] = {'DataType': 'Binary', 'BinaryValue': value}
        kwargs['MessageAttributes'] = att_dict
    response = sns.publish(**kwargs)
    return response['MessageId']

def sqs_send_message(region, queue, account, message, deduplication_id=None, group_id=None, attributes=None):
    sqs = boto3.client("sqs", region_name=region)
    kwargs = {
        'QueueUrl': f'https://sqs.{region}.amazonaws.com/{account}/{queue}',
        'MessageBody': message,
    }
    if group_id:
        kwargs['MessageGroupId'] = group_id
    if deduplication_id:
        kwargs['MessageDeduplicationId'] = deduplication_id
    if attributes:
        att_dict = {}
        for key, value in attributes.items():
            if isinstance(value, str):
                att_dict[key] = {'DataType': 'String', 'StringValue': value}
            elif isinstance(value, bytes):
                att_dict[key] = {'DataType': 'Binary', 'BinaryValue': value}
        kwargs['MessageAttributes'] = att_dict
    response = sqs.send_message(**kwargs)
    return response['MessageId']

def sqs_receive_message(region, queue, account, num=1, wait=1):
    sqs = boto3.client("sqs", region_name=region)
    kwargs = {
        'QueueUrl': f'https://sqs.{region}.amazonaws.com/{account}/{queue}',
        'MaxNumberOfMessages': num,
        'WaitTimeSeconds': wait,
    }
    response = sqs.receive_message(**kwargs)
    return response.get("Messages", [])

def dynamodb_item(attributes):
    item = {'created_at': str(datetime.utcnow())}
    if attributes:
        if '_arn' in attributes and attributes['_arn']:
            item = {**item, **get_request_arn(attributes['_arn'])}
        if 'created_at' in attributes and attributes['created_at']:
            item['created_at'] = str(attributes['created_at'])
        if 'created_by' in attributes and attributes['created_by']:
            item['created_by'] = str(attributes['created_by'])
        if 'message_id' in attributes and attributes['message_id']:
            item['message_id'] = str(attributes['message_id'])
        if 'request_id' in attributes and attributes['request_id']:
            item['request_id'] = str(attributes['request_id'])
        if 'request_partition' in attributes and attributes['request_partition']:
            item['request_partition'] = str(attributes['request_partition'])
        if 'request_service' in attributes and attributes['request_service']:
            item['request_service'] = str(attributes['request_service'])
        if 'request_region' in attributes and attributes['request_region']:
            item['request_region'] = str(attributes['request_region'])
        if 'request_account' in attributes and attributes['request_account']:
            item['request_account'] = str(attributes['request_account'])
        if 'request_resource' in attributes and attributes['request_resource']:
            item['request_resource'] = str(attributes['request_resource'])
        if 'transaction_id' in attributes and attributes['transaction_id']:
            item['transaction_id'] = str(attributes['transaction_id'])
        if 'transaction_status' in attributes and attributes['transaction_status']:
            item['transaction_status'] = str(attributes['transaction_status'])
        if 'transaction_code' in attributes and attributes['transaction_code']:
            item['transaction_code'] = str(attributes['transaction_code'])
        if 'storage_path' in attributes and attributes['storage_path']:
            item['storage_path'] = str(attributes['storage_path'])
        if 'storage_type' in attributes and attributes['storage_type']:
            item['storage_type'] = str(attributes['storage_type'])
    item['id'] = get_partition_key(item)
    item['sk'] = get_sort_key(item)
    return item

def dynamodb_get_by_item(region, table, item, range=60):
    resource = boto3.resource('dynamodb', region_name=region)
    LOGGER.debug(f'dynamodb_query_item item: {item}')
    response = resource.Table(table).query(
        KeyConditionExpression=Key('id').eq(get_partition_key(item)) & Key('sk').begins_with(str(item['transaction_id'])),
        ScanIndexForward=False
    )
    LOGGER.debug(f'dynamodb_query_item response: {response}')
    time = item['created_at'] if isinstance(item['created_at'], datetime) else datetime.fromisoformat(str(item['created_at']))
    item2 = {**item, 'created_at': time - timedelta(minutes=range)}
    LOGGER.debug(f'dynamodb_query_item item2: {item2}')
    response2 = resource.Table(table).query(
        KeyConditionExpression=Key('id').eq(get_partition_key(item2)) & Key('sk').begins_with(str(item2['transaction_id'])),
        ScanIndexForward=False
    )
    LOGGER.debug(f'dynamodb_query_item response2: {response2}')
    result = {
        'Count': int(response['Count']) + int(response2['Count']),
        'Items': response['Items'] + response2['Items'],
    }
    result['Statuses'] = [d['transaction_status'] for d in result['Items'] if 'transaction_status' in d]
    return result

def dynamodb_query_by_item(region, table, item, key=None, range=60):
    resource = boto3.resource('dynamodb', region_name=region)
    kwargs = {'KeyConditionExpression': Key('id').eq(get_partition_key(item))}
    if key:
        kwargs['ExclusiveStartKey'] = key
    return resource.Table(table).query(**kwargs)

def dynamodb_put_item(region, table, attributes, replicated=None):
    resource = boto3.resource('dynamodb', region_name=region)
    item = dynamodb_item(attributes)
    status = 'FLAG'
    result = {'item': item}
    LOGGER.debug(f'dynamodb_put_item: {item}')
    if item['transaction_status'] in ['ACCP']:
        item2 = {**item, 'transaction_status': status}
        item2['created_at'] = str(item['created_at']
            if isinstance(item['created_at'], datetime)
            else datetime.fromisoformat(str(item['created_at']))
            + timedelta(microseconds=1))
        item2['id'] = get_partition_key(item2)
        item2['sk'] = get_sort_key(item2)
        result['response'] = resource.Table(table).put_item(Item=item2)
        LOGGER.debug(f'dynamodb_get_by_item ACCP: {result["response"]}')
    elif item['transaction_status'] in ['ACSC', 'RJCT', 'CANC', 'FAIL']:
        response = dynamodb_get_by_item(region, table, item)
        LOGGER.debug(f'dynamodb_get_by_item ACSC, RJCT, CANC, FAIL: {response}')
        for i in response['Items']:
            if i['transaction_status'] == status:
                try:
                    resource.Table(table).delete_item(Key={'id': i['id'], 'sk': i['sk']})
                except Exception as e:
                    pass # nosec B110
                break
    result['response'] = resource.Table(table).put_item(Item=item)
    LOGGER.debug(f'dynamodb_get_by_item {item["transaction_status"]}: {result["response"]}')
    if replicated:
        result['replicated'] = dynamodb_replicated(replicated['region'], replicated['region2'],
            replicated['count'], item['id'], item['transaction_status'], replicated['identity'])
    LOGGER.debug(f'dynamodb put item result: {result}')
    return result

def dynamodb_recover_cross_region(region, region2, table, item):
    result = []
    key = None
    flag = True
    while flag:
        item2 = {**item, 'request_region': region2, 'transaction_status': 'FLAG'}
        response = dynamodb_query_by_item(region, table, item2, key)
        if response:
            if 'Items' in response:
                for i in response['Items']:
                    item3 = {**i, **item}
                    result += dynamodb_put_item(region, table, item3)
            if 'LastEvaluatedKey' in response:
                key = response['LastEvaluatedKey']
            else:
                flag = False
        else:
            flag = False
    return result

def dynamodb_replicated(region, region2, req_count=5, id=None, status=None, identity=None):
    headers = {'X-S3-Skip': 1, 'X-SNS-Skip': 1, 'X-SQS-Skip': 1, 'X-Transaction-Region': region}
    if id:
        headers['X-Transaction-Id'] = id
    if status:
        headers['X-Transaction-Status'] = status
    payload = {'identity': identity}

    iter = 0
    # @TODO: exponential back-off
    while iter < req_count:
        response = lambda_health_check(region2, headers, payload)
        LOGGER.debug(f'lambda health check response {iter}: {response}')
        if not('StatusCode' in response and response['StatusCode'] == 200):
            return False
        else:
            payload = json.loads(response['Payload'].read())
            LOGGER.debug(f'lambda health check payload: {payload}')
            body = json.loads(payload['body'])
            LOGGER.debug(f'lambda health check body: {body}')
            if int(body['dynamodb_count']) == 0:
                iter += 1
            else:
                return True
    return False

def lambda_health_check(region, headers=None, payload=None, function="rp2-health"):
    lambd = boto3.client('lambda', region_name=region)
    _payload = {}
    if headers:
        _headers = {'Content-Type': 'application/json'}
        if 'X-DynamoDB-Skip' in headers:
            _headers['X-DynamoDB-Skip'] = headers['X-DynamoDB-Skip']
        if 'X-S3-Skip' in headers:
            _headers['X-S3-Skip'] = headers['X-S3-Skip']
        if 'X-SNS-Skip' in headers:
            _headers['X-SNS-Skip'] = headers['X-SNS-Skip']
        if 'X-SQS-Skip' in headers:
            _headers['X-SQS-Skip'] = headers['X-SQS-Skip']
        if 'X-Transaction-Id' in headers:
            _headers['X-Transaction-Id'] = headers['X-Transaction-Id']
        if 'X-Transaction-Status' in headers:
            _headers['X-Transaction-Status'] = headers['X-Transaction-Status']
        if 'X-Transaction-Region' in headers:
            _headers['X-Transaction-Region'] = headers['X-Transaction-Region']
        _payload['headers'] = _headers
    if payload:
        if 'identity' in payload:
            _payload['identity'] = payload['identity']
    return lambd.invoke(
        FunctionName=function, InvocationType='RequestResponse',
        Payload=json.dumps(_payload))

def lambda_validate(event, id):
    if 'body' in event and event['body'] and 'Records' in event['body']:
        event = json.loads(event['body'])

    if 'Records' in event and event['Records'] and 'eventSource' in event['Records'][0] and event['Records'][0]['eventSource'] in ['aws:s3', 'aws:sqs']:
        return None

    metadata = {
        'ErrorCode': 'NARR',
        'RequestId': id,
    }

    # validate event method
    if 'method' not in event and 'httpMethod' not in event:
        msg = 'method is invalid or missing'
        return lambda_response(400, msg, metadata)

    # validate event identity
    if 'identity' not in event and 'requestContext' not in event and 'identity' not in event['requestContext']:
        msg = 'identity is invalid or missing'
        return lambda_response(400, msg, metadata)

    # validate event message body
    if 'body' not in event:
        msg = 'message body is invalid or missing'
        return lambda_response(400, msg, metadata)

    # validate transaction id
    if not('headers' in event and event['headers'] and 'X-Transaction-Id' in event['headers']):
        msg = 'transaction_id is invalid or missing'
        return lambda_response(400, msg, metadata)

    return None

def lambda_response(code=200, message='OK', metadata=None, start=None):
    body = {}
    if message:
        body['message'] = message
    if metadata:
        for k in metadata:
            body[re.sub(r'(?<!^)(?=[A-Z])', '_', k).lower()] = metadata[k]
    if start:
        body['request_timestamp'] = int(start.timestamp() * 1000)
        body['request_duration'] = (datetime.now(timezone.utc)-start).total_seconds()
    return {
        'statusCode': code,
        'body': json.dumps(body),
        'headers': {'Content-Type': 'application/json'}
    }

def auth2token(url, client_id, client_secret):
    if not url.startswith('http'):
        url = f'https://{url}'
    secret_hash = base64.b64encode(f'{client_id}:{client_secret}'.encode()).decode('utf-8')
    payload = {
        'client_id': client_id,
        'grant_type': 'client_credentials',
        'scope': 'rp2/read rp2/write',
    }
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': f'Basic {secret_hash}'
    }
    response = requests.post(f'{url}/oauth2/token', params=payload, headers=headers, timeout=15)
    return response.json() if response.status_code == 200 else response.text
