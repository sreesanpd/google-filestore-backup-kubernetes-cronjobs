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
FILESHARE_MOUNT_PRIMARY | Mount path for primary filestore in the container. '/mnt/primary-filestore' is the default location. If you want to change it, make necessary changes in volumeMounts under container spec in the kubernetes cronjob spec. Don't change /mnt in the mount path  |
FILESHARE_MOUNT_SECONDARY |  Mount path for secondary filestore in the container. '/mnt/secondary-filestore' is the default location. If you want to change it, make necessary changes in volumeMounts under container spec in the kubernetes cronjob spec. Don't change /mnt in the mount path   |

## GCS Backend Configuration

The below subheadings detail how to configure filestore to backup to a Google GCS backend.

### GCS - Configuring the Service Account

In order to backup to a GCS Bucket, you must create a Service Account in Google Cloud Platform that contains the neccesary permissions to write to the destination bucket (for example the `Storage Obect Creator` role).

Once created, you must create a key for the Service Account in JSON format. This key should then be base64 encoded and set in the `GCP_GCLOUD_AUTH` environment variable. For example, to encode `service_account.json` you would use the command `base64 ~/service-key.json` in your terminal and set the output as the `GCP_GCLOUD_AUTH` environment variable.


### GCS - Example Kubernetes Cronjob

An example of how to schedule this container in Kubernetes as a cronjob is below. This would configure a filestore backup to run each day at 01:00am. The GCP Service Account Key is stored in secrets. 


```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: primary-filestore-pv
spec:
  storageClassName: primary-filestore
  capacity:
    storage: 1000Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: "<IP address of google filestore primary instance>"
    path: "<fileshare name of the google filestore primary instance>"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: primary-filestore-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: primary-filestore
  resources:
    requests:
      storage: 1000Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: secondary-filestore-pv
spec:
  storageClassName: secondary-filestore
  capacity:
    storage: 1000Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: "<IP address of google filestore secondary instance>"
    path: "<fileshare name of the google filestore secondary instance>"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: secondary-filestore-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: secondary-filestore
  resources:
    requests:
      storage: 1000Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: filestore-backup
type: Opaque
data:
  gcp_gcloud_auth: "<Base64 encoded Service Account Key>"
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: filestore-backup
spec:
  schedule: "0 01 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: filestore-backup
            image: "<Docker Image URL>"
            imagePullPolicy: Always
            volumeMounts:
              - name: primary-filestore
                mountPath: "/mnt/primary-filestore"
              - name: secondary-filestore
                mountPath: "/mnt/secondary-filestore"
            env:
              - name: GCP_GCLOUD_AUTH
                valueFrom:
                   secretKeyRef:
                     name: filestore-backup
                     key: gcp_gcloud_auth
              - name: BACKUP_PROVIDER
                value: "gcp"
              - name: GCP_BUCKET_NAME
                value: "<Name of the GCS Bucket where filestore backups needs to be stored>"
              - name: FILESHARE_MOUNT_PRIMARY
                value: "primary-filestore"
              - name: FILESHARE_MOUNT_SECONDARY
                value: "secondary-filestore"
          restartPolicy: Never
          volumes:
            - name: primary-filestore
              persistentVolumeClaim:
                claimName: primary-filestore-pvc
            - name: secondary-filestore
              persistentVolumeClaim:
                claimName: secondary-filestore-pvc

```
