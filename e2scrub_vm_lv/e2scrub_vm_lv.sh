#!/bin/bash

#  e2scrub_vm_lv.sh - Check ext[234] filesystems on LVM volumes used by KVM VMs
#  Based on e2scrub by Darrick J. Wong <darrick.wong@oracle.com>
#
#  This script freezes guest filesystems before taking snapshots to ensure
#  consistent e2fsck results on VM disk images.

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

if (( $EUID != 0 )); then
    echo "e2scrub_vm_lv must be run as root"
    exit 1
fi

# Configuration
VG_NAME="vg0"
snap_size_mb=256
e2fsck_opts=""
conffile="/etc/e2scrub.conf"

# VM to LV mappings
# Format: "VM_NAME:LV_NAME:PARTITION:DEVICE:MOUNTPOINT"
VM_CONFIGS=(
    "Wall:wall_root:1:/dev/vda1:/"
    "Wall:wall_squid:1:/dev/vdc1:/var/spool/squid"
    "Web:web_root:1:/dev/vda1:/"
    "Web:web_home:1:/dev/vdc1:/home"
)

# Source config file if it exists
test -f "${conffile}" && . "${conffile}"

# Exit if periodic e2scrub is not enabled
if [ -z "${periodic_e2scrub}" ] || [ "${periodic_e2scrub}" -eq 0 ]; then
    exit 0
fi

# close file descriptor 3 (from cron) since it causes lvm to kvetch
if [ -e /proc/$$/fd/3 ]; then
    exec 3<&-
fi

send_error_email() {
    local vm_name="$1"
    local lv_name="$2"
    local mountpoint="$3"
    local error_type="$4"
    local details="$5"
    
    if ! type sendmail > /dev/null 2>&1; then
        echo "$0: sendmail program not found."
        return 1
    fi
    
    # Get hostname
    local hostname="$(hostname -f 2>/dev/null)"
    test -z "${hostname}" && hostname="${HOSTNAME}"
    
    # Use default recipient if not set
    if test -z "${recipient}" ; then
        recipient="root"
    fi
    
    # Use default sender if not set
    if test -z "${sender}" ; then
        sender="<e2scrub@${hostname}>"
    fi
    
    # Send email
    (cat << ENDL
To: ${recipient}
From: ${sender}
Subject: e2scrub failure on ${vm_name}:${mountpoint}

So sorry, the automatic e2scrub of ${mountpoint} on VM ${vm_name} failed.

Host: ${hostname}
Logical Volume: /dev/${VG_NAME}/${lv_name}
Error Type: ${error_type}

Details:
${details}

A log of what happened follows:
================================================================================
ENDL
    # Include recent journal entries for this run
    journalctl -n 50 --no-pager -u e2scrub-vm.service 2>/dev/null || echo "Unable to retrieve journal logs"
    ) | sendmail -t -i
}

check_vm_state() {
    local vm_name="$1"
    
    if ! virsh domstate "${vm_name}" | grep -q "running"; then
        return 1
    fi
    return 0
}

get_vm_filesystems() {
    local vm_name="$1"
    local mountpoint="$2"
    
    # Use virsh domfsinfo to check if filesystem exists and agent is working
    if virsh domfsinfo "${vm_name}" | grep -q "^ ${mountpoint}"; then
        return 0
    fi
    return 1
}

