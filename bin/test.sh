#!/bin/bash

help()
{
  echo "Test API consumer flow for a specific AWS region"
  echo
  echo "Syntax: test.sh [-q|r|i|c|s]"
  echo "Options:"
  echo "q     Specify custom domain (e.g. example.com)"
  echo "r     Specify AWS region (e.g. us-east-1)"
  echo "i     Specify unique id (e.g. abcd1234)"
  echo "c     Specify Amazon Cognito client id"
  echo "s     Specify Amazon Cognito client secret"
  echo
}

set -o pipefail

RP2_DOMAIN=""
RP2_REGION=""
RP2_ID=""
RP2_AUTH_CLIENT_ID=""
RP2_AUTH_CLIENT_SECRET=""

while getopts "h:q:r:i:c:s:" option; do
  case $option in
    h)
      help
      exit;;
    q)
      RP2_DOMAIN=$OPTARG;;
    r)
      RP2_REGION=$OPTARG;;
    i)
      RP2_ID=$OPTARG;;
    c)
      RP2_AUTH_CLIENT_ID=$OPTARG;;
    s)
      RP2_AUTH_CLIENT_SECRET=$OPTARG;;
    \?)
      echo "[ERROR] invalid option"
      echo
      help
      exit;;
  esac
done

if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_DEFAULT_REGION}" ]; then RP2_REGION="${AWS_DEFAULT_REGION}"; fi
if [ -z "${RP2_REGION}" ] && [ ! -z "${AWS_REGION}" ]; then RP2_REGION="${AWS_REGION}"; fi

if [ -z "${RP2_DOMAIN}" ]; then
  echo "[DEBUG] RP2_DOMAIN: ${RP2_DOMAIN}"
  echo "[ERROR] RP2_DOMAIN is missing..."; exit 1;
fi

