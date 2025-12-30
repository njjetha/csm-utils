#!/bin/bash
#******************************************************************************
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#******************************************************************************/

##### THE DEBUGGER ###
#######@@@@@@@@##########

#prereq
PREREQS="nbdkit nbdkit-linuxdisk-plugin dkms rpmdevtools libpcap-devel iniparser-devel pkg-config gcc-c++ libssh-devel swig"
DISABLE_SERVICES="irqbalance firewalld" #autofs
#firmware
FIRMWARE_PATH=/lib/firmware/qcom/qdu100
FLATIMG_PATH=$FIRMWARE_PATH/flatimg
FIRMWARE_FILES="abl_userdebug.elf aop_devcfg.mbn aop.mbn cpucp.elf devcfg.mbn efs1.bin efs2.bin efs3.bin Flashless_config.xml fw_csm_gsi_3.0.elf hypvm.mbn kernel_boot.elf logfs_ufs_8mb.bin multi_image.mbn multi_image_qti.mbn qdsp6m.qdb qdsp6sw_dtbs.elf qdsp6sw.mbn QSaharaServer Quantum.fv quantumsdk.fv qupv3fw.elf shr_cmd8.bin shrm.elf tools.fv tz.mbn uefi.elf xbl_config.elf xbl_config_usb.elf xbl_ramdump.elf xbl_s.melf zeros_1sector.bin"
FLATIMG_FILES="cache.img.raw NON-HLOS.bin persist.img.raw system.img.raw systemrw.img.raw userdata.img.raw mdmddr.mbn debug_transport.conf"
# RPM
SCRIPT_PATH="/usr/bin"
SERVICES_PATH="/etc/systemd/system"
UDEVRULES_PATH="/etc/udev/rules.d"
SCRIPT_FILES="$SCRIPT_PATH/csm-run-kickstart.sh $SCRIPT_PATH/csm-nbdkit.sh $SCRIPT_PATH/csm-nbdkit-stop.sh $SCRIPT_PATH/csm-configure-ip.sh"
SERVICE_FILES="$SERVICES_PATH/csm-configure-ip@.service $SERVICES_PATH/csm-run-kickstart@.service $SERVICES_PATH/csm-nbdkit@.service"
UDEVRULE_FILES="$UDEVRULES_PATH/99-csm-device-remove.rules $UDEVRULES_PATH/99-mhi-csm-ctrl-device.rules $UDEVRULES_PATH/99-mhi-permissions.rules $UDEVRULES_PATH/99-mhi-sriov-disable.rules $UDEVRULES_PATH/99-mhi-sriov-enable.rules"
RPM_FOLDERS="$SCRIPT_PATH $SERVICES_PATH $UDEVRULES_PATH"
RPM_FILES="$SCRIPT_FILES $SERVICE_FILES $UDEVRULE_FILES"
#kernel modules
DRIVER_MODULES="mhi_net wwan_mhi wwan mhi qcom_sahara qdu100 mhi_pci_generic mhi_wwan_mbim mhi_wwan_ctrl qcom_csm_dp"
BLACKLIST_PATH="/etc/modprobe.d"
DRIVER_AUTOLOAD_PATH="/etc/modules-load.d"
CONF_FILES="qdu100.conf"

# $1 - Message to show
# TODO - Report
show_msg () {
    echo -e "$1" >&2
}

# $1 - Message to write to file
print_msg() {
    echo -e "$1" >> /tmp/csm-host-debugger.log
}

# $1 - Message to show
# TODO - Report
show_error_msg () {
    echo -e "ERROR: $1" >&2
    print_msg "ERROR: $1"
}

# $1 - Error message"
# $2 - Device number
error_check () {
    if [ "$?" -ne 0 ]; then
        show_error_msg "$1"
    fi
}

#filsize check
# $1 - file path
# $2 - Error Message
filesize_check() {
        if ! [ -s "$1" ] ; then
            show_error_msg "$1 missing or  empty. $2"
        else
            show_msg "$1 checked"
        fi
}

#service_status_check
# $1 service
# $2 status to check active|inactive
service_status_check() {
    service_status="$( systemctl is-active $1)"
    msg="$1 service is $service_status"
    if [ "$service_status" == "$2" ]; then
        show_error_msg "$msg"
    else
        show_msg "$msg"
    fi
}

