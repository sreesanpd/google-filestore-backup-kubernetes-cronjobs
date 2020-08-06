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

An example of how to schedule this container in Kubernetes as a cronjob is below. This would configure a filestore backup to run each day at 01:00am. The GCP Service Account Key is stored in secrets. Persistent Volumes (PVs) and Persistent Volume Claims (PVCs) for primary filestore and secondary filestores will be created. 

* replace nfs server with the IP address of each filestore instances
* replace nfs path with fileshare name of each filestore instances
* replace gcp_gcloud_auth with base64 encoded service account key
* replace the docker image url with the image you have built 
* replace GCP_BUCKET_NAME with the GCS bucket you have created for storing filestore backups


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


## Pre-Requisites

In a production evironment, we expect these pre-requisites are already created. If not, create it accordingly. 

I use google cloud shell for running the below commands. If you are not using the cloud shell make sure that you have installed necessary tools before running these.

### Set the variables

```
project=my-project-123456

vpcname=gke-vpc

subnet1=subnet1

subnet2=subnet2

storagebucket=$project-filestore-backup$RANDOM

primaryfilestore=filestore-primary

secondaryfilestore=filestore-secondary

primaryfileshare=vol1

secondaryfileshare=vol1

gkecluster=gke-cluster1

serviceaccount=filestore-backup-storage-sa
```

### 1. Create VPC & Subnets

**Create VPC**

```
gcloud compute networks create $vpcname --subnet-mode=custom  --bgp-routing-mode=regional
```

**Create Firewall Rules**


```
gcloud compute firewall-rules create allow-all-access-gke --network $vpcname  --allow all
```

**Create Subnet1 with secondary ip range for the gke pods**

```
gcloud compute networks subnets create $subnet1 --network=$vpcname --range=10.128.0.0/19  --region=europe-north1 --secondary-range=pods-$subnet1=10.130.0.0/19
```

**Create Subnet2 with secondary ip range for the gke pods**

```
gcloud compute networks subnets create $subnet2 --network=$vpcname  --range=10.132.0.0/19  --region=europe-west4 --secondary-range=pods-$subnet2=10.134.0.0/19
```


### 2. Create Storage Bucket for filestore backup

```
gsutil mb -p $project -c STANDARD -l eu gs://$storagebucket
```

### 3. Create Primary and Secondary Filestore instances

**Create Primary Filestore Instance**

```
gcloud filestore instances create $primaryfilestore --project=$project --zone=europe-north1-b --tier=STANDARD --file-share=name=$primaryfileshare,capacity=1TB --network=name=$vpcname
```

**Create Primary Filestore Instance**


```
gcloud filestore instances create $secondaryfilestore --project=$project --zone=europe-west4-a --tier=STANDARD --file-share=name=$secondaryfileshare,capacity=1TB --network=name=$vpcname
```

### 4. Create GKE Cluster


```
gcloud container clusters create $gkecluster \
    --region  europe-north1  --node-locations europe-north1-a,europe-north1-b --enable-master-authorized-networks \
    --network $vpcname \
    --subnetwork $subnet1 \
    --cluster-secondary-range-name pods-$subnet1 \
    --services-ipv4-cidr 10.131.128.0/24 \
    --enable-private-nodes \
    --enable-ip-alias \
    --master-ipv4-cidr 10.131.248.0/28 \
    --num-nodes 1  \
   --default-max-pods-per-node 64   \
    --no-enable-basic-auth \
    --no-issue-client-certificate   \
--enable-master-authorized-networks   \
--master-authorized-networks=35.201.7.129/32

```

For master-authorized-networks, replace the value with your public ip address where you will use kubectl commands. 

If you are using google cloud shell, you can run the below command to get the public ip address of your cloud shell:

```
curl icanhazip.com
```

### 5. Create Container Registry for storing container images

Refer the document to enable container registry and authenticate to it : https://cloud.google.com/container-registry/docs/quickstart


### 6. Create Service Account for filestore backup & set permissions

