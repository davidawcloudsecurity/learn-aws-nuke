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

delete_version_in_bucket () {
bucket_name=$1

# Get list of object versions
#object_versions=$(aws s3api list-object-versions --bucket "$bucket_name" --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')
object_versions=$(aws s3api list-object-versions --bucket "$bucket_name" | grep VersionId)

# Check if object_versions is not empty
if [ -z "$object_versions" ]; then
    echo "No object versions found in bucket $bucket_name."
    exit 0
fi

# Loop through each object version and delete it
echo "$object_versions" | while read -r key versionId; do
    echo "Deleting object version: $key (VersionId: $versionId)"
    aws s3api delete-object --bucket "$bucket_name" --key "$key" --version-id "$versionId"
done

aws s3 rb s3://$bucket_name --force
}

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and delete its objects
for bucket in $buckets; do
    aws s3 rb s3://$bucket --force
    aws s3api delete-bucket --bucket $bucket --region ap-southeast-1
    delete_objects_in_bucket $bucket
    delete_version_in_bucket $bucket
done

echo "All S3 buckets and their objects have been deleted."
