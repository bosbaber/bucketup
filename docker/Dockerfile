FROM google/cloud-sdk:slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash bucketup

COPY docker/run.sh /home/bucketup/run.sh
COPY docker/server.py /home/bucketup/server.py
RUN chown bucketup:bucketup /home/bucketup/run.sh
RUN chmod +x /home/bucketup/run.sh

# Pre-populate known_hosts for the common git SSH providers so cloning can
# use strict host key checking without any extra runtime configuration.
RUN mkdir -p /home/bucketup/.ssh \
    && ssh-keyscan -t rsa,ecdsa,ed25519 github.com gitlab.com bitbucket.org >> /home/bucketup/.ssh/known_hosts \
    && chown -R bucketup:bucketup /home/bucketup/.ssh \
    && chmod 700 /home/bucketup/.ssh \
    && chmod 600 /home/bucketup/.ssh/known_hosts

USER bucketup

WORKDIR /home/bucketup

ENTRYPOINT [ "/bin/bash", "/home/bucketup/run.sh" ]