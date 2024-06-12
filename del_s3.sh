#!/bin/bash

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
BUCKETS=$(aws s3 ls | awk '{print $3}')

# Loop through each bucket
for BUCKET in $BUCKETS; do
    echo "Processing bucket: $BUCKET"
    
    # Check if the bucket exists
    if aws s3 ls "s3://$BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
        echo "Bucket $BUCKET does not exist. Skipping."
        continue
    fi

    # Delete all objects in the bucket
    echo "Deleting all objects in bucket: $BUCKET"
    aws s3 rm "s3://$BUCKET" --recursive

    # Finally, delete the bucket
    echo "Deleting bucket: $BUCKET"
    aws s3 rb "s3://$BUCKET" --force
    echo "Bucket $BUCKET and its contents have been deleted."
done

echo "Script execution completed."
