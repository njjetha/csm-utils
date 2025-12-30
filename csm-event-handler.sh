#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

DEVICE="$1"
echo "csm-event: starting script csm-event-handler" > /dev/kmsg

if [[ "$DEVICE" == *"SAHARA"* ]]; then
    echo "csm-event: $DEVICE: starting csm-nbdkit service for SAHARA" > /dev/kmsg
    systemd-run --no-block systemctl restart csm-nbdkit@"$DEVICE".service &
    echo "csm-event: $DEVICE: csm-nbdkit service completed with status:$?" > /dev/kmsg
else
    echo "csm-event: $DEVICE: starting csm-configure-ip service for CSM_CTRL" > /dev/kmsg
    systemd-run --no-block systemctl restart csm-configure-ip@"$DEVICE".service &
    echo "csm-event: $DEVICE: csm-configure-ip service completed with status:$?" > /dev/kmsg
    echo "csm-event: $DEVICE: starting csm-device-health service for CSM_CTRL" > /dev/kmsg
    systemd-run --no-block systemctl restart csm-device-health@"$DEVICE".service &
    echo "csm-event: $DEVICE: csm-device-health service completed with status:$?" > /dev/kmsg
fi
