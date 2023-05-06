#!/bin/bash

help()
{
  echo "Validate pre-requisite requirements"
  echo
  echo "Syntax: validate.sh [-q|t]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "t     Specify S3 bucket (e.g. rp2-backend-us-east-1)"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_BUCKET=""

while getopts "h:q:t:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_DOMAIN=$OPTARG;;
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

if [ -z "${RP2_DOMAIN}" ]; then
  echo "[ERROR] RP2_DOMAIN is missing..."; exit 1;
fi

if [ -z "${RP2_BUCKET}" ]; then
  echo "[ERROR] RP2_BUCKET is missing..."; exit 1;
fi

echo "[EXEC] aws sts get-caller-identity"
aws sts get-caller-identity

echo "[EXEC] aws ec2 describe-availability-zones --query \"AvailabilityZones[\*].ZoneId\""
aws ec2 describe-availability-zones --query "AvailabilityZones[*].ZoneId"

echo "[EXEC] aws iam create-service-linked-role --aws-service-name acm.amazonaws.com"
aws iam create-service-linked-role --aws-service-name acm.amazonaws.com

echo "[EXEC] aws iam create-service-linked-role --aws-service-name replication.dynamodb.amazonaws.com"
aws iam create-service-linked-role --aws-service-name replication.dynamodb.amazonaws.com

echo "[EXEC] aws iam create-service-linked-role --aws-service-name replication.ecr.amazonaws.com"
aws iam create-service-linked-role --aws-service-name replication.ecr.amazonaws.com

echo "[EXEC] terraform init -input=false -no-color"
terraform init -input=false -no-color

echo "[EXEC] terraform plan -var=\"resource_prefix=${RP2_BUCKET}\" -var=\"custom_domain=${RP2_DOMAIN}\" -out=terraform.tfplan"
terraform plan -var="resource_prefix=${RP2_BUCKET}" -var="custom_domain=${RP2_DOMAIN}" -out=terraform.tfplan

echo "[EXEC] terraform apply -auto-approve terraform.tfplan"
terraform apply -auto-approve terraform.tfplan

echo "[EXEC] terraform output"
terraform output

echo "[EXEC] terraform plan -destroy -var=\"resource_prefix=${RP2_BUCKET}\" -var=\"custom_domain=${RP2_DOMAIN}\" -out=terraform.tfplan"
terraform plan -destroy -var="resource_prefix=${RP2_BUCKET}" -var="custom_domain=${RP2_DOMAIN}" -out=terraform.tfplan

echo "[EXEC] terraform apply -destroy -auto-approve terraform.tfplan"
terraform apply -destroy -auto-approve terraform.tfplan

echo "[EXEC] rm -rf .terraform* terraform*"
rm -rf .terraform* terraform*
