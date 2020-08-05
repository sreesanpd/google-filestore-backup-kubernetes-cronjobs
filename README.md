# google-filestore-backup-kubernetes-cronjobs
Scheduled backup and disaster recovery solution for Google Filestore using kubernetes cronjobs

This project aims to create scheduled backup of Google Cloud Filestore contents to Google Cloud Storage (GCS) buckets at regular intervals. It also replicates the contents of Google Filestore instances in one location to Filestore instance another location at scheduled intervals for the disaster recovery (DR) purposes. It uses kubernetes cronjobs to schedule the backup. 

This would be an ideal solution if you are using Filestore instances as storage volumes for your kubernetes containers in Google Kubernetes Engine (GKE). Currently, backup and snapshot features for filestore are in [alpha](https://cloud.google.com/sdk/gcloud/reference/alpha/filestore/backups) and it didn't meet our use case. So I ventured out to create my own solution inspired from Benjamin Maynard's [kubernetes-cloud-mysql-backup](https://github.com/benjamin-maynard/kubernetes-cloud-mysql-backup) solution.

## Environment Variables

The below table lists all of the Environment Variables that are configurable for google-filestore-backup-kubernetes-cronjobs.

Environment Variables    | Purpose |
------------------------ | ------- |
GCP_GCLOUD_AUTH       |  Base64 encoded service account key exported as JSON. Example of how to generate: `base64 ~/service-key.json`                                         |
BACKUP_PROVIDER       | Backend to use for filestore backups. It will be GCP |
GCP_BUCKET_NAME       | Name of the Google Cloud Storage (GCS) bucket where filestore backups will be stored |
FILESHARE_MOUNT_PRIMARY | Mount path for primary filestore in the container. '/mnt/primary-filestore' is the default value. If you want to change it, make necessary changes in volumeMounts under container spec in the kubernetes cronjob spec. Don't change /mnt in the mount path  |
FILESHARE_MOUNT_SECONDARY |  Mount path for secondary filestore in the container. '/mnt/secondary-filestore' is the default value. If you want to change it, make necessary changes in volumeMounts under container spec in the kubernetes cronjob spec. Don't change /mnt in the mount path   |

