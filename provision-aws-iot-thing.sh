#! /bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

source ./conf

if [ -z "$AWS_DEFAULT_REGION" ]; then
  echo "AWS_DEFAULT_REGION is required"
  exit 0
fi

if [ -z "$THING_TYPE_NAME" ]; then
  echo "THING_TYPE_NAME is required"
  exit 0
fi

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

if [ ! -d $CERTS_DIR ]; then
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
          \"Resource\": [\"arn:aws:iot:$AWS_DEFAULT_REGION:$ACCOUNT_ID:topic/*\"]
        },
        {
          \"Effect\": \"Allow\",
          \"Action\": [\"iot:Subscribe\"],
          \"Resource\": [\"arn:aws:iot:$AWS_DEFAULT_REGION:$ACCOUNT_ID:topicfilter/*\"]
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
    --policy-name "$THING_POLICY_NAME" \
    --policy-document file://"${RUN_DIR}"/thing-policy.json

  echo "Attaching Thing Policy to Thing Certificate"
  aws iot attach-policy \
    --policy-name "$THING_POLICY_NAME" \
    --target "${CERTIFICATE_ARN}"

  echo "Attaching Thing Principal (Certificate)"
  aws iot attach-thing-principal \
    --thing-name "${THING_NAME}" \
    --principal "${CERTIFICATE_ARN}"
fi

chmod 700 $CERTS_DIR
chmod 644 $DEVICE_CERT_PATH
chmod 644 $ROOT_CERT_PATH
