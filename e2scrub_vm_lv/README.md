# e2scrub_vm_lv - Online ext4 filesystem checking for KVM/libvirt VMs

A tool for performing online filesystem checks of ext4 filesystems on LVM logical volumes that are used as block devices by KVM virtual machines. This script extends the functionality of the standard `e2scrub` utility to work with VM disk images.

## Overview

When running KVM virtual machines with LVM logical volumes as their backing storage, the standard `e2scrub` utility cannot check these filesystems because they appear as raw block devices from the host's perspective. This script bridges that gap by:

1. Using the QEMU guest agent to freeze VM filesystems
2. Creating LVM snapshots of the logical volumes
3. Running e2fsck on the snapshots to detect filesystem issues
4. Sending email notifications if problems are found

## Features

- **Safe online checking**: Freezes guest filesystems before creating snapshots to ensure consistency
- **Multiple VM support**: Can check multiple VMs and their filesystems in a single run
- **Email notifications**: Sends detailed error reports when issues are detected
- **Systemd integration**: Includes service and timer units for automated weekly checks
- **Compatible with e2scrub**: Uses the same configuration file (`/etc/e2scrub.conf`)

## Requirements

- Debian/Ubuntu Linux (tested on Debian)
- KVM/QEMU with libvirt
- LVM2 for logical volume management
- QEMU guest agent installed and running in all VMs
- Standard utilities: `kpartx`, `e2fsck`, `tune2fs`
- `sendmail` or compatible MTA for email notifications

## Installation

1. **Install the QEMU guest agent in all VMs**:
   ```bash
   # Inside each VM:
   apt-get install qemu-guest-agent
   systemctl enable qemu-guest-agent
   systemctl start qemu-guest-agent
   ```

2. **Add the guest agent channel to VM configurations**:
   
   For each VM, add this to the libvirt XML configuration (inside `<devices>`):
   ```xml
   <channel type='unix'>
     <source mode='bind'/>
     <target type='virtio' name='org.qemu.guest_agent.0'/>
   </channel>
   ```
   
   Note: VMs must be fully shut down and restarted for this change to take effect.

3. **Install the script**:
   ```bash
   sudo cp e2scrub_vm_lv.sh /usr/local/bin/
   sudo chmod 755 /usr/local/bin/e2scrub_vm_lv.sh
   ```

4. **Install systemd units** (optional, for automated runs):
   ```bash
   sudo cp e2scrub-vm.service /etc/systemd/system/
   sudo cp e2scrub-vm.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable e2scrub-vm.timer
   sudo systemctl start e2scrub-vm.timer
   ```

## Configuration

1. **Edit the VM configurations** in the script (`/usr/local/bin/e2scrub_vm_lv.sh`):
   ```bash
   VM_CONFIGS=(
       "Wall:wall_root:1:/dev/vda1:/"
       "Wall:wall_squid:1:/dev/vdc1:/var/spool/squid"
       "Web:web_root:1:/dev/vda1:/"
       "Web:web_home:1:/dev/vdb1:/home"
   )
   ```
   Format: `"VM_NAME:LV_NAME:PARTITION:DEVICE:MOUNTPOINT"`

2. **Configure email settings** in `/etc/e2scrub.conf`:
   ```bash
   # Enable periodic e2scrub
   periodic_e2scrub=1
   
   # Email settings
   recipient=admin@example.com
   sender=e2scrub@hostname.example.com
   
   # Snapshot size in MB
   snap_size_mb=256
   ```

## Usage

### Manual run:
```bash
sudo /usr/local/bin/e2scrub_vm_lv.sh
```

### Check systemd timer status:
```bash
sudo systemctl status e2scrub-vm.timer
sudo systemctl list-timers
```

### View logs:
```bash
sudo journalctl -u e2scrub-vm.service
```

## How it works

1. **Pre-flight checks**: Verifies each VM is running and the guest agent is responsive
2. **Filesystem freeze**: Uses `virsh domfsfreeze` to quiesce the specific filesystem
3. **Snapshot creation**: Creates an LVM snapshot of the logical volume
4. **Immediate thaw**: Unfreezes the guest filesystem (minimizing freeze time)
5. **Filesystem check**: Runs e2fsck on the snapshot to detect issues
6. **Notification**: Sends email if corruption or errors are found
7. **Cleanup**: Removes the snapshot

## Limitations

- Only works with ext2/3/4 filesystems
- Requires QEMU guest agent to be running in VMs
- Cannot safely mark filesystems for fsck while VMs are running (only sends notifications)
- Each LV should contain only one partition with one filesystem

## Troubleshooting

### Guest agent not responding
- Verify the agent is installed and running in the VM: `systemctl status qemu-guest-agent`
- Check if the virtio channel is present: `virsh dumpxml VM_NAME | grep guest_agent`
- Test agent communication: `virsh qemu-agent-command VM_NAME '{"execute":"guest-ping"}'`

### Snapshot creation fails
- Check available space in volume group: `vgs`
- Increase `snap_size_mb` in `/etc/e2scrub.conf` if needed
- Verify no old snapshots exist: `lvs | grep e2scrub`

### Email not received
- Check if sendmail is installed: `which sendmail`
- Verify email settings in `/etc/e2scrub.conf`
- Check system mail logs: `/var/log/mail.log`

## Files

- `e2scrub_vm_lv.sh` - Main script
- `e2scrub-vm.service` - Systemd service unit
- `e2scrub-vm.timer` - Systemd timer unit
- `/etc/e2scrub.conf` - Configuration file (shared with e2scrub)

## License

This script is based on e2scrub by Darrick J. Wong and follows the same GPL v2+ licensing.

## Author

Based on original e2scrub by Darrick J. Wong <darrick.wong@oracle.com>
Adapted for KVM/LVM environments.
