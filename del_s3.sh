#!/bin/bash

# Function to list objects in an S3 bucket and delete them
delete_objects_in_bucket() {
    bucket_name=$1
    echo "Processing bucket: $bucket_name"

    # List objects in the bucket
    objects=$(aws s3 ls "s3://$bucket_name" --recursive | awk '{print $4}')

    # Loop through each object and delete it
    for object in $objects; do
        echo "Deleting object: $object"
        aws s3 rm "s3://$bucket_name/$object" --recursive
    done

    echo "All objects in bucket $bucket_name have been deleted."
}

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and delete its objects
for bucket in $buckets; do
    delete_objects_in_bucket $bucket
done

echo "All S3 buckets and their objects have been deleted."
