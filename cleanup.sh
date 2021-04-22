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
