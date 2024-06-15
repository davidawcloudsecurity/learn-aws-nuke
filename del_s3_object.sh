#!/bin/bash

bucket_name="wrong-account-id-r3z6t-deploy-tfstate-k9dlg"

# Get delete markers and versions
delete_markers=$(aws s3api list-object-versions --bucket "$bucket_name" --query DeleteMarkers[*].Key --output json)
versions=$(aws s3api list-object-versions --bucket "$bucket_name" --query DeleteMarkers[*].VersionId --output json)

# Function to delete objects
delete_objects() {
    local keys="$1"
    local version_ids="$2"
    local bucket_name="$3"  # Replace with your actual bucket name

#    count=$(echo "$keys" | jq length)
    for ((i=0;i < 2;i++)); do
        key=$(echo "$keys" | jq -r ".[$i]")
        version_id=$(echo "$version_ids" | jq -r ".[$i]")
        echo "Deleting object with key: $key and version ID: $version_id"
        aws s3api delete-object --bucket "$bucket_name" --key "$key" --version-id "$version_id"
    done
}

# Delete delete markers
delete_objects "$delete_markers" "$versions" "$bucket_name"

echo "All delete markers and versions deleted from bucket $bucket_name."
