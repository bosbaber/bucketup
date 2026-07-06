# Bucketup

![Publish Status](https://github.com/bosbaber/bucketup/actions/workflows/build.yaml/badge.svg)

**Bucketup** is a minimal Helm chart for serving static content from within a Kubernetes cluster.
It’s designed for situations where you quickly need to expose files—such as maintenance pages or shared assets—without deploying a full web application.

## Features

* Automatically downloads static content on startup from either:
  * a Google Cloud Storage (GCS) bucket, or
  * a git repository (via SSH, using a read-only deploy key).
* Optionally polls the git branch for new commits and refreshes content
  in place, with an atomic swap so requests never see a half-updated tree.
* Runs a lightweight HTTP server to serve the content, with:
  * `/healthz` for readiness/liveness checks.
  * directory index resolution (`index.html`, `index.htm`, `default.html`, `default.htm`).
  * SPA-style fallback to the root `index.html` for unmatched routes.
* Simple Helm-based deployment for rapid setup.

## Common Use Cases

* Displaying maintenance or “under construction” pages.
* Serving internal assets to other services in the cluster.
* Quickly testing ingress rules or service exposure.

## Installation

Bucketup is configured via `config.source`, which selects where content is
pulled from: `gcs` or `git`.

### GCS source

```bash
helm repo add bucketuprepo https://bosbaber.github.io/bucketup
helm install bucketup bucketuprepo/bucketup \
  --set config.source=gcs \
  --set config.gcs.bucketName="my-gcs-bucket-name"
```

Currently supports **publicly accessible** GCS buckets only.

Equivalent values file:

```yaml
config:
  source: gcs
  gcs:
    bucketName: "my-gcs-bucket-name"
```

### Git source

Only SSH cloning is supported. A read-only SSH deploy key, stored in a
Kubernetes secret that already exists in the release namespace, is currently
**required for every git source**, public or private (`access.isPrivate` is
accepted for forwards compatibility but is not yet enforced/optional).

```yaml
config:
  source: git
  git:
    # only ssh cloning supported
    repository: git@github.com:interledger/interledger-app.git
    branch: docs
    access:
      isPrivate: true
      # The user should configure an ssh deploy key with RO permissions
      # on the repository
      privateKeySecretName: some-kubernetes-secret-name
      privateKeySecretKey: sshPrivateKey
```

Host key verification is enforced (`StrictHostKeyChecking=yes`); the image
ships known_hosts entries for GitHub, GitLab, and Bitbucket. Self-hosted git
servers are not currently supported.

Content is cloned once, shallow (`--depth 1`), at container startup. To
instead keep watching the branch for new commits, set
`config.git.pollIntervalSeconds` (default `0`, disabled):

```yaml
config:
  source: git
  git:
    repository: git@github.com:interledger/interledger-app.git
    branch: docs
    pollIntervalSeconds: 60
    access:
      isPrivate: true
      privateKeySecretName: some-kubernetes-secret-name
      privateKeySecretKey: sshPrivateKey
```

When enabled, a background loop checks `refs/heads/<branch>` every
`pollIntervalSeconds` and, on a new commit, clones it into a second content
directory and atomically re-points the server at it — in-flight requests
never see a partially-updated tree, and a failed poll (e.g. a transient
network error) is retried on the next interval rather than crashing the
container. This does not apply to the GCS source, which is still fetched
once at startup (see [Limitations](#limitations)).

## Limitations

* GCS source currently supports **publicly accessible** buckets only.
* Git source only supports cloning over SSH from GitHub, GitLab, or Bitbucket
  (host key verification is limited to those three providers), and always
  requires a deploy key secret, even for public repositories.
* GCS content is fetched once at container startup and is not periodically
  refreshed while the pod is running; to pick up new content, roll the
  deployment (e.g. `kubectl rollout restart deployment/<release>-web`). Git
  content can instead be kept in sync via `config.git.pollIntervalSeconds`.
