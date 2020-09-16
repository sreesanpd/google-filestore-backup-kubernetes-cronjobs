#!/bin/bash


## backup filestore to GCS ##
DATE=$(date +"%m-%d-%Y-%T")
gsutil rsync -r /mnt/$FILESHARE_MOUNT_PRIMARY/ gs://$GCP_BUCKET_NAME/$DATE/
