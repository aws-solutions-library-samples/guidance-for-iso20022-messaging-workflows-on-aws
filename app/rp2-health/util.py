#!/usr/bin/env python3
import boto3, uuid, re, json, base64, requests, ssl, pika
from boto3.dynamodb.conditions import Key
from datetime import datetime, timedelta, timezone
from math import floor

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

def get_uuid5(item):
    # @TODO: distribute even further by tenant_id, worker_id, etc
    result = ""
    if 'created_at' in item and item['created_at']:
        result += get_timestamp(item['created_at'])
    if 'request_region' in item and item['request_region']:
        result += item['request_region']
    # if 'request_resource' in item and item['request_resource']:
    #     result += item['request_resource']
    # if 'created_by' in item and item['created_by']:
    #     result += item['created_by']
    # if 'message_id' in item and item['message_id']:
    #     result += item['message_id']
    if 'transaction_status' in item and item['transaction_status']:
        result += item['transaction_status']
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, result + '.com'))

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

def sns_publish_message(region, account, name, message, attributes=None):
    sns = boto3.client("sns", region_name=region)
    kwargs = {
        'TopicArn': f'arn:aws:sns:{region}:{account}:{name}',
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
    item['id'] = get_uuid5(item)
    return item

def dynamodb_get_by_item(region, table, item, range=60):
    resource = boto3.resource('dynamodb', region_name=region)
    response = resource.Table(table).get_item(Key={'id': get_uuid5(item), 'transaction_id': str(item['transaction_id'])})
    if 'Item' in response and response['Item'] and 'id' in response['Item']:
        return response
    time = item['created_at'] if isinstance(item['created_at'], datetime) else datetime.fromisoformat(str(item['created_at']))
    item2 = {**item, 'created_at': time - timedelta(minutes=range)}
    return resource.Table(table).get_item(Key={'id': get_uuid5(item2), 'transaction_id': str(item2['transaction_id'])})

def dynamodb_query_by_item(region, table, item, key=None, range=60):
    resource = boto3.resource('dynamodb', region_name=region)
    kwargs = {'KeyConditionExpression': Key('id').eq(get_uuid5(item))}
    if key:
        kwargs['ExclusiveStartKey'] = key
    return resource.Table(table).query(**kwargs)

def dynamodb_put_item(region, table, attributes, replicated=None):
    resource = boto3.resource('dynamodb', region_name=region)
    item = dynamodb_item(attributes)
    result = {'item': item}
    if item['transaction_status'] in ['ACCP']:
        id = get_uuid5({**item, 'transaction_status': 'FLAG'})
        resource.Table(table).put_item(Item={**item, 'id': id, 'transaction_status': 'FLAG'})
    elif item['transaction_status'] in ['ACSC', 'RJCT', 'CANC', 'FAIL']:
        try:
            if item['transaction_status'] == 'CANC' and attributes['id']:
                id = attributes['id']
            else:
                tnx = dynamodb_get_by_item(region, table, {**item, 'transaction_status': 'FLAG'})
                id = tnx['Item']['id']
            resource.Table(table).delete_item(Key={'id': id, 'transaction_id': item['transaction_id']})
        except Exception as e:
            pass
    result['response'] = resource.Table(table).put_item(Item=item)
    if replicated:
        result['replicated'] = dynamodb_replicated(replicated['api_url'],
            replicated['auth'], replicated['count'], item['id'], item['transaction_status'])
    return result

def dynamodb_recover_cross_region(region, table, item, region2):
    result = []
    flag = True
    key = None
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

def dynamodb_replicated(api_url, auth_url, client_id, client_secret, req_count=5, id=None, status=None):
    # @TODO: exponential back-off
    iter = 0
    auth = {
        'auth_url': auth_url,
        'client_id': client_id,
        'client_secret': client_secret
    }
    health_check = request_health_check(api_url, auth, id, status, s3_skip=1, sqs_skip=1)
    while iter < req_count:
        response = health_check['health_check']
        if not(hasattr(response, 'status_code') and response.status_code == 200):
            return False
        elif int(response.json()['dynamodb_count']) == 0:
            iter += 1
            token = {'access_token': health_check['access_token']}
            health_check = request_health_check(api_url, token, id, status, s3_skip=1, sqs_skip=1)
        else:
            return True
    return False

def request_health_check(api_url, auth=None, id=None, status=None, ddb_skip=None, s3_skip=None, sqs_skip=None):
    if not api_url.startswith('http'):
        api_url = f'https://{api_url}'
    token = None
    headers = {'Content-Type': 'application/json'}
    if auth:
        if 'auth_url' in auth and 'client_id' in auth and 'client_secret' in auth:
            token = auth2token(auth['auth_url'], auth['client_id'], auth['client_secret'])
            if 'access_token' in token and token['access_token']:
                token = token['access_token']
        elif 'access_token' in auth:
            token = auth['access_token']
    if token:
        headers['Authorization'] = f'Bearer {token}'
    if id:
        headers['X-Transaction-Id'] = id
    if status:
        headers['X-Transaction-Status'] = status
    if ddb_skip:
        headers['X-DynamoDB-Skip'] = ddb_skip
    if s3_skip:
        headers['X-S3-Skip'] = s3_skip
    if sqs_skip:
        headers['X-SQS-Skip'] = sqs_skip
    return {
        'access_token': token,
        'health_check': requests.get(api_url, headers=headers, timeout=15)
    }

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

def lambda_invoke(region, name, headers=None, payload=None):
    lambd = boto3.client('lambda', region_name=region)
    _payload = {}
    if headers:
        _headers = {}
        if 'Content-Type' in headers:
            _headers['Content-Type'] = headers['Content-Type']
        if 'X-Message-Type' in headers:
            _headers['X-Message-Type'] = headers['X-Message-Type']
        if 'X-Transaction-Id' in headers:
            _headers['X-Transaction-Id'] = headers['X-Transaction-Id']
        _payload['headers'] = _headers
    if payload:
        if 'identity' in payload:
            _payload['identity'] = payload['identity']
        if 'method' in payload:
            _payload['method'] = payload['method']
        if 'body' in payload:
            _payload['body'] = payload['body']
    return lambd.invoke(
        FunctionName=name, InvocationType='Event',
        Payload=json.dumps(_payload))

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

def connect2rmq(host, port, user, pwd):
    credentials = pika.PlainCredentials(user, pwd)
    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    parameters = pika.ConnectionParameters(
        host=host, port=port, credentials=credentials,
        ssl_options=pika.SSLOptions(context), virtual_host='/')
    return pika.BlockingConnection(parameters)

def publish2rmq(connection, data, count, exchange, routing_key):
    main_channel = connection.channel()
    properties = pika.BasicProperties(
        app_id='default_application',
        content_type='application/json',
        headers={u'X-Message-Type': u'pacs.008'}
    )
    iter = 0
    while iter < count:
        main_channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=data, properties=properties)
        iter += 1
