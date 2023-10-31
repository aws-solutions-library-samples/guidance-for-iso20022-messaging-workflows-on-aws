FROM public.ecr.aws/docker/library/alpine:latest AS layer

ARG AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
ARG AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}
ARG AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-""}
ARG AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN:-""}

ENV AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}

# work-around: https://aws.amazon.com/blogs/compute/working-with-lambda-layers-and-extensions-in-container-images/
# lambda layer: https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_lambda.html
# x86_64 => arn:aws:lambda:us-east-1:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension:4
# arm64  => arn:aws:lambda:us-east-1:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension-Arm64:4
ARG LAYER_ARN=${LAYER_ARN:-"arn:aws:lambda:us-east-1:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension-Arm64:4"}
ARG LAYER_REGION=${LAYER_REGION:-"us-east-1"}

RUN apk add aws-cli curl unzip
RUN curl $(aws lambda get-layer-version-by-arn --arn ${LAYER_ARN} --region ${LAYER_REGION} --query 'Content.Location' --output text) --output layer.zip
RUN mkdir -p /opt
RUN unzip layer.zip -d /opt
RUN rm layer.zip

FROM public.ecr.aws/lambda/python:3.11-arm64 AS base

WORKDIR /opt
COPY --from=layer /opt/ .
# RUN pip3 install -r /opt/requirements.txt -t /opt/extensions/lib

ENV LANG=en_US.UTF-8 \
    TZ=:/etc/localtime \
    LAMBDA_TASK_ROOT=/var/task \
    LAMBDA_RUNTIME_DIR=/var/runtime \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=120

WORKDIR ${LAMBDA_TASK_ROOT}

ENV VIRTUAL_ENV=${LAMBDA_TASK_ROOT}/venv \
    PYTHONPATH=${PYTHONPATH}:${LAMBDA_TASK_ROOT} \
    LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/opt/lib:${LAMBDA_RUNTIME_DIR}:${LAMBDA_RUNTIME_DIR}/lib:${LAMBDA_TASK_ROOT}:${LAMBDA_TASK_ROOT}/lib

ENV PATH=${VIRTUAL_ENV}/bin:/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin:${PATH}

RUN yum update -y

COPY . .

RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt --target "${LAMBDA_TASK_ROOT}"
# work-around: https://github.com/psf/requests/issues/6443
RUN pip3 install --upgrade 'urllib3<2'

CMD [ "lambda_function.lambda_handler" ]

#checkov:skip=CKV_DOCKER_2:Skip health check
#checkov:skip=CKV_DOCKER_3:Skip user control
