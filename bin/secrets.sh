#!/bin/bash

help()
{
  echo "Create placeholder secrets in Secrets Manager"
  echo
  echo "Syntax: secrets.sh [-q|r|f]"
  echo "Options:"
  echo "q     Specify secret name (e.g. rp2-client-mq)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "f     Specify failover region (e.g. us-west-2)"
  echo
}

set -o pipefail

RP2_SECRET=""
RP2_REGION=""
RP2_REGION2=""

while getopts "h:q:r:f:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_SECRET=$OPTARG;;
    r)
      RP2_REGION=$OPTARG;;
    f)
      RP2_REGION=$OPTARG;;
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

if [ ! -z "${TF_VAR_RP2_SECRET}" ]; then RP2_SECRET="${TF_VAR_RP2_SECRET}"; fi
if [ ! -z "${TF_VAR_RP2_REGION}" ]; then RP2_REGION="${TF_VAR_RP2_REGION}"; fi
if [ ! -z "${TF_VAR_RP2_REGION2}" ]; then RP2_REGION2="${TF_VAR_RP2_REGION2}"; fi

if [ -z "${RP2_SECRET}" ]; then echo "[ERROR] RP2_SECRET is missing..."; exit 1; fi
if [ -z "${RP2_REGION}" ]; then echo "[ERROR] RP2_REGION is missing..."; exit 1; fi
if [ -z "${RP2_REGION2}" ]; then echo "[ERROR] RP2_REGION2 is missing..."; exit 1; fi

if [ -z "${RP2_SECRET##*_region_*}" ]; then
  RP2_SECRET=${RP2_SECRET/_region_/${RP2_REGION2}}
fi

echo "[EXEC] aws secretsmanager get-secret-value --secret-id ${RP2_SECRET} --region ${RP2_REGION}"
RP2_RESULT=$(aws secretsmanager get-secret-value --secret-id ${RP2_SECRET} --region ${RP2_REGION})

if [ -z "${RP2_RESULT##*error*}" ]; then
  echo "[EXEC] aws secretsmanager create-secret --name ${RP2_SECRET} --add-replica-regions Region=${RP2_REGION2} --force-overwrite-replica-secret --region ${RP2_REGION}"
  RP2_RESULT=$(aws secretsmanager create-secret --name ${RP2_SECRET} --add-replica-regions Region=${RP2_REGION2} --force-overwrite-replica-secret --region ${RP2_REGION})

  if [ ! -z "${RP2_RESULT##*error*}" ]; then
    echo "[EXEC] aws secretsmanager put-secret-value --secret-id ${RP2_SECRET} --secret-string '{}' --region ${RP2_REGION}"
    aws secretsmanager put-secret-value --secret-id ${RP2_SECRET} --secret-string '{}' --region ${RP2_REGION}
  fi
fi
