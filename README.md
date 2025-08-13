# Bucketup

As a Kubernetes administrator there are times where we just need to serve some static content from inside our cluster so that we can either test out some new ingress settings, or provide arbitrary assets to a internal service.

This projects provides a minimalistic Helm Chart that does the following:
- On startup, download static content from GCP bucket
- Start a minimalistic http server to serve static content

We find it useful for the following scenarios:
- Serving maintenance pages
- Distributing assets