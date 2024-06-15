#!/usr/bin/env bash

# Inspiration from Lyle Scott, III  // lyle@ls3.io
# https://gist.github.com/LyleScott/ab20b5969a441b2ebe8a28602b5deaee
# Temporary Python script embedded within the bash script
cat <<'EOF' > /tmp/nuke_bucket.py
from __future__ import print_function

import argparse
import sys
import boto3
from botocore.exceptions import ClientError

def delete_bucket(bucket_name, profile=None):
    """Delete a bucket (and all object versions)."""
    kwargs = {}
    if profile:
        kwargs['profile_name'] = profile

    session = boto3.Session(**kwargs)
    print('Deleting {} ...'.format(bucket_name), end='')

    try:
        s3 = session.resource(service_name='s3')
        bucket = s3.Bucket(bucket_name)
        bucket.object_versions.delete()
        bucket.delete()
    except ClientError as ex:
        print('error: {}'.format(ex.response['Error']))
        sys.exit(1)

    print('done')

def _parse_args():
    """A helper for parsing command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument('bucket_name', help='The bucket name to delete.')
    parser.add_argument('-p', '--profile', default='',
                        help='Use a specific profile for bucket operations. '
                             'Default: "default" profile in ~/.aws/config or '
                             'AWS_PROFILE environment variable')
    return parser.parse_args()

def _main():
    """Script execution handler."""
    args = _parse_args()
    delete_bucket(args.bucket_name, profile=args.profile)

if __name__ == '__main__':
    _main()
EOF

# Fetch S3 bucket names, list in reverse order, and remove date and time from the listing
s3_buckets=$(aws s3 ls | tac | sed 's/^[0-9-]\{10\} [0-9:]\{8\} //')

# Loop through each bucket and delete it using the embedded Python script
for bucket in $s3_buckets; do
  echo "Removing $bucket"
  python3 /tmp/nuke_bucket.py "$bucket"
done

# Clean up the temporary Python script
rm /tmp/nuke_bucket.py
