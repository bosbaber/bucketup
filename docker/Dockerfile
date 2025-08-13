FROM google/cloud-sdk:slim

RUN useradd -ms /bin/bash bucketup

COPY docker/run.sh /home/bucketup/run.sh
COPY server.py /home/bucketup/server.py
RUN chown bucketup:bucketup /home/bucketup/run.sh
RUN chmod +x /home/bucketup/run.sh

USER bucketup

WORKDIR /home/bucketup

ENTRYPOINT [ "/bin/bash", "/home/bucketup/run.sh" ]