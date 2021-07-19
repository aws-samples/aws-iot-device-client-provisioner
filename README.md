# aws-iot-device-client-provisioner

This repository is complimentary to the usage of the [AWS IoT Device Client](https://github.com/awslabs/aws-iot-device-client/). The Device Client's setup scripts assumes that you have already provisioned an AWS IoT Thing, including generating device certificates (or alternatively have configured Fleet Provisioning). This project provides some convenience scripts which generates all of those resources, including the Device Client configuration file which makes reference to those resources, in order to get up and running with the Device Client as quickly as possible.

# Provide AWS credentials to the device

Provide your AWS credentials to your device so that the installer can provision the required AWS resources. 


**To provide AWS credentials to the device**
+ On your device, provide AWS credentials by doing one of the following:
  + Use long\-term credentials from an IAM user:

    1. Provide the access key ID and secret access key for your IAM user. For more information about how to retrieve long\-term credentials, see [Managing access keys for IAM users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) in the *IAM User Guide*.

    1. Run the following commands to provide the credentials to the AWS CLI for use with the provisioning scripts.

       ```
       export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
       export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
       ```
  + \(Recommended\) Use temporary security credentials from an IAM role:

    1. Provide the access key ID, secret access key, and session token from an IAM role that you assume. For more information about how to retrieve these credentials, see [Using temporary security credentials with the AWS CLI](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html#using-temp-creds-sdk-cli) in the *IAM User Guide*.

    1. Run the following commands to provide the credentials to the AWS CLI for use with the provisioning scripts.

       ```
       export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
       export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
       export AWS_SESSION_TOKEN=AQoDYXdzEJr1K...o5OytwEXAMPLE=
       ```

## Download and install dependencies

The following dependencies are required both to build the Device Client and for use with the convenience scripts contained in this repository:
```bash
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install libssl-dev cmake git python3-pip python3-venv jq -y
```

Next install the AWS CLI
```bash
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
  unzip awscli-bundle.zip
  sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws  
```

Before proceeding, ensure the AWS CLI is working as expected: `aws --version` 

Please note that as of July 15, 2021, Python3 is required for installing the v1 AWS CLI. If you do not intend to run programs written in Python 2, it may be helpful to make Python 3 the default. The following resource might be helpful in accomplishing this configuration: https://linuxconfig.org/how-to-change-from-default-to-alternative-python-version-on-debian-linux


# Clone this repo to your device

```
  git clone https://github.com/aws-samples/aws-iot-device-client-provisioner
  cd aws-iot-device-client-provisioner
```

# Configure your Environment

The following environment variables are required to run the convenience scripts provided in this project. 
```
  export AWS_DEFAULT_REGION=us-east-1
  export THING_NAME=My-Unique-Thing-Name
  export THING_TYPE_NAME=My-Thing-Type
```

To provision your thing with AWS IoT Core provided X.509 certificates, the convenience scripts make use of the AWS CLI and requires the AWS Key pair obtained in the previous steps. These credentials will only be used one time to provision the necessary resources in your AWS account, and to generate the X.509 certificates that will be used by the device client. They can be discarded and the associated IAM user can be deleted after you have completed the subsequent steps.

```
  export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
  export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

# Provision Your AWS IoT Thing

Set the following environment variables, and then run the provided provisioning script. This script makes use of the AWS CLI to provision your AWS IoT Thing in the Device Registry, generate device certificates and thing policies, and attaches the thing to the certificate. The device certificates are saved in a directory that is created for you at `$HOME/aws-iot-device-client/certs`.

```
  ./provision-aws-iot-thing.sh
```

# Download, Build and Configure the AWS IoT Device Client

This script clones the AWS IoT Device Client Github repo, builds the repo using the provided cmake build scripts, and then configures the Device Client. The repo is cloned to `$HOME/aws-iot-device-client`, and all of the build artifacts are created within that directory.

```
  ./fetch-build-and-configure-aws-iot-device-client.sh
```

# Run the AWS IoT Device Client

This command runs the Device Client executable

```
  $HOME/aws-iot-device-client/build/aws-iot-device-client
```


# Troubleshooting

On OSX, you may need to remove any references to s2n from `CMakeLists.txt`.

You may also need to explicitly set `OPENSSL_ROOT_DIR` as an environment variable before you can build the device client.
For example:
`export OPENSSL_ROOT_DIR=/usr/local/opt/openssl`
