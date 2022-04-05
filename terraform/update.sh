#!/usr/bin/env bash

aws lambda update-function-code --function-name $(terraform output -raw openapi_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
aws lambda update-function-code --function-name $(terraform output -raw authorizer_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
aws lambda update-function-code --function-name $(terraform output -raw backendinterfaces_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
aws lambda update-function-code --function-name $(terraform output -raw provisioning_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
aws lambda update-function-code --function-name $(terraform output -raw claiming_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
aws lambda update-function-code --function-name $(terraform output -raw clients_function) \
  --s3-bucket $(terraform output -raw source_s3_bucket) \
  --s3-key $(terraform output -raw source_s3_code_key) \
  --region $(terraform output -raw region)
