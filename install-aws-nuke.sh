#!/bin/bash

# Prompt the user for the URL
read -p "Enter the URL for the aws-nuke tarball: " url

# Check if the URL is not empty
if [ -z "$url" ]; then
  echo "URL cannot be empty. Exiting."
  exit 1
fi

# Download the aws-nuke tarball
wget -c "$url" -O aws-nuke.tar.gz

# Extract the aws-nuke binary
tar -xvf aws-nuke.tar.gz

# Find the extracted binary (assuming it's the only file in the tarball)
binary_name=$(tar -tf aws-nuke.tar.gz | head -n 1)

# Rename the extracted binary to aws-nuke
mv "$binary_name" aws-nuke

# Copy the extracted binary to your $PATH
sudo mv aws-nuke /usr/local/bin/aws-nuke

# Clean up
rm aws-nuke.tar.gz

# Retrieve the current AWS account ID using AWS CLI
account_id=$(aws sts get-caller-identity --query Account --output text)

# Retrieve the current AWS region
current_region=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

# Prompt the user for the IAM user name
read -p "Enter the IAM user name to exclude from deletion: " iam_user_name

# Create the YAML configuration file with the retrieved account ID and region
cat <<EOL > config.yml
regions:
- $current_region

account-blocklist:
- "999999999999" # production

accounts:
  "$account_id": # aws-nuke-example
    filters:
      IAMUser:
      - "$iam_user_name"
      IAMUserPolicyAttachment:
      - "$iam_user_name -> AdministratorAccess"
EOL

echo "aws-nuke has been installed successfully."
echo "Configuration file config.yml has been created."
echo "vi or nano config.yml to filter user not to be deleted."
echo "Run the following commands to execute aws-nuke"
echo "aws-nuke -c config.yml --no-dry-run"