setup() {
    local vm_name="$1"
    local lv_name="$2"
    local mountpoint="$3"
    local snap="${lv_name}.e2scrub"
    local snap_dev="/dev/${VG_NAME}/${snap}"
    
    # Check if LV exists
    if [ ! -e "/dev/${VG_NAME}/${lv_name}" ]; then
        echo "${vm_name}:${lv_name} (${mountpoint}): Logical volume not found"
        return 1
    fi
    
    # Check free space in VG
    local vg_free=$(vgs --noheadings -o vg_free --units m "${VG_NAME}" | awk '{print int($1)}')
    if [ "${vg_free}" -lt "${snap_size_mb}" ]; then
        echo "${vm_name}:${lv_name} (${mountpoint}): Insufficient free space in VG for snapshot"
        return 1
    fi
    
    # Try to remove snapshot for 30s, bail out if we can't remove it
    local lvremove_deadline="$(( $(date "+%s") + 30))"
    lvremove -f "${VG_NAME}/${snap}" 2>/dev/null
    while [ "$?" -eq "5" ] && [ -e "${snap_dev}" ] &&
          [ "$(date "+%s")" -lt "${lvremove_deadline}" ]; do
        sleep 0.5
        lvremove -f "${VG_NAME}/${snap}"
    done
    if [ -e "${snap_dev}" ]; then
        echo "${vm_name}:${lv_name} (${mountpoint}): e2scrub snapshot is in use, cannot check!"
        return 1
    fi
    
    # Freeze the specific filesystem
    if ! virsh domfsfreeze "${vm_name}" --mountpoint "${mountpoint}"; then
        echo "${vm_name}:${lv_name} (${mountpoint}): Failed to freeze filesystem"
        # Try to thaw just in case it partially froze
        virsh domfsthaw "${vm_name}" 2>/dev/null
        return 1
    fi
    
    # Create the snapshot
    if ! lvcreate -s -L "${snap_size_mb}m" -n "${snap}" "${VG_NAME}/${lv_name}"; then
        virsh domfsthaw "${vm_name}"
        echo "${vm_name}:${lv_name} (${mountpoint}): Snapshot creation FAILED"
        return 1
    fi
    
    # Thaw immediately after snapshot creation
    virsh domfsthaw "${vm_name}"
    
    # Set up partition mapping
    kpartx -a "${snap_dev}"
    udevadm settle --timeout=20
    sleep 2
    
    return 0
}

teardown() {
    local lv_name="$1"
    local snap="${lv_name}.e2scrub"
    local snap_dev="/dev/${VG_NAME}/${snap}"
    local lvremove_deadline="$(( $(date "+%s") + 30))"
    
    sleep 1
    kpartx -d "${snap_dev}"

    lvremove -f "${VG_NAME}/${snap}"
    while [ "$?" -eq "5" ] && [ -e "${snap_dev}" ] &&
          [ "$(date "+%s")" -lt "${lvremove_deadline}" ]; do

        sleep 1
        kpartx -d "${snap_dev}"
        lvremove -f "${VG_NAME}/${snap}"
    done
}

check() {
    local lv_name="$1"
    local partition="$2"
    local snap="${lv_name}.e2scrub"
    local part_dev="/dev/mapper/${VG_NAME}-${snap}${partition}"
    
    # Verify partition device exists
    if [ ! -e "${part_dev}" ]; then
        return 8  # Operational error
    fi
    
    # First we recover the journal, then we see if e2fsck tries any
    # non-optimization repairs. If either of these two returns a
    # non-zero status (errors fixed or remaining) then this fs is bad.
    E2FSCK_FIXES_ONLY=1
    export E2FSCK_FIXES_ONLY
    
    e2fsck -E journal_only -p ${e2fsck_opts} "${part_dev}" || return $?
    e2fsck -f -y ${e2fsck_opts} "${part_dev}"
}


mark_corrupt() {
    # Don't actually mark anything since filesystem mounted on an active OS
    echo "WARNING: Filesystem corruption detected but not marking force_fsck"
    echo "Manual intervention required - run fsck from within the VM (tune2fs -E force_fsck /dev/{disk})"
    return 0
}

check_snapshot_invalid() {
    local lv_name="$1"
    local snap="${lv_name}.e2scrub"
    
    local is_invalid=$(lvs -o lv_snapshot_invalid --noheadings "/dev/${VG_NAME}/${snap}" | awk '{print $1}')
    if [ -n "${is_invalid}" ]; then
        return 0
    fi
    return 1
}

