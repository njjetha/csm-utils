#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

# Source any required scripts
source /usr/bin/csm-check-repair.sh
source /usr/bin/decimal-to-hex.sh

set_debug_transport() {
    LASSEN_DEVICE_FOLDER=$1
    if [ -f $LASSEN_DEVICE_FOLDER/debug_transport.conf ]; then
        debug_transport=$(cat $LASSEN_DEVICE_FOLDER/debug_transport.conf)
    else
        debug_transport="pcie"
    fi
    mnt_data_dir="/tmp/data.$serialno"
    mkdir -p $mnt_data_dir
    mount $LASSEN_DEVICE_FOLDER/userdata.img.raw $mnt_data_dir
    echo -n $debug_transport > $mnt_data_dir/debug_transport.conf
    umount $mnt_data_dir
}
# transfer images via qsahara channel for the x100 card connected PCIe card via channel no#
# @1:  MHI Channel no

sync_device_firmware_image () {
    LASSEN_FW_FOLDER=/lib/firmware/qcom/qdu100/
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")
    CRASH_DUMP_FOLDER=/local/mnt/crash/$serialno
    mkdir -p -m 777 $CRASH_DUMP_FOLDER
    LASSEN_RAW_IMG_FOLDER=$LASSEN_FW_FOLDER/flatimg/
    LASSEN_DEVICE_FOLDER=$LASSEN_FW_FOLDER/$serialno
    #create device folder to copy individual device file system if not found
    # it saves previous loaded filesystem.
    # To clean up remove entire flatimg* folders from x12 manually
    if [ ! -d $LASSEN_DEVICE_FOLDER ]; then
        mkdir -m 777 $LASSEN_DEVICE_FOLDER
        rsync -av $LASSEN_RAW_IMG_FOLDER $LASSEN_DEVICE_FOLDER
    fi
    echo "sync_device_firmware_image completed for $serialno"

    echo "setting up debug transport..."
    set_debug_transport $LASSEN_DEVICE_FOLDER
}

# Trigger nbdkit command for the x100 card connected PCIe card #
# @1:  MHI Channel no
trigger_nbdkit() {
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")
    LASSEN_DEVICE_FOLDER=/lib/firmware/qcom/qdu100/$serialno

    check-repair $LASSEN_DEVICE_FOLDER

    # If the ndbkit isn't already triggered by a socket
    # then start it here.
    portno=$(( 10809 + $1 ))
    config_portno=$(( 12809 + $1 ))
    echo "port no for nbdkit - $portno"

    if ! systemctl is-active nbdkit.socket > /dev/null 2>&1; then
        nbdkit --filter=exportname file dir=$LASSEN_DEVICE_FOLDER -p $portno
        nbdkit --filter=cow linuxdisk $LASSEN_DEVICE_FOLDER/config size=4M type=ext4 -p $config_portno
    fi

    echo "nbdkit configured for the device $serialno at port $portno"
}

# Udev rule triggers csm_nbdkit service with mhi$1_CSM_CTRL channel as argument when Device detected on PCIe channel at boot
# $1 - mhi#_CSM_CTRL
channel="$1"
echo "Device detected in $channel"

# Retrieve channel no from the /dev/mhi#_CSM_CTRL string
channelno=$(echo $channel | cut -d "_" -f1 | cut -d "i" -f2)
echo "Channel number retrieved $channelno"

# Run both functions
sync_device_firmware_image $channelno
trigger_nbdkit $channelno

echo "Device setup completed for $channel"
