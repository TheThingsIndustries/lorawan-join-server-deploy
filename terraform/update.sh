#!/usr/bin/env bash

set -e

source_s3_bucket=$(terraform output -raw source_s3_bucket)
source_s3_code_key=$(terraform output -raw source_s3_code_key)
region=$(terraform output -raw region)

for fn in openapi authorizer backendinterfaces provisioning claiming; do \
  echo "Updating $fn"
  aws lambda update-function-code \
    --function-name $(terraform output -raw ${fn}_function) \
    --s3-bucket ${source_s3_bucket} \
    --s3-key ${source_s3_code_key} \
    --region ${region} > /dev/null
done
