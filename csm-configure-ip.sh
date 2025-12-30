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
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Error: channel number must be a non-negative."
        exit 2
    fi

    local channel=$1
    local base=$(( channel * 2 ))
    SWIP0_LOCAL_INTERFACE="mhi_swip${base}"
    MPLANE_INTERFACE="mhi_swip$(( base + 1 ))"
    echo "Host MHI interface name   --> $SWIP0_LOCAL_INTERFACE"
    echo "Mplane MHI interface name --> $MPLANE_INTERFACE"

    SWIP0_LOCAL_ADDR="192.200.100.$1"
    SWIP0_REMOTE_ADDR="192.200.101.$1"
    echo "configure interface $SWIP0_LOCAL_INTERFACE $SWIP0_LOCAL_ADDR $SWIP0_REMOTE_ADDR"
    config_interface $SWIP0_LOCAL_INTERFACE $SWIP0_LOCAL_ADDR $SWIP0_REMOTE_ADDR

    # Configure mhi_swipe1 interface for QDU Mplane App - OEM OAM App
    OAM_HOST_ADDR="192.200.102.$1"
    MPLANE_ADDR="192.200.103.$1"
    echo "configure interface $MPLANE_INTERFACE $OAM_HOST_ADDR $MPLANE_ADDR"
    config_interface $MPLANE_INTERFACE $OAM_HOST_ADDR $MPLANE_ADDR
}

# Udev rule triggers csm_nbdkit service with SAHARA channel as argument when Device detected on PCIe channel at boot
# $1 - MHI#_CSM_CTRL
channel="$1"
echo "Device detected in $channel"
# Retrieve channel no from the /dev/mhi#_CSM_CTRL string
channelno=$(echo $channel | cut -d "_" -f1 | cut -d "i" -f2)
echo "Channel number retrieved $channelno"
configure_ipaddress $channelno
