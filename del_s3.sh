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

    # Delete all versions and delete markers in the bucket
    versions=$(aws s3api list-object-versions --bucket "$BUCKET" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json)
    delete_markers=$(aws s3api list-object-versions --bucket "$BUCKET" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json)

    echo "$versions" | jq -c '.[]' | while read -r version; do
        key=$(echo "$version" | jq -r '.Key')
        versionId=$(echo "$version" | jq -r '.VersionId')
        echo "Deleting object $key version $versionId from bucket $BUCKET"
        aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$versionId"
    done

    echo "$delete_markers" | jq -c '.[]' | while read -r marker; do
        key=$(echo "$marker" | jq -r '.Key')
        versionId=$(echo "$marker" | jq -r '.VersionId')
        echo "Deleting delete marker $key version $versionId from bucket $BUCKET"
        aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$versionId"
    done

    # Delete all objects in the bucket (to handle any remaining non-versioned objects)
    echo "Deleting all objects in bucket: $BUCKET"
    aws s3 rm "s3://$BUCKET" --recursive

    # Finally, delete the bucket
    echo "Deleting bucket: $BUCKET"
    aws s3 rb "s3://$BUCKET" --force
    echo "Bucket $BUCKET and its contents have been deleted."
done

echo "Script execution completed."
