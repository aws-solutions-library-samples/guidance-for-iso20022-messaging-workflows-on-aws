#!/bin/bash

help()
{
  echo "Deploy AWS resource using Terraform and Terragrunt"
  echo
  echo "Syntax: deploy.sh [-q|r|t|d|c]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "t     Specify S3 bucket (e.g. rp2-backend-us-east-1)"
  echo "d     Specify directory (e.g. iac.cicd)"
  echo "c     Specify cleanup / resource removal (e.g. true)"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_REGION="us-east-1"
RP2_BUCKET="rp2-backend-us-east-1"
DIRECTORY="iac.cicd"
CLEANUP=""

while getopts "h:q:r:t:d:c:" option; do
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
    d)
      DIRECTORY=$OPTARG;;
    d)
      CLEANUP=$OPTARG;;
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

if [ ! -z "${TF_VAR_CUSTOM_DOMAIN}" ]; then RP2_DOMAIN="${TF_VAR_CUSTOM_DOMAIN}"; fi
if [ ! -z "${TF_VAR_RP2_REGION}" ]; then RP2_REGION="${TF_VAR_RP2_REGION}"; fi

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

echo "[EXEC] cd ${WORKDIR}/${DIRECTORY}/"
cd ${WORKDIR}/${DIRECTORY}/

echo "[EXEC] terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET}"
terragrunt run-all init -backend-config region=${RP2_REGION} -backend-config bucket=${RP2_BUCKET} || { echo &2 "[ERROR] terragrunt run-all init failed. aborting..."; cd -; exit 1; }

if [ ! -z "${CLEANUP}" -a "${CLEANUP}" == "true" ]; then
  echo "[EXEC] terragrunt run-all destroy -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"}"
  echo "Y" | terragrunt run-all destroy -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"} || { echo &2 "[ERROR] terragrunt run-all destroy failed. aborting..."; cd -; exit 1; }
else
  echo "[EXEC] terragrunt run-all apply -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"}"
  echo "Y" | terragrunt run-all apply -auto-approve -var-file default.tfvars -var custom_domain=${RP2_DOMAIN} -var backend_bucket={\"${RP2_REGION}\"=\"${RP2_BUCKET}\"} || { echo &2 "[ERROR] terragrunt run-all apply failed. aborting..."; cd -; exit 1; }
fi

echo "[EXEC] cd -"
cd -