process_filesystem() {
    local vm_name="$1"
    local lv_name="$2"
    local partition="$3"
    local device="$4"
    local mountpoint="$5"
    
    echo "Checking ${vm_name}:${mountpoint} on /dev/${VG_NAME}/${lv_name}"
    
    # Check VM is running
    if ! check_vm_state "${vm_name}"; then
        echo "${vm_name}:${lv_name} (${mountpoint}): VM not running, skipping"
        send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "VM Not Running" "Skipping check - VM is not in running state"
        return 0
    fi
    
    # Verify filesystem exists in VM and agent is working
    if ! get_vm_filesystems "${vm_name}" "${mountpoint}"; then
        echo "${vm_name}:${lv_name} (${mountpoint}): Filesystem not found or guest agent not responding"
        send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "Guest Agent Error" "Filesystem not found or guest agent not responding"
        return 0
    fi
    
    # Setup snapshot
    if ! setup "${vm_name}" "${lv_name}" "${mountpoint}"; then
        send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "Setup Failed" "Failed to create snapshot - check logs for details"
        return 8
    fi
    
    # Set trap for cleanup
    trap "teardown '${lv_name}'" EXIT INT QUIT TERM
    
    # Check filesystem
    check "${lv_name}" "${partition}"
    local ret=$?
    
    case "$ret" in
    "0")
        # Clean check!
        echo "${vm_name}:${mountpoint}: Scrub succeeded."
        teardown "${lv_name}"
        trap '' EXIT INT QUIT TERM
        return 0
        ;;
    "8")
        # Operational error
        echo "${vm_name}:${lv_name} (${mountpoint}): e2fsck operational error"
        send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "Operational Error" "e2fsck encountered an operational error"
        teardown "${lv_name}"
        trap '' EXIT INT QUIT TERM
        return 8
        ;;
    *)
        # fsck failed. Check if the snapshot is invalid
        if check_snapshot_invalid "${lv_name}"; then
            echo "${vm_name}:${lv_name} (${mountpoint}): Scrub FAILED due to invalid snapshot"
            send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "Invalid Snapshot" "Snapshot overflow during check"
        else
            echo "${vm_name}:${lv_name} (${mountpoint}): Scrub FAILED due to corruption! Unmount and run e2fsck -y"
            mark_corrupt "${lv_name}" "${partition}"
            send_error_email "${vm_name}" "${lv_name}" "${mountpoint}" "Filesystem Corruption" "Errors detected - filesystem marked for fsck at next mount"
        fi
        teardown "${lv_name}"
        trap '' EXIT INT QUIT TERM
        return 6
        ;;
    esac
}

# Main execution
main() {
    local overall_ret=0
    
    # Check prerequisites
    if ! type lsblk >&/dev/null; then
        echo "e2scrub_vm_lv: can't find lsblk --- is util-linux installed?"
        exit 1
    fi
    
    if ! type lvcreate >&/dev/null; then
        echo "e2scrub_vm_lv: can't find lvcreate --- is lvm2 installed?"
        exit 1
    fi
    
    if ! type virsh >&/dev/null; then
        echo "e2scrub_vm_lv: can't find virsh --- is libvirt installed?"
        exit 1
    fi
    
    if ! type kpartx >&/dev/null; then
        echo "e2scrub_vm_lv: can't find kpartx --- is kpartx installed?"
        exit 1
    fi
    
    # Process each filesystem
    for config in "${VM_CONFIGS[@]}"; do
        IFS=':' read -r vm_name lv_name partition device mountpoint <<< "${config}"
        
        process_filesystem "${vm_name}" "${lv_name}" "${partition}" "${device}" "${mountpoint}"
        local ret=$?
        
        # Track worst exit code
        if [ $ret -ne 0 ] && [ $ret -gt $overall_ret ]; then
            overall_ret=$ret
        fi
    done
    
    exit $overall_ret
}

# Run main
main "$@"
