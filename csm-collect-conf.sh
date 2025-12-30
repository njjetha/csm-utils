#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

# device_collect_config - Receive indication from device to backup conf from systemrw
# restore-conf - Restores the backed up conf on file corruption

source /usr/bin/decimal-to-hex.sh
backup_conf=(
        "/etc/splane/internal/si5518_dload_image_cfg.conf"
        "/etc/splane/internal/sync_timing_ptp2_boundary_clock_G_8275_1_multicast.conf"
        "/etc/splane/internal/sync_timing_ptp2_slave_clock_G_8275_1_multicast.conf"
        "/etc/splane/internal/sync_timing_ptp2_t_gm_G_8275_1_multicast.conf"
        "/etc/splane/internal/sync_timing_ptp2_t_gm_only.conf"
        "/etc/sync_timing_driver.conf"
        "/etc/splane/internal/x100/splane_intern_cfg.conf"
        "/etc/transceiver_dual_speed_cfg.conf"
        "/etc/transceiver_fault_management_cfg.conf"
        "/etc/transceiver_logger_cfg.conf"
        "/etc/transceiver_perf_cfg.conf"
        "/etc/fault_manager/public/Qualcomm_fault_configuration.conf"
)

device_collect_config() {
    # mount system.img to view the device info
    decimal_serial=$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)
    serialno=$(convert_serial_to_hex "$decimal_serial")
    DEVICE_FOLDER=/lib/firmware/qcom/qdu100/$serialno
    mkdir -m 644 -p /tmp/tmp.$serialno
    mount $DEVICE_FOLDER/system.img.raw /tmp/tmp.$serialno
    DEVICE_CONF_PATH=$DEVICE_FOLDER/conf
    if [ ! -d "$DEVICE_CONF_PATH" ];then
        mkdir -m 644 -p $DEVICE_CONF_PATH
    fi
    echo "Backing up configs to backup path $DEVICE_CONF_PATH..."
    for conf in ${backup_conf[@]}; do
        rsync -av /tmp/tmp.$serialno$conf $DEVICE_CONF_PATH
    done
    umount /tmp/tmp.$serialno
}

restore-conf() {
    DEVICE_CONF_PATH=$1/conf
    serialno=$(basename $1)
    if [ -d "$DEVICE_CONF_PATH" ];then
        echo "Restoring configs from backup path $DEVICE_CONF_PATH..."
        mkdir -m 644 -p /tmp/tmp.$serialno
        mount $1/system.img.raw /tmp/tmp.$serialno
        for conf_path in ${backup_conf[@]}; do
            conf_name=$(basename $conf_path)
            rsync -av $DEVICE_CONF_PATH/$conf_name /tmp/tmp.$serialno$conf_path
        done
        umount /tmp/tmp.$serialno
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    device_collect_config $1
fi