# $1 - Package name
prereq_test () {
    # Check RPM prereqs
    #nbdkit nbdkit-linuxdisk-plugin dkms rpmdevtools iniparser-devel pkg-config gcc-c++ libssh-devel
    #yum update nbdkit dkms
    #dnf install swig
    show_msg "-----prereq_test: Check whether Pre Req packages are installed"
    for pkg in $PREREQS; do
        yum list installed | grep $pkg
        error_check "ERROR: prereq_test: $pkg is not installed"
    done
    show_msg "-----prereq_test: Check for Pre-Reqs Complete\n"
    show_msg "-----prereq_test: Check for prerunning services"
    #check prerunning services
    for service in $DISABLE_SERVICES; do
        service_status_check "$service" "active"
    done
    show_msg "-----prereq_test: Check for prerunning services complete\n"
    #TODO AUTO DISABLE  SERVICES
}

#firmware
firmware_unit_test () {
    show_msg "-----firmware_unit_test: Check all the firmware files copied correctly"
    # check Firmware path
    for file in $FIRMWARE_FILES; do
        filesize_check "$FIRMWARE_PATH/$file" "Check FIRMWARE copy"
    done
    #Check flatimg path
    for file in $FLATIMG_FILES; do
        filesize_check "$FLATIMG_PATH/$file" "Check FIRMWARE copy"
    done
    show_msg "-----firmware_unit_test: END\n"
    # TODO AUTO COPY missing files
}

#Test 1
#
rpm_unit_test () {
    # rpm install check
    show_msg "-----rpm_unit_test: Check RPM installation"
    rpm -qa | grep qti-csm-host
    error_check "RPM qti-csm-host is not installed"
    # TODO  AUTOFIX - #install rpm AI if missing
    #Check for 0 file size
    show_msg "-----rpm_unit_test: Check RPM installation - Complete\n"
    show_msg "-----rpm_unit_test: Check RPM installed files"
    for file in $RPM_FILES; do
        filesize_check "$file" "Recheck RPM installation"
    done

    #Delete RPM save files
    for path in $RPM_FOLDERS; do
        rpmsave=`ls $path | grep rpmsave`
        for file in $rpmsave; do
            show_error_msg "Found $path/$file. Cleanup rpmsave files"
            # TODO  AUTOFIX
            #remove rpms save
            #rm *.rpmsave
        done
    done
    show_msg "-----rpm_unit_test: Complete\n"
}

# Driver install check
driver_unit_test () {
    # check PCIe link
    show_msg "-----driver_unit_test: Check PCIe link"
    #lspci -vmm  | grep -B2 -A3 "Qualcomm"
    lspci | grep "Qualcomm"
    error_check "PCIe link is not up"
    show_msg "-----driver_unit_test: Check PCIe link complete\n"
    # check mhi driver module load
    show_msg "-----driver_unit_test: check mhi driver module load and check for any blacklist file"
    for driver in $DRIVER_MODULES; do
        lsmod | grep $driver
        error_check "$driver module is not loaded"
        # check blacklist
        blacklistfiles="$(grep -rw "$driver" $BLACKLIST_PATH/*blacklist*.conf)"
        for file in $blacklistfiles; do
            show_error_msg "Blacklist file found - $file found. It might disable $driver module load"
        done
    done
    show_msg "-----driver_unit_test: check mhi driver module-load and check for any blacklist file complete\n"

    # check module conf files
    show_msg "-----driver_unit_test: check module conf files"
    for file in $CONF_FILES; do
        filesize_check "$DRIVER_AUTOLOAD_PATH/$file" "Recheck RPM install"
        content="$(cat $DRIVER_AUTOLOAD_PATH/$file)"
        if [ "$content" == "qdu100" ] || [ "$content" == "qcom_csm_dp" ] ; then
            show_msg "$DRIVER_AUTOLOAD_PATH/$file contains $content"
        else
            show_error_msg "Missing proper content in $DRIVER_AUTOLOAD_PATH/$file"
        fi
    done
    show_msg "-----driver_unit_test: check module conf files complete\n"
    # modinfo mhi
    show_msg "-----driver_unit_test: check installed mhi module is from RPM location"
    mhiinstalled="$(modinfo mhi | grep filename | cut -d ":" -f2 | xargs)"
    mhiversion="$(modinfo mhi | grep version | cut -d ":" -f2 | xargs)"
    if [ "$mhiinstalled" == "$DRIVER_PATH/mhi.ko.xz" ] ; then
        show_msg "MHI driver installed from $DRIVER_PATH"
        show_msg "MHI driver version $mhiversion"
    else
        show_error_msg "Incorrect MHI driver installed . Check $mhiinstalled"
    fi
    show_msg "-----driver_unit_test: check installed mhi module is from RPM location complete\n"
}


