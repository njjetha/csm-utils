#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

# device_log_collection - Receive indication from device to collect logs from systemrw
# @1:  MHI Channel no
#
source /usr/bin/decimal-to-hex.sh

device_log_collection() {
    # mount uderdata to view the device info
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")
    DEVICE_FOLDER=/lib/firmware/qcom/qdu100/$serialno
    mkdir -m 644 -p /tmp/$serialno
    mount $DEVICE_FOLDER/userdata.img.raw /tmp/$serialno
    DEVICE_LOG_PATH=/var/log/device$1
    mkdir -m 644 -p $DEVICE_LOG_PATH
    rsync -av /tmp/$serialno/logs/* $DEVICE_LOG_PATH/
    umount /tmp/$serialno
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	device_log_collection $1
fi