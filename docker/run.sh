#!/bin/bash

set -e;

# Assert that SOURCE is set
if [ -z "$SOURCE" ]; then
  echo "SOURCE environment variable is not set."
  exit 1
fi

mkdir -p content

case "$SOURCE" in
  gcs)
    if [ -z "$BUCKET_NAME" ]; then
      echo "BUCKET_NAME environment variable is not set."
      exit 1
    fi

    # Download everything in the bucket to ./content
    gsutil -m rsync -r "gs://$BUCKET_NAME" content
    ;;

  git)
    if [ -z "$GIT_REPOSITORY" ]; then
      echo "GIT_REPOSITORY environment variable is not set."
      exit 1
    fi
    if [ -z "$GIT_BRANCH" ]; then
      echo "GIT_BRANCH environment variable is not set."
      exit 1
    fi
    if [ -z "$GIT_SSH_KEY_PATH" ]; then
      echo "GIT_SSH_KEY_PATH environment variable is not set."
      exit 1
    fi

    # The mounted deploy key may be group/world readable (secret volume
    # permissions), which ssh refuses to use. Copy it to a private file
    # owned solely by this user before use.
    mkdir -p "$HOME/.ssh"
    cp "$GIT_SSH_KEY_PATH" "$HOME/.ssh/deploy_key"
    chmod 600 "$HOME/.ssh/deploy_key"

    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/deploy_key -o UserKnownHostsFile=$HOME/.ssh/known_hosts -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes"

    git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_REPOSITORY" content
    rm -rf content/.git
    ;;

  *)
    echo "Unsupported SOURCE '$SOURCE' (expected 'gcs' or 'git')."
    exit 1
    ;;
esac

# Start a simple HTTP server to serve the content
ls -la content

python3 server.py