**Create Service Account**

```
gcloud iam service-accounts create $serviceaccount --description="sa for filestore backup gcs storage" --display-name="filestore-backup-storage-sa"
```

**Set ACL for Servicve Account in filestore backup storage bucket**

```
gsutil iam ch serviceAccount:$serviceaccount@$project.iam.gserviceaccount.com:objectAdmin gs://$storagebucket/
```

**Create JSON Key for the Service Account**

```
gcloud iam service-accounts keys create ~/filestore-backup-storage-sa-key.json --iam-account $serviceaccount@$project.iam.gserviceaccount.com
```


**Convert the Json key to base64 encoded format for using in kubernetes secret**

```
base64 ~/filestore-backup-storage-sa-key.json | tr -d '\n' | tr -d '\r' >  ~/filestore-backup-storage-sa-key-base64.txt
```


This output should be used as the value for GCP_GCLOUD_AUTH in the filestore-backups-cronjob-sample.yaml 

Note: Make sure that there is no newline while you copy paste this value to the yaml. 


## Using the Solution

**Clone the repository to the cloud shell**

```
git clone https://github.com/sreesanpd/google-filestore-backup-kubernetes-cronjobs
```

**Change Directory to repository folder**

```
cd google-filestore-backup-kubernetes-cronjobs
```

**Change Directory to Dockerfil foldere**

```
cd docker-resources 
```

**Docker build and push to container registry**

```
docker build . -t gcr.io/$project/gcp-filestore-k8s-backup

docker push gcr.io/$project/gcp-filestore-k8s-backup

```

Note: Make sure that you have followed the steps to enable container registry and authenticated to it as per the step 5 in pre-requisites

**Change directory to kubernetes folder**

```
cd ../kubernetes-resources
```

**Modify the yaml with correct values as per your requirement**

Refer to GCS - Example Kubernetes Cronjob in this document

**Create the cronjob in the GKE cluster**

```
kubectl -f kubernetes-resources/filestore-backups-cronjob-sample.yaml
```

## Troubleshooting

If there is a problem with the cronjob container, you can inspect it by:

1. Add sleep timer to the container by editing google-filestore-backup-kubernetes-cronjobs/docker-resources/resources/filestore-backup.sh. Otherwise the container will immediately get deleted after running the job.

```
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
rsync -avz --delete /mnt/$FILESHARE_MOUNT_PRIMARY/ /mnt/$FILESHARE_MOUNT_SECONDARY/

sleep 1000

```

2. Build and push the container image to container repository

3. Deploy the cronjob

4. Login to the cronjob container shell by running the below command: 

```
kubectl exec -it podname -- /bin/bash
```

Replace the podname with your cronjob's pod name. 

5. Run the bash script manually using: 


```
bash -x /filestore-backup.sh 
```

6. You can also check whether the filestore has been properly mounted by running the command: 

```
df -h
```

7. If any problem with deploying the cronjob, run:

```
kubectl describe cronjob filestore-backup
```

## Clean Up

**Delete GKE Cluster**

```
gcloud container clusters delete $gkecluster --region europe-north1 --quiet
```

**Delete Filestore Instances**

```
gcloud filestore instances delete $primaryfilestore --zone europe-north1-b --quiet

gcloud filestore instances delete $secondaryfilestore --zone europe-west4-a --quiet
```

**Delete Storage Bucket**

```
gsutil rm -r gs://$storagebucket

gsutil rb -f gs://$storagebucket 
```

**Delete Subnets**

```
gcloud compute networks subnets delete $subnet1  --region europe-north1 --quiet

gcloud compute networks subnets delete $subnet2  --region europe-west4 --quiet 
```

**Delete Firewall Rules**

```
gcloud compute firewall-rules delete allow-all-access-gke  --quiet
```

**Delete VPC**

```
gcloud compute networks delete $vpcname --quiet
```

**Delete Service Account**

```
gcloud iam service-accounts delete $serviceaccount@$project.iam.gserviceaccount.com --quiet
```
