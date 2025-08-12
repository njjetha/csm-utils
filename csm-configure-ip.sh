#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

# source decimal-to-hex for converting decimal to hex
source /usr/bin/decimal-to-hex.sh

config_interface()
{
    LOCAL_INTERFACE=$1
    LOCAL_ADDR=$2
    REMOTE_ADDR=$3
    INTERFACE_TIMEOUT=60
    ifconfig -a $LOCAL_INTERFACE >/dev/null 2>&1
    while [ "$?" -ne 0 ]; do
        echo "Waiting for $LOCAL_INTERFACE..."
        sleep 1
        if [ "$INTERFACE_TIMEOUT" -le 0 ]; then
            return 1
        fi
        (( INTERFACE_TIMEOUT -= 1 ))
        ifconfig -a $LOCAL_INTERFACE >/dev/null 2>&1
    done

    # Bringup interface
    ifconfig $LOCAL_INTERFACE $LOCAL_ADDR up

    # Configure route
    ip route add $REMOTE_ADDR via $LOCAL_ADDR
    echo "ip route added for $REMOTE_ADDR via $LOCAL_ADDR"
    return 0
}

# configure_ipaddress - dynamically assign ip address based on mhi channel no
# @1:  MHI Channel no
#
configure_ipaddress() {
    SWIP0_LOCAL_INTERFACE="mhi$1_IP_SW0"
    SWIP0_LOCAL_ADDR="192.200.100.$1"
    SWIP0_REMOTE_ADDR="192.200.101.$1"
    echo "configure interface $SWIP0_LOCAL_INTERFACE $SWIP0_LOCAL_ADDR $SWIP0_REMOTE_ADDR"
    config_interface $SWIP0_LOCAL_INTERFACE $SWIP0_LOCAL_ADDR $SWIP0_REMOTE_ADDR

    # Configure mhi_swipe1 interface for QDU Mplane App - OEM OAM App
    MPLANE_INTERFACE="mhi$1_IP_SW1"
    OAM_HOST_ADDR="192.200.102.$1"
    MPLANE_ADDR="192.200.103.$1"
    echo "configure interface $MPLANE_INTERFACE $OAM_HOST_ADDR $MPLANE_ADDR"
    config_interface $MPLANE_INTERFACE $OAM_HOST_ADDR $MPLANE_ADDR

    # get debug transport config
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")
    LASSEN_DEVICE_FOLDER=/lib/firmware/qcom/qdu100/$serialno
    if [ -f $LASSEN_DEVICE_FOLDER/debug_transport.conf ]; then
        debug_transport=$(cat $LASSEN_DEVICE_FOLDER/debug_transport.conf)
    else
        debug_transport="pcie"
    fi

    timeout=10   # seconds
    interval=0.2 # seconds
    elapsed=0

    debug_node="/sys/bus/mhi/devices/mhi$1_CSM_CTRL/transport_mode"
    while (( $(echo "$elapsed < $timeout" | bc -l) )); do
        if [ -f "$debug_node" ]; then
                echo "$debug_transport" > "$debug_node"
                echo "Copied $debug_transport to $debug_node"
                return 0
        fi
        sleep $interval
        elapsed=$(echo "$elapsed + $interval" | bc)
    done

    echo "Destination file $debug_node not found after $timeout seconds."
    return 1
}

# Udev rule triggers csm_nbdkit service with SAHARA channel as argument when Device detected on PCIe channel at boot
# $1 - MHI#_CSM_CTRL
channel="$1"
echo "Device detected in $channel"
# Retrieve channel no from the /dev/mhi#_CSM_CTRL string
channelno=$(echo $channel | cut -d "_" -f1 | cut -d "i" -f2)
echo "Channel number retrieved $channelno"
configure_ipaddress $channelno
