#!/bin/bash

# Define the backup vault name and region
backup_vault_name="high-utku6v0"
region="ap-southeast-1"

# List recovery points and extract ARNs
recovery_points=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name "$backup_vault_name" --region "$region" | grep "RecoveryPointArn" | awk -F'"' '{print $4}')

# Iterate over each recovery point ARN and delete it
for recovery_point_arn in $recovery_points; do
    echo "Deleting recovery point: $recovery_point_arn"
    aws backup delete-recovery-point \
        --backup-vault-name "$backup_vault_name" \
        --recovery-point-arn "$recovery_point_arn" \
        --region "$region"
done

echo "All specified recovery points have been deleted."
