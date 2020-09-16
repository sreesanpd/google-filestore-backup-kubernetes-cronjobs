#!/bin/bash


## rsync primary filestore to secondary filestore ##
rsync -avz --delete /mnt/$FILESHARE_MOUNT_PRIMARY/ /mnt/$FILESHARE_MOUNT_SECONDARY/
