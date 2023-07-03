#!/bin/bash

help()
{
  echo "Build image based on Dockerfile and push it to private container registry"
  echo
  echo "Syntax: docker.sh [-q|r|v|p|d|f|g|u]"
  echo "Options:"
  echo "q     Specify repository name (e.g. rp2-health)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "v     Specify version number (e.g. latest)"
  echo "p     Specify platform (e.g. linux/arm64)"
  echo "d     Specify directory (e.g. app.src)"
  echo "f     Specify Dockerfile (e.g. Dockerfile)"
  echo "g     Specify CI/CD role name (e.g. rp2-cicd-assume-role-abcd1234)"
  echo "u     Specify update to Lambda function (e.g. true)"
  echo
}

set -o pipefail

RP2_REPOSITORY=""
RP2_REGION=""
RP2_VERSION="latest"
RP2_PLATFORM="linux/arm64"
DIRECTORY="app.src"
DOCKERFILE="Dockerfile"
ROLENAME=""
UPDATE=""

while getopts "h:q:r:v:p:d:f:g:u:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_REPOSITORY=$OPTARG;;
    r)
      RP2_REGION=$OPTARG;;
    v)
      RP2_VERSION=$OPTARG;;
    p)
      RP2_PLATFORM=$OPTARG;;
    d)
      DIRECTORY=$OPTARG;;
    f)
      DOCKERFILE=$OPTARG;;
    g)
      ROLENAME=$OPTARG;;
    u)
      UPDATE=$OPTARG;;
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

aws --version > /dev/null 2>&1 || { pip install awscli; }
aws --version > /dev/null 2>&1 || { echo "[ERROR] aws is missing. aborting..."; exit 1; }
docker --version > /dev/null 2>&1 || { echo "[ERROR] docker is missing. aborting..."; exit 1; }

if [ -z "${ROLENAME}" ] && [ ! -z "${TF_VAR_ROLE_NAME}" ]; then ROLENAME="${TF_VAR_ROLE_NAME}"; fi
if [ -z "${RP2_REGION}" ] && [ ! -z "${TF_VAR_RP2_REGION}" ]; then RP2_REGION="${TF_VAR_RP2_REGION}"; fi
if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_DEFAULT_REGION}" ]; then RP2_REGION="${AWS_DEFAULT_REGION}"; fi
if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_REGION}" ]; then RP2_REGION="${AWS_REGION}"; fi

if [ -z "${RP2_REGION}" ]; then
  echo "[DEBUG] RP2_REGION: ${RP2_REGION}"
  echo "[ERROR] RP2_REGION is missing. aborting..."; exit 1;
fi

if [ -z "${RP2_REPOSITORY}" ]; then
  echo "[DEBUG] RP2_REPOSITORY: ${RP2_REPOSITORY}"
  echo "[ERROR] RP2_REPOSITORY is missing. aborting..."; exit 1;
fi

if [ -z "${RP2_VERSION}" ]; then
  echo "[DEBUG] RP2_VERSION: ${RP2_VERSION}"
  echo "[ERROR] RP2_VERSION is missing. aborting..."; exit 1;
fi

if [ -z "${RP2_PLATFORM}" ]; then
  echo "[DEBUG] RP2_PLATFORM: ${RP2_PLATFORM}"
  echo "[ERROR] RP2_PLATFORM is missing. aborting..."; exit 1;
fi

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"
ACCOUNT=$(aws sts get-caller-identity --query Account --region ${RP2_REGION})
ACCOUNT=${ACCOUNT//\"/}
ENDPOINT="${ACCOUNT}.dkr.ecr.${RP2_REGION}.amazonaws.com"
DOCKER_CONFIG="${WORKDIR}/.docker"
OPTIONS=""

echo "[INFO] echo {\"credsStore\":\"ecr-login\"} > ${DOCKER_CONFIG}/config.json"
mkdir -p ${DOCKER_CONFIG} && touch ${DOCKER_CONFIG}/config.json && echo "{\"credsStore\":\"ecr-login\"}" > ${DOCKER_CONFIG}/config.json

echo "[INFO] aws ecr get-login-password --region ${RP2_REGION} | docker login --username AWS --password-stdin ${ENDPOINT}"
aws ecr get-login-password --region ${RP2_REGION} | docker login --username AWS --password-stdin ${ENDPOINT} || { echo "[ERROR] docker login failed. aborting..."; exit 1; }

if [ ! -z "${ROLENAME}" ]; then
  echo "[INFO] aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/${ROLENAME} --role-session-name ${ACCOUNT}"
  ASSUME_ROLE=$(aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/${ROLENAME} --role-session-name ${ACCOUNT})
  OPTIONS="${OPTIONS} --build-arg AWS_DEFAULT_REGION=${RP2_REGION}"
  OPTIONS="${OPTIONS} --build-arg AWS_ACCESS_KEY_ID=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.AccessKeyId')"
  OPTIONS="${OPTIONS} --build-arg AWS_SECRET_ACCESS_KEY=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.SecretAccessKey')"
  OPTIONS="${OPTIONS} --build-arg AWS_SESSION_TOKEN=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.SessionToken')"
fi

echo "[INFO] docker build -t ${RP2_REPOSITORY}:${RP2_VERSION} -f ${WORKDIR}/${DOCKERFILE} ${WORKDIR}/${DIRECTORY}/${RP2_REPOSITORY}/ --platform ${RP2_PLATFORM}"
docker build -t ${RP2_REPOSITORY}:${RP2_VERSION} -f ${WORKDIR}/${DOCKERFILE} ${WORKDIR}/${DIRECTORY}/${RP2_REPOSITORY}/ --platform ${RP2_PLATFORM} ${OPTIONS} || { echo "[ERROR] docker build failed. aborting..."; exit 1; }

echo "[INFO] docker tag ${RP2_REPOSITORY}:${RP2_VERSION} ${ENDPOINT}/${RP2_REPOSITORY}:${RP2_VERSION}"
docker tag ${RP2_REPOSITORY}:${RP2_VERSION} ${ENDPOINT}/${RP2_REPOSITORY}:${RP2_VERSION} || { echo "[ERROR] docker tag failed. aborting..."; exit 1; }

echo "[INFO] docker push ${ENDPOINT}/${RP2_REPOSITORY}:${RP2_VERSION}"
OUTPUT=$(docker push ${ENDPOINT}/${RP2_REPOSITORY}:${RP2_VERSION}) || { echo "[ERROR] docker push failed. aborting..."; exit 1; }

echo "[INFO] OUTPUT: ${OUTPUT}"
IFS=' ' read -ra ARR <<< "$(echo "${OUTPUT}" | tr '\n' ' ')"

if [ ! -z "${UPDATE}" ] && [ "${UPDATE}" == "true" ]; then
  echo "[INFO] aws lambda update-function-code --region ${RP2_REGION} --function-name ${RP2_REPOSITORY} --image-uri ${ENDPOINT}/${RP2_REPOSITORY}@${ARR[${#ARR[@]} - 3]}"
  aws lambda update-function-code --region ${RP2_REGION} --function-name ${RP2_REPOSITORY} --image-uri ${ENDPOINT}/${RP2_REPOSITORY}@${ARR[${#ARR[@]} - 3]}
fi
