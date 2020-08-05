# google-filestore-backup-kubernetes-cronjobs
Scheduled backup and disaster recovery solution for Google Filestore using kubernetes cronjobs

This project aims to create scheduled backup of Google Cloud Filestore contents to Google Cloud Storage (GCS) buckets at regular intervals. It also replicates the contents of Google Filestore instances in one location to Filestore instance another location at scheduled intervals for the disaster recovery (DR) purposes. It uses kubernetes cronjobs to schedule the backup. 

This would be an ideal solution if you are using Filestore instances as storage volumes for your kubernetes containers in Google Kubernetes Engine (GKE). Currently, backup and snapshot features for filestore are in [alpha](https://cloud.google.com/sdk/gcloud/reference/alpha/filestore/backups) and it didn't meet our use case. So I ventured out to create my own solution inspired from Benjamin Maynard's [kubernetes-cloud-mysql-backup](https://github.com/benjamin-maynard/kubernetes-cloud-mysql-backup) solution.


