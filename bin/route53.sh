#!/bin/bash

if [ ! -z "${1}" ]; then RP2_CHECK_URL="${1}";
elif [ -z "${RP2_CHECK_URL}" ]; then
  echo "[ERROR] RP2_CHECK_URL is missing..."; exit 1;
fi

if [ ! -z "${2}" ]; then RP2_API_URL="${2}";
elif [ -z "${RP2_API_URL}" ]; then
  echo "[ERROR] RP2_API_URL is missing..."; exit 1;
fi

sed "s/TO_BE_REPLACED/${RP2_CHECK_URL}/" route53.json > route53.tmp

ROUTE53=$(aws route53 create-health-check \
  --caller-reference $(date "+%Y%m%d%H%M%S") \
  --health-check-config file://route53.tmp)

rm route53.tmp
echo $ROUTE53

ROUTE53=$(echo $ROUTE53 | jq .HealthCheck.Id)
ROUTE53=${RESPONSE//\"/}

aws route53 change-tags-for-resource \
  --resource-type healthcheck \
  --resource-id ${ROUTE53} \
  --add-tags Key=Name,Value=${RP2_API_URL}
