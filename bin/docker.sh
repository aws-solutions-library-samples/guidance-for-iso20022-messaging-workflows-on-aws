#!/bin/bash

help()
{
  echo "Build image based on Dockerfile and push it to private container registry"
  echo
  echo "Syntax: docker.sh [-q|r|v|p|d|u]"
  echo "Options:"
  echo "q     Specify repository name (e.g. rp2-inbox)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "v     Specify version number (e.g. latest)"
  echo "p     Specify platform (e.g. linux/arm64)"
  echo "d     Specify directory (e.g. app.src)"
  echo "f     Specify Dockerfile (e.g. Dockerfile)"
  echo "u     Update Lambda function (e.g. true)"
  echo
}

set -o pipefail

REGION="us-east-1"
REPOSITORY="rp2-health"
VERSION="latest"
PLATFORM="linux/arm64"
DIRECTORY="app.src"
DOCKERFILE="Dockerfile"
UPDATE=""

while getopts "h:q:r:v:p:d:f:u:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      REPOSITORY=$OPTARG;;
    r)
      REGION=$OPTARG;;
    v)
      VERSION=$OPTARG;;
    p)
      PLATFORM=$OPTARG;;
    d)
      DIRECTORY=$OPTARG;;
    f)
      DOCKERFILE=$OPTARG;;
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

if [ ! -z "${TF_VAR_RP2_REGION}" ]; then REGION="${TF_VAR_RP2_REGION}"; fi

if [ -z "${REGION}" ]; then
  echo "[DEBUG] REGION: ${REGION}"
  echo "[ERROR] REGION is missing. aborting..."; exit 1;
fi

if [ -z "${REPOSITORY}" ]; then
  echo "[DEBUG] REPOSITORY: ${REPOSITORY}"
  echo "[ERROR] REPOSITORY is missing. aborting..."; exit 1;
fi

if [ -z "${VERSION}" ]; then
  echo "[DEBUG] VERSION: ${VERSION}"
  echo "[ERROR] VERSION is missing. aborting..."; exit 1;
fi

if [ -z "${PLATFORM}" ]; then
  echo "[DEBUG] PLATFORM: ${PLATFORM}"
  echo "[ERROR] PLATFORM is missing. aborting..."; exit 1;
fi

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"
ACCOUNT=$(aws sts get-caller-identity --query Account --region ${REGION})
ACCOUNT=${ACCOUNT//\"/}
ENDPOINT="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
DOCKER_CONFIG="${WORKDIR}/.docker"

echo "[INFO] echo {\"credsStore\":\"ecr-login\"} > ${DOCKER_CONFIG}/config.json"
mkdir -p ${DOCKER_CONFIG} && touch ${DOCKER_CONFIG}/config.json && echo "{\"credsStore\":\"ecr-login\"}" > ${DOCKER_CONFIG}/config.json

echo "[INFO] aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ENDPOINT}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ENDPOINT} || { echo "[ERROR] docker login failed. aborting..."; exit 1; }

echo "[INFO] aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/rp2-cicd-assume-role --role-session-name ${ACCOUNT}"
ASSUME_ROLE=$(aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/rp2-cicd-assume-role --role-session-name ${ACCOUNT})

echo "[INFO] docker build -t ${REPOSITORY}:${VERSION} -f ${WORKDIR}/${DOCKERFILE} ${WORKDIR}/${DIRECTORY}/${REPOSITORY}/ --platform ${PLATFORM}"
docker build -t ${REPOSITORY}:${VERSION} -f ${WORKDIR}/${DOCKERFILE} ${WORKDIR}/${DIRECTORY}/${REPOSITORY}/ --platform ${PLATFORM} --build-arg AWS_DEFAULT_REGION=${REGION} --build-arg AWS_ACCESS_KEY_ID=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.AccessKeyId') --build-arg AWS_SECRET_ACCESS_KEY=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.SecretAccessKey') --build-arg AWS_SESSION_TOKEN=$(echo "${ASSUME_ROLE}" | jq -r '.Credentials.SessionToken') || { echo "[ERROR] docker build failed. aborting..."; exit 1; }

echo "[INFO] docker tag ${REPOSITORY}:${VERSION} ${ENDPOINT}/${REPOSITORY}:${VERSION}"
docker tag ${REPOSITORY}:${VERSION} ${ENDPOINT}/${REPOSITORY}:${VERSION} || { echo "[ERROR] docker tag failed. aborting..."; exit 1; }

echo "[INFO] docker push ${ENDPOINT}/${REPOSITORY}:${VERSION}"
OUTPUT=$(docker push ${ENDPOINT}/${REPOSITORY}:${VERSION}) || { echo "[ERROR] docker push failed. aborting..."; exit 1; }

echo "[INFO] OUTPUT: ${OUTPUT}"
IFS=' ' read -ra ARR <<< "$(echo "${OUTPUT}" | tr '\n' ' ')"

if [ ! -z "${UPDATE}" -a "${UPDATE}" == "true" ]; then
  echo "[INFO] aws lambda update-function-code --region ${REGION} --function-name ${REPOSITORY} --image-uri ${ENDPOINT}/${REPOSITORY}@${ARR[${#ARR[@]} - 3]}"
  aws lambda update-function-code --region ${REGION} --function-name ${REPOSITORY} --image-uri ${ENDPOINT}/${REPOSITORY}@${ARR[${#ARR[@]} - 3]}
fi
