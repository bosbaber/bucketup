FROM google/cloud-sdk:slim

RUN useradd -ms /bin/bash bucketup
USER bucketup

WORKDIR /home/bucketup
COPY docker/run.sh /home/bucketup/run.sh
RUN chmod +x /home/bucketup/run.sh

ENTRYPOINT [ "/bin/bash", "/home/bucketup/run.sh" ]