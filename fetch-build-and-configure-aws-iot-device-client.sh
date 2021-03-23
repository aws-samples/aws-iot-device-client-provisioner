#! /bin/bash

set -x

source ./conf

if [ ! -d $JOBS_HANDLER_DIRECTORY ]; then
  mkdir -p $JOBS_HANDLER_DIRECTORY
fi

if [ ! -d /var/log/aws-iot-device-client/ ]; then
  sudo mkdir /var/log/aws-iot-device-client/
  sudo chmod 745 /var/log/aws-iot-device-client/
fi

cd $HOME

git clone https://github.com/awslabs/aws-iot-device-client
cd aws-iot-device-client

mkdir build && cd build && cmake ../
cmake --build . --target aws-iot-device-client

cd $RUN_DIR

# Generate Device Client Configuration
cp $HOME/aws-iot-device-client/config-template.json ./config-template.json
jq --arg endpoint "$MQTT_ENDPOINT" \
  --arg thingName "$THING_NAME" \
  --arg cert "$DEVICE_CERT_PATH" \
  --arg key "$PRIVATE_KEY_PATH" \
  --arg rootCA "$ROOT_CERT_PATH" \
  --arg jobsHandlerDirectory "$JOBS_HANDLER_DIRECTORY" \
  '.endpoint = $endpoint | ."thing-name" = $thingName | .cert = $cert | .key = $key | ."root-ca" = $rootCA | .jobs."handler-directory" = $jobsHandlerDirectory' \
  ./config-template.json > ./aws-iot-device-client.conf

rm ./config-template.json
mkdir $HOME/.aws-iot-device-client
mv ./aws-iot-device-client.conf $HOME/.aws-iot-device-client/aws-iot-device-client.conf
chmod 745 $HOME/.aws-iot-device-client/
chmod 644 $HOME/.aws-iot-device-client/aws-iot-device-client.conf

cat $HOME/.aws-iot-device-client/aws-iot-device-client.conf
