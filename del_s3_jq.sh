#!/bin/bash

# Ask for user input
read -p "Enter the bucket name you want to empty: " bucket_name

aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Suspended
# Pipe the output to a while loop to delete objects in batches
aws s3api list-object-versions --bucket "$bucket_name" --output=json | \
  jq -r '.Versions[] | {Key: .Key, VersionId: .VersionId} | @base64' | \
  while IFS= read -r line; do
    # Decode the line from base64
    decoded=$(echo "$line" | base64 --decode)
    # Delete object version
    aws s3api delete-object --bucket "wifi-counter-sensor-6oq20d9" --cli-input-json "$decoded"
  done
