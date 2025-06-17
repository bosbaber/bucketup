#!/bin/bash

set -e;

# Assert that BUCKET_NAME is set
if [ -z "$BUCKET_NAME" ]; then
  echo "BUCKET_NAME environment variable is not set."
  exit 1
fi

# Download everything in the bucket to ./content
mkdir -p content
gsutil -m rsync -r "gs://$BUCKET_NAME" content

# Start a simple HTTP server to serve the content
cd content
python3 -m http.server 8080 --bind
