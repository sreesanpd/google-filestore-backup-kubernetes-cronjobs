#!/bin/bash

## Create the GCloud Authentication file if set ##
if [ ! -z "$GCP_GCLOUD_AUTH" ]
then
    echo "$GCP_GCLOUD_AUTH" > "$HOME"/gcloud.json
    gcloud auth activate-service-account --key-file="$HOME"/gcloud.json
fi

## backup filestore to GCS ##
DATE=$(date +"%m-%d-%Y-%T")
gsutil rsync -r /mnt/$FILESHARE_MOUNT_PRIMARY/ gs://$GCP_BUCKET_NAME/$DATE/


## rsync primary filestore to secondary filestore ##
rsync -avz /mnt/$FILESHARE_MOUNT_PRIMARY/ /mnt/$FILESHARE_MOUNT_SECONDARY/
