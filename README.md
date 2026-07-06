# Bucketup

![Publish Status](https://github.com/bosbaber/bucketup/actions/workflows/build.yaml/badge.svg)

**Bucketup** is a minimal Helm chart for serving static content from within a Kubernetes cluster.
It’s designed for situations where you quickly need to expose files—such as maintenance pages or shared assets—without deploying a full web application.

## Features

* Automatically downloads static content on startup from either:
  * a Google Cloud Storage (GCS) bucket, or
  * a git repository (via SSH, optionally using a read-only deploy key for private repos).
* Runs a lightweight HTTP server to serve the content.
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

Only SSH cloning is supported. Private repositories require a read-only SSH
deploy key stored in a Kubernetes secret that already exists in the release
namespace.

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

## Limitations

* GCS source currently supports **publicly accessible** buckets only.
* Git source only supports cloning over SSH from GitHub, GitLab, or Bitbucket
  (host key verification is limited to those three providers).
* Content is fetched once at container startup; it is not periodically
  refreshed while the pod is running.
