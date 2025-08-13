# Bucketup

![Publish Status](https://github.com/bosbaber/bucketup/actions/workflows/build.yaml/badge.svg)

**Bucketup** is a minimal Helm chart for serving static content from within a Kubernetes cluster.
It’s designed for situations where you quickly need to expose files—such as maintenance pages or shared assets—without deploying a full web application.

## Features

* Automatically downloads static content from a specified Google Cloud Storage (GCS) bucket on startup.
* Runs a lightweight HTTP server to serve the content.
* Simple Helm-based deployment for rapid setup.

## Common Use Cases

* Displaying maintenance or “under construction” pages.
* Serving internal assets to other services in the cluster.
* Quickly testing ingress rules or service exposure.

## Installation

```bash
helm repo add bucketuprepo https://bosbaber.github.io/bucketup
helm install bucketup bucketuprepo/bucketup --set bucketName="my-gcs-bucket-name"
```

## Limitations

* Currently supports **publicly accessible** GCS buckets only.
  (Support for private buckets and authentication is planned.)
