#!/usr/bin/env bash
# To list all backup vaults:
# python3 manage_backup_vaults.py --list
# To delete a specific backup vault:
# python3 manage_backup_vaults.py your-backup-vault-name

cat <<'EOF' > /tmp/manage_backup_vaults.py
import boto3
from botocore.exceptions import ClientError

def list_backup_vaults():
    """List all backup vaults."""
    client = boto3.client('backup')
    
    try:
        response = client.list_backup_vaults()
        vaults = response['BackupVaultList']
        
        if not vaults:
            print("No backup vaults found.")
        else:
            for vault in vaults:
                print(vault['BackupVaultName'])
    except ClientError as e:
        print(f'Error listing backup vaults: {e}')

def stop_backup_jobs():
    """Stop all ongoing backup jobs."""
    client = boto3.client('backup')
    
    try:
        response = client.list_backup_jobs(ByState='RUNNING')
        backup_jobs = response['BackupJobs']
        
        for job in backup_jobs:
            job_id = job['BackupJobId']
            try:
                client.stop_backup_job(BackupJobId=job_id)
                print(f'Stopped backup job: {job_id}')
            except ClientError as e:
                print(f'Error stopping backup job {job_id}: {e}')
    except ClientError as e:
        print(f'Error listing backup jobs: {e}')

def delete_recovery_points(vault_name):
    """Delete all recovery points in the specified vault."""
    client = boto3.client('backup')
    
    try:
        paginator = client.get_paginator('list_recovery_points_by_backup_vault')
        response_iterator = paginator.paginate(BackupVaultName=vault_name)
        
        for response in response_iterator:
            recovery_points = response['RecoveryPoints']
            
            for recovery_point in recovery_points:
                recovery_point_arn = recovery_point['RecoveryPointArn']
                try:
                    client.delete_recovery_point(BackupVaultName=vault_name, RecoveryPointArn=recovery_point_arn)
                    print(f'Deleted recovery point: {recovery_point_arn}')
                except ClientError as e:
                    print(f'Error deleting recovery point {recovery_point_arn}: {e}')
    except ClientError as e:
        print(f'Error listing recovery points: {e}')

def delete_backup_vault(vault_name):
    """Delete the specified backup vault."""
    client = boto3.client('backup')
    
    try:
        client.delete_backup_vault(BackupVaultName=vault_name)
        print(f'Deleted backup vault: {vault_name}')
    except ClientError as e:
        print(f'Error deleting backup vault {vault_name}: {e}')

def main(vault_name=None):
    """Main function to stop jobs and delete everything in the vault."""
    if vault_name:
        stop_backup_jobs()
        delete_recovery_points(vault_name)
        delete_backup_vault(vault_name)
    else:
        list_backup_vaults()

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='List or delete AWS Backup vaults and their contents.')
    parser.add_argument('-l', '--list', action='store_true', help='List all backup vaults.')
    parser.add_argument('vault_name', nargs='?', help='The name of the backup vault to delete.')
    
    args = parser.parse_args()
    
    if args.list:
        list_backup_vaults()
    elif args.vault_name:
        main(args.vault_name)
    else:
        parser.print_help()
EOF

# Capture the output of the vault listing
vaults=$(python3 /tmp/manage_backup_vaults.py --list)

# Ensure the vaults variable is a list
IFS=$'\n' read -rd '' -a vault_list <<<"$vaults"

# Loop through each vault and delete it using the embedded Python script
for vault in "${vault_list[@]}"; do
  echo "Removing $vault"
  python3 /tmp/manage_backup_vaults.py "$vault"
done

# Clean up the temporary Python script
rm /tmp/manage_backup_vaults.py
