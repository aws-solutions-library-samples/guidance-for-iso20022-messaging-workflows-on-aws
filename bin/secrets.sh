#!/bin/bash

help()
{
  echo "Create placeholder secrets in Secrets Manager"
  echo
  echo "Syntax: secrets.sh [-q|r]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_REGION=""
RP2_REGION2=""

while getopts "h:q:r:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_DOMAIN=$OPTARG;;
    r)
      RP2_REGION=$OPTARG;;
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

if [ ! -z "${TF_VAR_RP2_DOMAIN}" ]; then RP2_DOMAIN="${TF_VAR_RP2_DOMAIN}"; fi
if [ ! -z "${TF_VAR_RP2_REGION}" ]; then RP2_REGION="${TF_VAR_RP2_REGION}"; fi
if [ ! -z "${TF_VAR_RP2_REGION2}" ]; then RP2_REGION2="${TF_VAR_RP2_REGION2}"; fi

if [ -z "${RP2_DOMAIN}" ]; then echo "[ERROR] RP2_DOMAIN is missing..."; exit 1; fi
if [ -z "${RP2_REGION}" ]; then echo "[ERROR] RP2_REGION is missing..."; exit 1; fi
if [ -z "${RP2_REGION2}" ]; then echo "[ERROR] RP2_REGION2 is missing..."; exit 1; fi

if [ -z "${RP2_DOMAIN##*_region_*}" ]; then
  RP2_DOMAIN=${RP2_DOMAIN/_region_/${RP2_REGION2}}
fi

echo "[EXEC] aws secretsmanager get-secret-value --secret-id ${RP2_DOMAIN} --region ${RP2_REGION}"
RP2_SECRET=$(aws secretsmanager get-secret-value --secret-id ${RP2_DOMAIN} --region ${RP2_REGION})

if [ -z "${RP2_SECRET##*error*}" ]; then
  echo "[EXEC] aws secretsmanager create-secret --name ${RP2_DOMAIN} --region ${RP2_REGION}"
  RP2_SECRET=$(aws secretsmanager create-secret --name ${RP2_DOMAIN} --region ${RP2_REGION})

  if [ ! -z "${RP2_SECRET##*error*}" ]; then
    echo "[EXEC] aws secretsmanager put-secret-value --secret-id ${RP2_DOMAIN} --secret-string '{}' --region ${RP2_REGION}"
    aws secretsmanager put-secret-value --secret-id ${RP2_DOMAIN} --secret-string '{}' --region ${RP2_REGION}
  fi
fi
