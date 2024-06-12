# learn-aws-nuke
How to destroy aws resources or services or exclude specific ones

Resource - https://medium.com/aws-security-user-group-west-africa/aws-tools-aws-nuke-to-clean-up-an-account-4b9077103780

https://github.com/rebuy-de/aws-nuke

Get updated releases - https://github.com/search?q=+https%3A%2F%2Fgithub.com%2Frebuy-de%2Faws-nuke%2Freleases%2Fdownload&type=pullrequests

https://medium.com/airwalk/aws-nuke-without-destroying-sso-f73d9cce85fd
```ruby
## Download aws-nuke
wget -c https://github.com/rebuy-de/aws-nuke/releases/download/v2.16.0/aws-nuke-v2.16.0-linux-amd64.tar.gz
## Extract the aws-nuke binary
tar -xvf aws-nuke-v2.16.0-linux-amd64.tar.gz
## Rename the extracted binary to aws-nuke
mv aws-nuke-v2.16.0-linux-amd64 aws-nuke
## Copy the extracted binary to your $PATH
sudo mv aws-nuke /usr/local/bin/aws-nuke
## Validate
aws-nuke -h
```
sample-config.yml
```ruby
regions:
- eu-west-1
- us-east-1
- global

account-blocklist:
- "999999999999" # production

accounts:
  "<ACCOUNT_ID>": {} # aws-nuke-example
```
```ruby
## View resources to be deleted
aws-nuke -c nuke-config.yml --profile aws_nuke
## Delete resources
aws-nuke -c nuke-config.yml --profile aws_nuke --no-dry-run
```
