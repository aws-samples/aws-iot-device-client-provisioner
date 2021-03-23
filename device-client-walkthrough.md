Freshly minted Raspberry Pi v4 with Raspberry Pi OS Lite (32-bit)

# Provide AWS credentials to the device

`Instructions copied from https://raw.githubusercontent.com/awsdocs/aws-iot-greengrass-v2-developer-guide/main/doc_source/quick-installation.md`

Provide your AWS credentials to your device so that the installer can provision the required AWS resources. For more information about the required permissions, see [Minimal IAM policy for installer to provision resources](provision-minimal-iam-policy.md).


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

The following dependencies are required for use with the convenience scripts provided in this repository.

```bash
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install libssl-dev cmake git python-pip jq

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
```

# Clone this repo to your device

git clone TODO-github-repo-url

# Provision Your AWS IoT Thing

Set the following environment variables, and then run the provided provisioning script. This script makes use of the AWS CLI to provision your AWS IoT Thing in the Device Registry, generate device certificates and thing policies, and attaches the thing to the certificate. The device certificates are saved under `$HOME/aws-iot-device-client/certs`.

```
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

export THING_NAME=My_Unique_Thing_Name
export THING_TYPE_NAME=My_Thing_Name

./provision-aws-iot-thing.sh
```

# Download, Build and Configure the AWS IoT Device Client

This script clones the AWS IoT Device Client Github repo, builds the repo using the provided cmake build scripts, and then configures the Device Client. The repo is cloned to `$HOME/aws-iot-device-client`, and all of the build artifacts are created within that directory.

```
  ./fetch-build-and-configure-aws-iot-device-client.sh
```

# Run the AWS IoT Device Client. This command runs the executable

```
  $HOME/aws-iot-device-client/aws-iot-device-client
```
