#!/bin/bash

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and delete it
for bucket in $buckets; do
    echo "Processing bucket: $bucket"
    aws s3 rb s3://$bucket --force
done

echo "All S3 buckets have been deleted."