if [ -z "${RP2_REGION}" ]; then
  RP2_REGION=$(curl https://api.${RP2_DOMAIN}/ --http1.1 \
    --location --request GET --header "X-S3-Skip: 1" --header "X-SNS-Skip: 1" --header "X-SQS-Skip: 1")

  if [ -z "${RP2_REGION}" ] || [ -z "${RP2_REGION##*error*}" ]; then
    echo "[DEBUG] RP2_REGION: ${RP2_REGION}"
    echo "[ERROR] RP2_REGION request failed..."; exit 1;
  fi

  RP2_REGION=$(echo ${RP2_REGION} | jq .region_id)
  RP2_REGION=${RP2_REGION//\"/}
  echo "[DEBUG] RP2_REGION: ${RP2_REGION}"
fi

if [ -z "${RP2_AUTH_CLIENT_ID}" ] || [ -z "${RP2_AUTH_CLIENT_SECRET}" ]; then
  if [ -z "${RP2_ID}" ]; then
    echo "[DEBUG] RP2_ID: ${RP2_ID}"
    echo "[ERROR] RP2_ID is missing..."; exit 1;
  fi

  RP2_RESULT=$(aws secretsmanager get-secret-value --secret-id rp2-client-api-${RP2_REGION}-${RP2_ID})

  if [ -z "${RP2_RESULT}" ] || [ -z "${RP2_RESULT##*error*}" ]; then
    echo "[DEBUG] RP2_RESULT: ${RP2_RESULT}"
    echo "[ERROR] RP2_RESULT request failed..."; exit 1;
  fi

  RP2_SECRET=$(echo ${RP2_RESULT} | jq -r .SecretString)
  RP2_AUTH_CLIENT_ID=$(echo ${RP2_SECRET} | jq -r .RP2_AUTH_CLIENT_ID)
  RP2_AUTH_CLIENT_ID=${RP2_AUTH_CLIENT_ID//\"/}
  RP2_AUTH_CLIENT_SECRET=$(echo ${RP2_SECRET} | jq -r .RP2_AUTH_CLIENT_SECRET)
  RP2_AUTH_CLIENT_SECRET=${RP2_AUTH_CLIENT_SECRET//\"/}
fi

if [ -z "${RP2_AUTH_CLIENT_ID}" ] || [ -z "${RP2_AUTH_CLIENT_ID##*error*}" ]; then
  echo "[DEBUG] RP2_AUTH_CLIENT_ID: ${RP2_AUTH_CLIENT_ID}"
  echo "[ERROR] RP2_AUTH_CLIENT_ID is missing..."; exit 1;
fi

if [ -z "${RP2_AUTH_CLIENT_SECRET}" ] || [ -z "${RP2_AUTH_CLIENT_SECRET##*error*}" ]; then
  echo "[DEBUG] RP2_AUTH_CLIENT_SECRET: ${RP2_AUTH_CLIENT_SECRET}"
  echo "[ERROR] RP2_AUTH_CLIENT_SECRET is missing..."; exit 1;
fi

RP2_API_URL="https://api-${RP2_REGION}.${RP2_DOMAIN}"
echo "[INFO] RP2_API_URL: ${RP2_API_URL}"
RP2_AUTH_URL="https://auth-${RP2_REGION}.${RP2_DOMAIN}"
echo "[INFO] RP2_AUTH_URL: ${RP2_AUTH_URL}"
RP2_AUTH_CLIENT_SCOPE="rp2/read rp2/write"
RP2_AUTH_CLIENT_BASE64=$(echo -n "${RP2_AUTH_CLIENT_ID}:${RP2_AUTH_CLIENT_SECRET}" | base64)

RP2_TOKEN=$(curl ${RP2_AUTH_URL}/oauth2/token \
  --location --request POST \
  --header "Authorization: Basic ${RP2_AUTH_CLIENT_BASE64}" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${RP2_AUTH_CLIENT_ID}" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "scope=${RP2_AUTH_CLIENT_SCOPE}")

if [ -z "${RP2_TOKEN}" ] || [ -z "${RP2_TOKEN##*error*}" ]; then
  echo "[DEBUG] RP2_TOKEN: ${RP2_TOKEN}"
  echo "[ERROR] RP2_TOKEN request failed..."; exit 1;
fi

RP2_TOKEN=$(echo ${RP2_TOKEN} | jq .access_token)
RP2_TOKEN=${RP2_TOKEN//\"/}
# echo "[DEBUG] RP2_TOKEN: ${RP2_TOKEN}"

RP2_UUID=$(curl ${RP2_API_URL}/uuid \
  --http1.1 --location --request GET \
  --header "Authorization: Bearer ${RP2_TOKEN}" \
  --header "Content-Type: application/json")

if [ -z "${RP2_UUID}" ] || [ -z "${RP2_UUID##*error*}" ]; then
  echo "[DEBUG] RP2_UUID: ${RP2_UUID}"
  echo "[ERROR] RP2_UUID request failed..."; exit 1;
fi

RP2_UUID=$(echo ${RP2_UUID} | jq .transaction_id)
RP2_UUID=${RP2_UUID//\"/}
echo "[INFO] RP2_UUID: ${RP2_UUID}"

WORKDIR="$( cd "$(dirname "$0")/../" > /dev/null 2>&1 || exit 1; pwd -P )"
RP2_INBOX=$(curl ${RP2_API_URL}/inbox \
  --http1.1 --location --request POST \
  --header "Authorization: Bearer ${RP2_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "X-Transaction-Id: ${RP2_UUID}" \
  --header "X-Message-Type: pacs.008" \
  --data "@${WORKDIR}/data/pacs.008.xml")
echo "[INFO] RP2_INBOX: ${RP2_INBOX}"

if [ -z "${RP2_INBOX}" ] || [ -z "${RP2_INBOX##*error*}" ]; then
  echo "[DEBUG] RP2_INBOX: ${RP2_INBOX}"
  echo "[ERROR] RP2_INBOX request failed..."; exit 1;
fi

sleep 10

echo -n "[INFO] RP2_OUTBOX: "
curl ${RP2_API_URL}/outbox \
  --http1.1 --location --request POST \
  --header "Authorization: Bearer ${RP2_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "X-Transaction-Id: ${RP2_UUID}"
echo ""
