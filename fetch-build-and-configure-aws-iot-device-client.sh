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

source ./conf

if [ ! -d $HOME/.aws-iot-device-client ]; then
  mkdir $HOME/.aws-iot-device-client
fi

if [ ! -d $HOME/.aws-iot-device-client/jobs/ ]; then
  mkdir $HOME/.aws-iot-device-client/jobs/
fi

cd $HOME

git clone https://github.com/awslabs/aws-iot-device-client
cd aws-iot-device-client

if [ ! -d ./build/ ]; then
  mkdir build
fi

if [ ! -d $HOME/.aws-iot-device-client/log/ ]; then
  mkdir $HOME/.aws-iot-device-client/log/
fi

cd build 
cmake ../
cmake --build . --target aws-iot-device-client --target test-aws-iot-device-client

cd $RUN_DIR

# Generate Device Client Configuration
cp $HOME/aws-iot-device-client/config-template.json ./config-template.json
jq --arg endpoint "$MQTT_ENDPOINT" \
  --arg thingName "$THING_NAME" \
  --arg cert "$DEVICE_CERT_PATH" \
  --arg key "$PRIVATE_KEY_PATH" \
  --arg rootCA "$ROOT_CERT_PATH" \
  --arg jobsHandlerDirectory "$HOME/.aws-iot-device-client/jobs/" \
  --arg logFile "$HOME/.aws-iot-device-client/log/aws-iot-device-client.log" \
  'del(."fleet-provisioning", .samples) | .logging.file = $logFile | .endpoint = $endpoint | ."thing-name" = $thingName | .cert = $cert | .key = $key | ."root-ca" = $rootCA | .jobs."handler-directory" = $jobsHandlerDirectory' \
  ./config-template.json > ./aws-iot-device-client.conf

rm ./config-template.json
mv ./aws-iot-device-client.conf $HOME/.aws-iot-device-client/aws-iot-device-client.conf

chmod 745 $HOME/.aws-iot-device-client/
chmod 644 $HOME/.aws-iot-device-client/aws-iot-device-client.conf

cp $HOME/aws-iot-device-client/sample-job-handlers/* $HOME/.aws-iot-device-client/jobs/
chmod -R 700 $HOME/.aws-iot-device-client/jobs/

cat $HOME/.aws-iot-device-client/aws-iot-device-client.conf
