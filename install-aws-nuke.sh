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

# Create the YAML configuration file
cat <<EOL > config.yml
regions:
- eu-west-1

account-blocklist:
- "999999999999" # production

accounts:
  "000000000000": # aws-nuke-example
    filters:
      IAMUser:
      - "my-user"
      IAMUserPolicyAttachment:
      - "my-user -> AdministratorAccess"
EOL

echo "aws-nuke has been installed successfully."
echo "Configuration file config.yml has been created."
echo "vi or nano config.yml to filter user not to be deleted."
echo "Run the following commands to execute aws-nuke"
echo "aws-nuke -c config.yml --no-dry-run"
