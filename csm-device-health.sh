#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

source decimal-to-hex.sh
source csm-host-logger.sh

BOOT_TIME_OUT=600
INTERVAL=5            # Check every 5 seconds

# Checks the boot status by polling for 
# boot_flag file

device_boot_check () {
    LASSEN_FW_FOLDER=/lib/firmware/qcom/qdu100/
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")

    mnt_dir=$(mktemp -d)
    boot_status_file=$mnt_dir/post_boot/boot_flag
    LASSEN_DEVICE_FOLDER=$LASSEN_FW_FOLDER$serialno
    while [ "$BOOT_TIME_OUT" > 0 ]; do
        if mount $LASSEN_DEVICE_FOLDER/userdata.img.raw $mnt_dir; then
            if [[ -f $boot_status_file ]]; then
                recv_msg=$(cat $boot_status_file)
                echo "Received message from device $recv_msg"
                boot_status=success
                device_log_collection $1
                rm -f $boot_status_file
                umount $mnt_dir
                return
            fi
        umount $mnt_dir
        fi
        sleep $INTERVAL
        BOOT_TIME_OUT=$(( BOOT_TIME_OUT - INTERVAL ))
    done

    # Check exit status of timeout
    echo "Boot up confirmation not received within BOOT_TIME_OUT"
    echo "Invoke csm host debugger"
    source csm-host-debugger.sh $1
    boot_status="error"
}
# Udev rule triggers csm_nbdkit service with SAHARA channel as argument when Device detected on PCIe channel at boot
# $1 - MHI#_CSM_CTRL
channel="$1"
echo "Device detected in $channel"
# Retrieve channel no from the /dev/mhi#_CSM_CTRL string
channelno=$(echo $channel | cut -d "_" -f1 | cut -d "i" -f2)
echo "Channel number retrieved $channelno"
# check for device boot
boot_status=""
device_boot_check $channelno
if [ "$boot_status" == "error" ]; then
    echo "Device boot failed"
    exit
fi

#Start a timer to collect logs from device
sudo systemctl start csm-host-logger@$channelno.timer
sudo systemctl start csm-collect-conf@$channelno.timer

echo "$(date) :Collect host log if X100 just crashed" >> /tmp/host_log_crash.log
csm-host-log-crash.sh "$channelno" >> /tmp/host_log_crash.log 2>&1