#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/
source /usr/bin/decimal-to-hex.sh

ddr_training_to_firmware_system() {
    # Retrieving the serial number of the card
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")

    # Path for firmware directory
    LASSEN_DEVICE_FOLDER=/lib/firmware/qcom/qdu100/

    # Path of training data
    training_file=/sys/bus/mhi/devices/mhi$1/ddr_training_data

    # Path for output file name
    OUTPUT_FILE=$LASSEN_DEVICE_FOLDER/mdmddr_${serialno}.mbn

    # Check if serial number specific file exists.
    if [ -f "$OUTPUT_FILE" ]; then
	    echo "Training data  file exists: $OUTPUT_FILE"
	    exit 1
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$LASSEN_DEVICE_FOLDER"

    # Wait up to 10 seconds for training file to appear
    for i in {1..10}; do
            if [ -f "$training_file" ]; then
                    break
            fi
            sleep 1
    done

    # Check if training file exists
    if [ ! -f "$training_file" ]; then
        echo "Training data file not found: $training_file"
        exit 1
    fi

    # Read training data and write to output file
    cat "$training_file" > "$OUTPUT_FILE"

    # Check if file size is zero
    if [ ! -s "$OUTPUT_FILE" ]; then
        echo "Training data file is empty. Exiting."
        exit 1
    fi

    echo "Training data copied to $OUTPUT_FILE"
}

# Udev rule triggers csm_<> service with MHI# node when Device detected on PCIe channel at boot
# $1 - MHI#
channel="$1"
echo "Device detected in $channel"
# Retrieve channel no from the /dev/mhi# string
channelno=$(echo "$channel" | cut -d "i" -f2)
echo "Channel number retrieved $channelno"
ddr_training_to_firmware_system $channelno
