#!/bin/bash

help()
{
  echo "Build image based on Dockerfile and push it to private container registry"
  echo
  echo "Syntax: docker.sh [-q|r|v|p|u]"
  echo "Options:"
  echo "q     Specify repository name (e.g. rp2-inbox)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "v     Specify version number (e.g. latest)"
  echo "p     Specify platform (e.g. linux/arm64)"
  echo "u     Update Lambda function (e.g. true)"
  echo
}

set -o pipefail

REGION="us-east-1"
REPOSITORY="rp2-health"
VERSION="latest"
PLATFORM="linux/arm64"
UPDATE=""

while getopts "h:q:r:v:p:u:" option; do
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
aws --version > /dev/null 2>&1 || { echo &2 "[ERROR] aws is missing. aborting..."; exit 1; }
docker --version > /dev/null 2>&1 || { echo &2 "[ERROR] docker is missing. aborting..."; exit 1; }

if [ ! -z "${TF_VAR_RP2_REGION}" ]; then REGION="${TF_VAR_RP2_REGION}"; fi
if [ -z "${REGION}" ]; then echo &2 "[ERROR] REGION is missing. aborting..."; exit 1; fi
if [ -z "${REPOSITORY}" ]; then echo &2 "[ERROR] REPOSITORY is missing. aborting..."; exit 1; fi
if [ -z "${VERSION}" ]; then echo &2 "[ERROR] VERSION is missing. aborting..."; exit 1; fi
if [ -z "${PLATFORM}" ]; then echo &2 "[ERROR] PLATFORM is missing. aborting..."; exit 1; fi

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"
ACCOUNT=$(aws sts get-caller-identity --query Account --region ${REGION})
ACCOUNT=${ACCOUNT//\"/}
ENDPOINT="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

echo "[INFO] aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ENDPOINT}"
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ENDPOINT} || { echo &2 "[ERROR] docker login failed. aborting..."; exit 1; }

echo "[INFO] docker build -t ${REPOSITORY}:${VERSION} -f ${WORKDIR}/Dockerfile ${WORKDIR}/app/${REPOSITORY}/ --platform ${PLATFORM}"
docker build -t ${REPOSITORY}:${VERSION} -f ${WORKDIR}/Dockerfile ${WORKDIR}/app/${REPOSITORY}/ --platform ${PLATFORM} || { echo &2 "[ERROR] docker build failed. aborting..."; exit 1; }

echo "[INFO] docker tag ${REPOSITORY}:${VERSION} ${ENDPOINT}/${REPOSITORY}:${VERSION}"
docker tag ${REPOSITORY}:${VERSION} ${ENDPOINT}/${REPOSITORY}:${VERSION} || { echo &2 "[ERROR] docker tag failed. aborting..."; exit 1; }

echo "[INFO] docker push ${ENDPOINT}/${REPOSITORY}:${VERSION}"
OUTPUT=$(docker push ${ENDPOINT}/${REPOSITORY}:${VERSION}) || { echo &2 "[ERROR] docker push failed. aborting..."; exit 1; }

echo "[INFO] OUTPUT: ${OUTPUT}"
IFS=' ' read -ra ARR <<< "$(echo "${OUTPUT}" | tr '\n' ' ')"

if [ ! -z "${UPDATE}" -a "${UPDATE}" == "true" ]; then
  echo "[INFO] aws lambda update-function-code --region ${REGION} --function-name ${REPOSITORY} --image-uri ${ENDPOINT}/${REPOSITORY}@${ARR[${#ARR[@]} - 3]}"
  aws lambda update-function-code --region ${REGION} --function-name ${REPOSITORY} --image-uri ${ENDPOINT}/${REPOSITORY}@${ARR[${#ARR[@]} - 3]}
fi
