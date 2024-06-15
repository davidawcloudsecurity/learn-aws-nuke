#!/bin/bash

# Function to list all IoT certificates and extract their IDs, ARNs, and status
list_certificates() {
    aws iot list-certificates | jq -r '.certificates[] | "\(.certificateId) \(.certificateArn) \(.status)"'
}

# Function to describe IoT certificate
describe_iot_certificate() {
    local cert_id=$1
    aws iot describe-certificate --certificate-id "$cert_id"
}

# Function to list policies attached to IoT certificate
list_iot_policies() {
    local cert_arn=$1
    aws iot list-principal-policies --principal "$cert_arn"
}

# Function to detach policies from IoT certificate
detach_iot_policies() {
    local cert_arn=$1
    policies=$(list_iot_policies "$cert_arn" | jq -r '.policies[].policyName')
    for policy in $policies; do
        echo "Detaching policy $policy from certificate $cert_arn"
        aws iot detach-policy --policy-name "$policy" --target "$cert_arn"
    done
}

# Function to delete IoT certificate
delete_iot_certificate() {
    local cert_id=$1
    echo "Deleting IoT certificate $cert_id"
    aws iot delete-certificate --certificate-id "$cert_id" --force
}

# Main script
echo "Listing all IoT certificates:"
certificates=$(list_certificates)

IFS=$'\n'
for cert in $certificates; do
    cert_id=$(echo "$cert" | awk '{print $1}')
    cert_arn=$(echo "$cert" | awk '{print $2}')
    cert_status=$(echo "$cert" | awk '{print $3}')

    echo "Processing certificate ID: $cert_id, ARN: $cert_arn, Status: $cert_status"

    if [ "$cert_status" == "ACTIVE" ]; then
        echo "Deactivating certificate $cert_id"
        aws iot update-certificate --certificate-id "$cert_id" --new-status INACTIVE
    fi

    # Detach policies
    detach_iot_policies "$cert_arn"

    # Delete the certificate
    delete_iot_certificate "$cert_id"
done

echo "All IoT certificates have been processed and deleted."
