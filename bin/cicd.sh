#!/bin/bash

help()
{
  echo "Create CI/CD Pipeline"
  echo
  echo "Syntax: cicd.sh [-q|r|t]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "t     Specify S3 bucket (e.g. rp2-backend-us-east-1)"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_REGION="us-east-1"
RP2_BUCKET="rp2-backend-us-east-1"

while getopts "h:q:r:t:" option; do
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
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

aws --version > /dev/null 2>&1 || { echo &2 "[ERROR] aws is missing. aborting..."; exit 1; }
terraform -version > /dev/null 2>&1 || { echo &2 "[ERROR] terraform is missing. aborting..."; exit 1; }
terragrunt -version > /dev/null 2>&1 || { echo &2 "[ERROR] terragrunt is missing. aborting..."; exit 1; }

if [ -z "${RP2_DOMAIN}" ]; then
  echo "[ERROR] RP2_DOMAIN is missing..."; exit 1;
fi

if [ -z "${RP2_REGION}" ]; then
  echo "[ERROR] RP2_REGION is missing..."; exit 1;
fi

if [ -z "${RP2_BUCKET}" ]; then
  echo "[ERROR] RP2_BUCKET is missing..."; exit 1;
fi

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"

echo "[EXEC] cd ${WORKDIR}/iac.cicd/"
cd ${WORKDIR}/iac.cicd/

echo "[EXEC] terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET}"
terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET}

echo "[EXEC] terragrunt run-all apply -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"}"
echo "Y" | terragrunt run-all apply -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"}

echo "[EXEC] cd -"
cd -
