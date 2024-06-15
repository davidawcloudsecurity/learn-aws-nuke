#!/bin/bash

# Function to empty all objects in an S3 bucket
empty_s3_bucket() {
    bucket_name=$1
    echo "Emptying bucket: $bucket_name"
    
    # List and delete all object versions (to handle versioned buckets)
    aws s3api list-object-versions --bucket $bucket_name  --query DeleteMarkers[*].Key --output text
    object_keys=$(aws s3api list-object-versions --bucket $bucket_name  --query DeleteMarkers[*].Key --output text)
    version_ids=$(aws s3api list-object-versions --bucket $bucket_name  --query DeleteMarkers[*].VersionId --output text)
    for (( i=0; i<${#object_keys[@]}; i++ )); do
      object_key="${object_keys[$i]}"
      version_id="${version_ids[$i]}"
      echo "Deleting object with key: $object_key and version ID: $version_id"
      aws s3api delete-object --bucket "$bucket_name" --key "$object_key" --version-id "$version_id"
    done

    # List and delete all delete markers (to handle versioned buckets)
    delete_markers=$(aws s3api list-object-versions --bucket "$bucket_name" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)
    if [[ "$delete_markers" != "{}" ]]; then
        echo "Deleting delete markers in bucket: $bucket_name"
        aws s3api delete-objects --bucket "$bucket_name" --delete "$delete_markers"
    fi

    # List and delete all objects (for non-versioned buckets)
    objects=$(aws s3api list-objects --bucket "$bucket_name" --query '{Objects: Contents[].{Key:Key}}' --output json)
    if [[ "$objects" != "{}" ]]; then
        echo "Deleting objects in bucket: $bucket_name"
        aws s3api delete-objects --bucket "$bucket_name" --delete "$objects"
    fi

    echo "Bucket $bucket_name is now empty."
}

# Get the list of all S3 buckets
echo "Fetching list of S3 buckets..."
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and empty it
for bucket in $buckets; do
    echo "Processing bucket: $bucket"
    aws s3 rb s3://$bucket --force
    empty_s3_bucket $bucket
    aws s3 rb s3://$bucket --force
done

echo "All S3 buckets have been emptied."
