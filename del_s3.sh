#!/bin/bash

# Function to empty all objects in an S3 bucket
empty_s3_bucket() {
    bucket_name=$1
    echo "Emptying bucket: $bucket_name"
    
    # Get delete markers and versions
    Keys=$(aws s3api list-object-versions --bucket "$bucket_name" --query DeleteMarkers[*].Key --output json)
    versions=$(aws s3api list-object-versions --bucket "$bucket_name" --query DeleteMarkers[*].VersionId --output json)

    count=$(echo "$Keys" | jq length)
    for ((i=0;i < count;i++)); do
        key=$(echo "$Keys" | jq -r ".[$i]")
        version_id=$(echo "$versions" | jq -r ".[$i]")
        echo "Deleting object with key: $key and version ID: $version_id"
        aws s3api delete-object --bucket "$bucket_name" --key "$key" --version-id "$version_id"
    done
    echo "Bucket $bucket_name is now empty."
}

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and empty it
for bucket in $buckets; do
    echo "Processing bucket: $bucket"
    aws s3 rb s3://$bucket --force
    aws s3 rm s3://$bucket --recursive
    empty_s3_bucket $bucket
    aws s3 rb s3://$bucket --force
done

echo "All S3 buckets have been emptied."
