#!/bin/bash

# Pipe the output to a while loop to delete objects in batches
aws s3api list-object-versions --bucket "wifi-counter-sensor-6oq20d9" --output=json | \
  jq -r '.Versions[] | {Key: .Key, VersionId: .VersionId} | @base64' | \
  while IFS= read -r line; do
    # Decode the line from base64
    decoded=$(echo "$line" | base64 --decode)
    # Delete object version
    aws s3api delete-object --bucket "wifi-counter-sensor-6oq20d9" --cli-input-json "$decoded"
  done
