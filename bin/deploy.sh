#!/bin/bash

help()
{
  echo "Deploy AWS resource using Terraform and Terragrunt"
  echo
  echo "Syntax: deploy.sh [-q|r|t|i|d|c|b]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "t     Specify S3 bucket (e.g. rp2-backend-us-east-1)"
  echo "i     Specify unique id (e.g. abcd1234)"
  echo "d     Specify directory (e.g. iac.cicd)"
  echo "c     Specify cleanup / destroy resources (e.g. true)"
  echo "b     Specify Terraform backend config (e.g. {\"us-east-1\"=\"rp2-backend-us-east-1\"})"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_REGION=""
RP2_BUCKET=""
RP2_BACKEND=""
RP2_ID=""
DIRECTORY="iac.cicd"
CLEANUP=""

while getopts "h:q:r:t:i:d:c:b:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_DOMAIN=$OPTARG;;
    r)
      RP2_REGION=$OPTARG;;
    t)
      RP2_BUCKET=$OPTARG;;
    i)
      RP2_ID=$OPTARG;;
    d)
      DIRECTORY=$OPTARG;;
    c)
      CLEANUP=$OPTARG;;
    b)
      RP2_BACKEND=$OPTARG;;
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

aws --version > /dev/null 2>&1 || { echo "[ERROR] aws is missing. aborting..."; exit 1; }
terraform -version > /dev/null 2>&1 || { echo "[ERROR] terraform is missing. aborting..."; exit 1; }
terragrunt -version > /dev/null 2>&1 || { echo "[ERROR] terragrunt is missing. aborting..."; exit 1; }

if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_DEFAULT_REGION}" ]; then RP2_REGION="${AWS_DEFAULT_REGION}"; fi
if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_REGION}" ]; then RP2_REGION="${AWS_REGION}"; fi

if [ -z "${RP2_DOMAIN}" ]; then
  echo "[DEBUG] RP2_DOMAIN: ${RP2_DOMAIN}"
  echo "[ERROR] RP2_DOMAIN is missing..."; exit 1;
fi

if [ -z "${RP2_REGION}" ]; then
  echo "[DEBUG] RP2_REGION: ${RP2_REGION}"
  echo "[ERROR] RP2_REGION is missing..."; exit 1;
fi

if [ -z "${RP2_BUCKET}" ]; then
  echo "[DEBUG] RP2_BUCKET: ${RP2_BUCKET}"
  echo "[ERROR] RP2_BUCKET is missing..."; exit 1;
fi

if [ -z "${RP2_BACKEND}" ]; then
  RP2_BACKEND={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"}
fi

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"
OPTIONS="-var custom_domain=${RP2_DOMAIN} -var backend_bucket=${RP2_BACKEND}"

if [ ! -z "${RP2_ID}" ]; then
  OPTIONS="${OPTIONS} -var rp2_id=${RP2_ID}"
fi

echo "[EXEC] cd ${WORKDIR}/${DIRECTORY}/"
cd ${WORKDIR}/${DIRECTORY}/

echo "[EXEC] terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET}"
terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET} || { echo "[ERROR] terragrunt run-all init failed. aborting..."; cd -; exit 1; }

if [ ! -z "${CLEANUP}" ] && [ "${CLEANUP}" == "true" ]; then
  echo "[EXEC] terragrunt run-all destroy -auto-approve -var-file default.tfvars ${OPTIONS}"
  echo "Y" | terragrunt run-all destroy -auto-approve -var-file default.tfvars ${OPTIONS} || { echo "[ERROR] terragrunt run-all destroy failed. aborting..."; cd -; exit 1; }
else
  echo "[EXEC] terragrunt run-all apply -auto-approve -var-file default.tfvars ${OPTIONS}"
  echo "Y" | terragrunt run-all apply -auto-approve -var-file default.tfvars ${OPTIONS} || { echo "[ERROR] terragrunt run-all apply failed. aborting..."; cd -; exit 1; }
fi

echo "[EXEC] cd -"
cd -
