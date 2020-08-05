# Set the base image
FROM ubuntu

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y python3 bash rsync curl gzip coreutils nfs-common net-tools telnet && \
  rm -rf /var/lib/apt/lists/*

# Set Default Environment Variables
ENV CLOUD_SDK_VERSION=285.0.1
ENV BACKUP_PROVIDER=gcp

# Set Google Cloud SDK Path
ENV PATH /google-cloud-sdk/bin:$PATH

# Install Google Cloud SDK
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version


# Copy backup script and execute
COPY resources/filestore-backup.sh /
RUN chmod +x /filestore-backup.sh
CMD ["bash", "/filestore-backup.sh"]


