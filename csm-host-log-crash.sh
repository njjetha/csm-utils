#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

# If X100 has just crashed, then collect the host log

# $1 - 0 | 1

source /usr/bin/decimal-to-hex.sh

channelno="$1"
decimal_serial=$(cat /sys/bus/mhi/devices/mhi$channelno/serial_number | cut -d " " -f3)
serialno=$(convert_serial_to_hex "$decimal_serial")
CRASH_DUMP_FOLDER=/local/mnt/crash/$serialno

X100_IP=192.200.101.$channelno
ADB=/local/mnt/workspace/adb/adb
last_reset_reason=""
just_crashed="no"
config_file="/etc/host_log_crash.cfg"

echo "channelno: $channelno"
echo "serialno: $serialno"
echo "CRASH_DUMP_FOLDER: $CRASH_DUMP_FOLDER"
echo "X100_IP: $X100_IP"

X100_just_crashed()
{
    count=0
    while true; do
        $ADB connect ${X100_IP}:5555
        if [ "$?" -ne 0 ]; then
            count=$((count + 1))
            if [ $count -ge 10 ]; then
                echo "Can't connect X100 adb device. Exit"
                exit 1
            fi
            echo "Waiting for X100 adb device to connect"
            sleep 5
        else
            break
        fi
    done

    timeout 180s $ADB -s $X100_IP wait-for-device
    if [ "$?" -ne 0 ]; then
        echo "No X100 adb device. Exit"
        exit 2
    fi

    device_state=`$ADB -s $X100_IP get-state`

    if [ "$device_state" == "device" ]; then
        echo "Found X100 ADB device on $X100_IP"
    else
        echo "X100 ADB device is in unexpected state: $device_state. Exit"
        exit 3
    fi

    last_reset_reason=`$ADB -s $X100_IP shell "cat /sys/kernel/reset_reason/reset_reason"`
    echo "$last_reset_reason"
    if [[ "$last_reset_reason" == *"panic"* || "$last_reset_reason" == *"watchdog bark"* ]]; then
        just_crashed="yes"
        echo "X100 $X100_IP just crashed"
    fi
}

collect_host_log()
{
    ts=$(date "+%m.%d.%Y-%H.%M.%S")
    log_folder=${CRASH_DUMP_FOLDER}/host_logs/$ts
    mkdir -p -m 644 $log_folder

    ## The format of config file
    # Log type,command to get log,collect or not

    # Read and process the first line
    IFS=',' read -r property Num_log_set < "$config_file"
    echo "Num_log_set: $Num_log_set"

    cd ${CRASH_DUMP_FOLDER}/host_logs || exit # to make sure we don't accidentally remove incorrect files

    # List all files (not directories), sorted by newest first
    all_files=$(ls -tp | grep -v '/$')
    echo "all files: $all_files"

    # Get the files to delete (everything after the first Num_log_set)
    files_to_delete=$(echo "$all_files" | tail -n +$Num_log_set)

    # Delete the files
    echo "files_to_delete: $files_to_delete"
    echo "$files_to_delete" | xargs -d '\n' rm -f --

    cd $log_folder

    # Now read and process the rest of the lines
    tail -n +2 "$config_file" | while IFS=',' read -r log_type command collect; do
        echo "Read: $log_type, $command, $collect"
        if [[ "$collect" == "yes" ]]; then
            echo "Proceed: $log_type, $command, $collect"
            $command > ${log_type}.txt
        fi
    done

    cd ${CRASH_DUMP_FOLDER}/host_logs
    zip -r ${ts}.zip $ts
    rm -rf $log_folder

    echo "$(date) : host log at ${log_folder}.zip"
}

X100_just_crashed

if [ "$just_crashed" == "yes" ]; then
    collect_host_log
fi
