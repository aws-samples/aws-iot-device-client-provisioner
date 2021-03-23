#! /bin/bash

set -x


if [ -z "$THING_TYPE_NAME" ]; then
  echo "THING_TYPE_NAME is required"
  exit 0
fi

source ./conf

rm -rf $HOME/aws-iot-device-client/
rm -rf $CERTS_DIR
rm -rf $JOBS_HANDLER_DIRECTORY

CERTIFICATE_ARN=$(aws iot list-thing-principals --thing-name $THING_NAME --output text --query 'principals[0]')
CERTIFICATE_ID="${CERTIFICATE_ARN##*/}"

aws iot detach-policy \
  --target "$CERTIFICATE_ARN" \
  --policy-name "$THING_POLICY_NAME"

# Assume that we will not delete the policy for now
# aws iot delete-policy \
#   --policy-name "$THING_POLICY_NAME"

aws iot update-certificate \
  --certificate-id $CERTIFICATE_ID \
  --new-status INACTIVE

aws iot detach-thing-principal \
  --thing-name "$THING_NAME" \
  --principal "$CERTIFICATE_ARN"

aws iot delete-certificate --certificate-id $CERTIFICATE_ID

aws iot delete-thing --thing-name $THING_NAME

# deleting thing type requires ~5 minutes after deprecating the thing type to succeed
# aws iot deprecate-thing-type --thing-type-name $THING_TYPE_NAME
# aws iot delete-thing-type --thing-type-name $THING_TYPE_NAME
