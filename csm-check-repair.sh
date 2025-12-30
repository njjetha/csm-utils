#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/
source csm-collect-conf.sh
check-repair() {
     DEVICE_PATH="$1"
     ext4_images=(cache.img.raw persist.img.raw system.img.raw userdata.img.raw systemrw.img.raw)
     for img in ${ext4_images[@]}; do
	 echo "checking for image : $DEVICE_PATH/$img"
         e2fsck -n $DEVICE_PATH/$img
         status=$?
         if [[ $status != 0 ]]; then
             e2fsck -pf $DEVICE_PATH/$img
             status=$?
             if [[ $status -lt 3 ]]; then
                     echo "$DEVICE_PATH/$img checked and repaired as needed..."
             elif [[ $status -eq 4 || $status -eq 8 ]]; then
                     echo "$DEVICE_PATH/$img could not be repaired, copying from flatimg..."
                     LASSEN_RAW_IMG_FOLDER=/lib/firmware/qcom/qdu100/flatimg/
                     rsync -av $LASSEN_RAW_IMG_FOLDER/$img $DEVICE_PATH/
                     if [ "$img" = "system.img.raw" ]; then
                        restore-conf $DEVICE_PATH
                     fi
             fi
         fi
     done
}

