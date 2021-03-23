#! /bin/bash

RUN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$THING_NAME" ]; then
  echo "Environment variable THING_NAME is required"
  exit 0
fi

if [ -z "$THING_TYPE_NAME" ]; then
  echo "Environment variable THING_TYPE_NAME is required"
  exit 0
fi

ACCOUNT_ID=$(aws --output text sts get-caller-identity --query 'Account')
MQTT_ENDPOINT=$(aws --output text iot describe-endpoint --endpoint-type iot:Data-ATS --query 'endpointAddress')

CERTS_DIR=$HOME/aws-iot-device-client/certs
ROOT_CERT_PATH=${CERTS_DIR}/AmazonRootCA1.pem
DEVICE_CERT_PATH=${CERTS_DIR}/${THING_NAME}_thing.cert.pem
PUBLIC_KEY_PATH=${CERTS_DIR}/${THING_NAME}_thing.public.key
PRIVATE_KEY_PATH=${CERTS_DIR}/${THING_NAME}_thing.private.key

if ! aws --output text iot list-thing-types --query 'thingTypes[].thingTypeName' | grep -q "${THING_TYPE_NAME}"; then
  echo "Thing Type with name \"${THING_TYPE_NAME}\" does not exist. Creating AWS resources"
  aws iot create-thing-type --thing-type-name "${THING_TYPE_NAME}"
fi

if ! aws iot describe-thing --thing-name "${THING_NAME}" > /dev/null 2>&1; then
  echo "Thing with name \"${THING_NAME}\" does not exist. Creating AWS resources"

  echo "Creating Thing in IoT Thing Registry"
  aws --output text iot create-thing \
    --thing-name "${THING_NAME}" \
    --thing-type-name ${THING_TYPE_NAME} \
    --query 'thingArn'
else
  echo "Thing with name \"${THING_NAME}\" already exists - skipping resource creation"
fi

if [ ! -f $CERTS_DIR ]; then
  mkdir -p $CERTS_DIR
fi

# Check to see if root CA file exists, download if not
if [ ! -f $ROOT_CERT_PATH ]; then
  printf "\nDownloading AWS IoT Root CA certificate from AWS...\n"
  curl https://www.amazontrust.com/repository/AmazonRootCA1.pem > $ROOT_CERT_PATH
fi

if [ ! -f $DEVICE_CERT_PATH ]; then
  echo "Creating Keys and Certificate"
  CERTIFICATE_ARN=$(aws --output text iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile "$DEVICE_CERT_PATH" \
    --public-key-outfile "$PUBLIC_KEY_PATH" \
    --private-key-outfile "$PRIVATE_KEY_PATH" \
    --query 'certificateArn')

  THING_POLICY_OUTPUT="{
      \"Version\": \"2012-10-17\",
      \"Statement\": [
        {
          \"Effect\": \"Allow\",
          \"Action\": [
            \"iot:Publish\",
            \"iot:Receive\"
          ],
          \"Resource\": [\"arn:aws:iot:$AWS_REGION:$ACCOUNT_ID:topic/*\"]
        },
        {
          \"Effect\": \"Allow\",
          \"Action\": [\"iot:Subscribe\"],
          \"Resource\": [\"arn:aws:iot:$AWS_REGION:$ACCOUNT_ID:topicfilter/*\"]
        },
        {
          \"Effect\": \"Allow\",
          \"Action\": [\"iot:Connect\"],
          \"Resource\":[ \"*\" ],
            \"Condition\": {
                \"Bool\": {
                    \"iot:Connection.Thing.IsAttached\": [\"true\"]
                }
            }
        }
      ]
    }"

  echo "Generating Thing Policy document"
  echo "$THING_POLICY_OUTPUT" | tee "${RUN_DIR}"/thing-policy.json >/dev/null

  echo "Creating Thing Policy"
  aws iot create-policy \
    --policy-name "${THING_NAME}-Policy" \
    --policy-document file://"${RUN_DIR}"/thing-policy.json

  echo "Attaching Thing Policy to Thing Certificate"
  aws iot attach-policy \
    --policy-name "${THING_NAME}-Policy" \
    --target "${CERTIFICATE_ARN}"

  echo "Attaching Thing Principal (Certificate)"
  aws iot attach-thing-principal \
    --thing-name "${THING_NAME}" \
    --principal "${CERTIFICATE_ARN}"
fi
