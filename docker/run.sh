#!/bin/bash

set -e;

# Assert that SOURCE is set
if [ -z "$SOURCE" ]; then
  echo "SOURCE environment variable is not set."
  exit 1
fi

case "$SOURCE" in
  gcs)
    if [ -z "$BUCKET_NAME" ]; then
      echo "BUCKET_NAME environment variable is not set."
      exit 1
    fi

    # Download everything in the bucket to ./content
    mkdir -p content
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

    # Normalize an optional poll interval; 0 (default) disables polling.
    GIT_POLL_INTERVAL="${GIT_POLL_INTERVAL:-0}"
    case "$GIT_POLL_INTERVAL" in
      ''|*[!0-9]*) GIT_POLL_INTERVAL=0 ;;
    esac

    # The mounted deploy key may be group/world readable (secret volume
    # permissions), which ssh refuses to use. Copy it to a private file
    # owned solely by this user before use.
    mkdir -p "$HOME/.ssh"
    cp "$GIT_SSH_KEY_PATH" "$HOME/.ssh/deploy_key"
    chmod 600 "$HOME/.ssh/deploy_key"

    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/deploy_key -o UserKnownHostsFile=$HOME/.ssh/known_hosts -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes"

    # Content lives in one of two slot directories; "content" is a symlink
    # pointing at whichever slot is currently live. Re-pointing the symlink
    # with `mv -T` is an atomic rename, so in-flight requests never see a
    # half-written tree, even while a newer commit is being cloned in the
    # background.
    clone_git_slot() {
      rm -rf "$1"
      git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_REPOSITORY" "$1"
    }

    active_slot="content-a"
    [ -e content ] && [ ! -L content ] && rm -rf content
    clone_git_slot "$active_slot"
    current_sha="$(git -C "$active_slot" rev-parse HEAD)"
    rm -rf "$active_slot/.git"
    ln -sfn "$active_slot" content.tmp
    mv -T content.tmp content

    if [ "$GIT_POLL_INTERVAL" -gt 0 ]; then
      echo "Polling $GIT_REPOSITORY ($GIT_BRANCH) every ${GIT_POLL_INTERVAL}s for new commits"
      (
        set +e
        while true; do
          sleep "$GIT_POLL_INTERVAL"
          remote_sha="$(git ls-remote "$GIT_REPOSITORY" "refs/heads/$GIT_BRANCH" | cut -f1)"
          if [ -z "$remote_sha" ] || [ "$remote_sha" = "$current_sha" ]; then
            continue
          fi

          next_slot="content-b"
          [ "$active_slot" = "content-b" ] && next_slot="content-a"

          if ! clone_git_slot "$next_slot"; then
            echo "poll: clone of $GIT_BRANCH failed, will retry" >&2
            continue
          fi

          new_sha="$(git -C "$next_slot" rev-parse HEAD)"
          rm -rf "$next_slot/.git"
          ln -sfn "$next_slot" content.tmp
          mv -T content.tmp content
          rm -rf "$active_slot"
          active_slot="$next_slot"
          current_sha="$new_sha"
          echo "content updated to $current_sha"
        done
      ) &
    fi
    ;;

  *)
    echo "Unsupported SOURCE '$SOURCE' (expected 'gcs' or 'git')."
    exit 1
    ;;
esac

# Start a simple HTTP server to serve the content
ls -la content

python3 server.py