#nbdkit test
# $1  mhi channelno
nbdkit_unit_test () {
    show_msg "-----nbdkit_unit_test: Check nbdkit service"
    service_status_check "csm-nbdkit@mhi$1_SAHARA.service" "inactive"
    systemctl status csm-nbdkit@mhi$1_SAHARA.service | cat
    error_check "csm-nbdkit service hasn't ran"
    show_msg "-----nbdkit_unit_test: Check nbdkit service complete\n"
    show_msg "-----nbdkit_unit_test: Check nbdkit version"
    ver="$(nbdkit --version | cut -d " " -f2)"
    requiredver="1.24.0"
    if [ "$(printf '%s\n' "$requiredver" "$ver" | sort -V | head -n1)" = "$requiredver" ]; then
        show_msg "NBDKit version is $ver"
    else
        show_error_msg "NBDKit version should $requiredver or above"
    fi
    show_msg "-----nbdkit_unit_test: Check nbdkit version complete\n"
    show_msg "-----nbdkit_unit_test: Check nbdkit process running"
    show_msg "Check NBDKit process"
    pgrep nbdkit
    error_check "NBDKit process not running"
    show_msg "-----nbdkit_unit_test: Check nbdkit process running complete\n"
    show_msg "-----nbdkit_unit_test: Check serialid folder created"
    serialid="$(cat /sys/bus/mhi/devices/mhi$1/serial_number | cut -d " " -f3)"
    if [ -d "$FIRMWARE_PATH/$serialid" ] ; then
        show_msg "$FIRMWARE_PATH/$serialid found"
        #Check flatimg path
        for file in $FLATIMG_FILES; do
            filesize_check "$FIRMWARE_PATH/$serialid/$file" "Check FIRMWARE copy"
        done
    else
        show_error_msg " $FIRMWARE_PATH/$serialid folder is not found"
    fi
    show_msg "-----nbdkit_unit_test: Check serialid folder created complete\n"
}

# configureip
# $1  mhi channelno
cofigureip_unit_test () {
    show_msg "-----cofigureip_unit_test: Check csm-configure-ip service"
    service_status_check "csm-configure-ip@mhi$1_CSM_CTRL.service" "active"
    systemctl status csm-configure-ip@mhi$1_CSM_CTRL.service | cat
    error_check "csm-configure-ip service hasn't run"
    show_msg "-----cofigureip_unit_test: Check csm-configure-ip service complete\n"

    show_msg "-----cofigureip_unit_test: Check sw-ip channels are configured"
    ifconfig | grep -B1 -A3 mhi$1_IP_SW0
    error_check "MHI IP interface is not configured"
    ifconfig | grep -B1 -A3 mhi$1_IP_SW1
    error_check "MHI IP interface for mplane is not configured"
    show_msg "-----cofigureip_unit_test: Check sw-ip channels are configured complete\n"
}

csm_device_health_unit_test() {
    show_msg "-----csm_device_health_unit_test: Check csm-device-health service"
    service_status_check "csm-device-health@mhi$1_CSM_CTRL.service" "active"
    systemctl status csm-device-health@mhi$1_CSM_CTRL.service | cat
    error_check "csm-device-health service hasn't run"
    show_msg "-----csm_device_health_unit_test: Check csm-device-health service complete\n"
}

echo -e "\n***CSM HOST DEBUGGER RESULT***" > /tmp/csm-host-debugger.log
prereq_test
firmware_unit_test
rpm_unit_test
nbdkit_unit_test $1
cofigureip_unit_test $1
csm_device_health_unit_test $1
cat /tmp/csm-host-debugger.log