#Set the base image
FROM alpine:3.11

RUN apk -v --update add \
        python3 \
        bash \
        rsync \
        curl \
        gzip \
        coreutils \
        libc6-compat \
        groff \
        less \
        gnupg \
        nfs-utils \
        rpcbind \
        && \
    rm /var/cache/apk/*

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
