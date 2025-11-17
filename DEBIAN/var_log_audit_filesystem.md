# Create Dedicated /var/log/audit Filesystem (5GB)

## Quick Start (Copy-Paste)

```bash
# Stop auditd
cd /root
sudo service auditd stop

# Create 5GB image and format
sudo dd if=/dev/zero of=/var/log/audit.img bs=1M count=5120 status=progress
sudo mkfs.ext4 -F -L AUDIT_LOGS /var/log/audit.img

# Add to fstab
echo "/var/log/audit.img /var/log/audit ext4 loop,defaults 0 2" | sudo tee -a /etc/fstab

# Mount it
sudo systemctl daemon-reload
sudo mount -a

# Set permissions and start
sudo chmod 750 /var/log/audit
sudo service auditd start

# Verify
df -h /var/log/audit
ls -lh /var/log/audit/
```

---

## Overview

Create a dedicated 5GB filesystem for audit logs to:
- Isolate audit logs from main filesystem
- Prevent audit logs from filling up root partition
- Better control over audit log storage

## Prerequisites

- Root access
- ~5GB free space on current partition
- Auditd installed

---

## Steps

### 1. Stop Auditd Service

```bash
cd /root
sudo service auditd stop
```

Verify it's stopped:

```bash
sudo systemctl status auditd
```

**Important:** Make sure you're NOT in `/var/log/audit/` directory before proceeding.

### 2. Backup Current Logs (Optional)

If you want to keep existing logs:
```bash
sudo tar -czf /root/audit-logs-backup-$(date +%Y%m%d).tar.gz /var/log/audit/
```

Or skip backup if you want to start fresh.

### 3. Create 5GB Disk Image File

```bash
sudo dd if=/dev/zero of=/var/log/audit.img bs=1M count=5120 status=progress
```

**Note:** This creates a 5120MB (5GB) file. Adjust `count=` if needed.
**Location:** Creating at `/var/log/audit.img` (root filesystem)

### 4. Format as ext4 Filesystem

```bash
sudo mkfs.ext4 -F -L AUDIT_LOGS /var/log/audit.img
```

### 5. Make Mount Permanent - Update /etc/fstab

```bash
echo "/var/log/audit.img /var/log/audit ext4 loop,defaults 0 2" | sudo tee -a /etc/fstab
```

**Verify fstab entry:**
```bash
grep audit.img /etc/fstab
```

### 6. Reload systemd and Mount

```bash
# Reload systemd to recognize fstab changes
sudo systemctl daemon-reload

# Mount all filesystems from fstab
sudo mount -a
```

**Verify mount:**
```bash
df -h /var/log/audit
mount | grep audit
```

Should show `/dev/loop` mounted on `/var/log/audit` with ~5GB size.

### 7. Set Proper Permissions

```bash
sudo chmod 750 /var/log/audit
sudo chown root:root /var/log/audit
```

### 8. Start Auditd Service

```bash
sudo service auditd start
```

**Verify it's running:**
```bash
sudo systemctl status auditd
```

**Check log file is created:**
```bash
ls -lh /var/log/audit/
```

Should show `audit.log` being created.

### 9. Verify Everything Works

```bash
# Check filesystem is mounted and showing correct size
df -h /var/log/audit
```

Expected output: ~5GB filesystem, /dev/loop device

```bash
# Check audit rules are loaded (should be 113+)
sudo auditctl -l | wc -l
```

```bash
# Check log file exists and is being written to NEW filesystem
ls -lh /var/log/audit/
```

**Important:** Verify the file is on the loop device:
```bash
df -h /var/log/audit/audit.log
```

Should show `/dev/loop`, NOT `/dev/sdb1` or root filesystem.

```bash
# Generate test event
touch /tmp/test && rm /tmp/test

# Search for it in logs
sudo ausearch -k delete -ts recent

# Watch logs in real-time
sudo tail -f /var/log/audit/audit.log
```

Press `Ctrl+C` to exit tail.

---

## Verification Checklist

- [ ] Filesystem is 5GB
- [ ] Mounted at /var/log/audit
- [ ] Permissions are 750
- [ ] Owner is root:root
- [ ] Entry in /etc/fstab
- [ ] Auditd is running
- [ ] Rules are loaded (113 expected)
- [ ] Logs are being written

**Commands:**
```bash
df -h /var/log/audit
ls -ld /var/log/audit
grep audit.img /etc/fstab
systemctl status auditd
auditctl -l | wc -l
ls -lh /var/log/audit/
```

---

## Alternative: Use LVM Instead

If you prefer LVM (more flexible):

```bash
# Create LV
sudo lvcreate -L 5G -n audit_lv vg_name

# Format
sudo mkfs.ext4 /dev/vg_name/audit_lv

# Mount
sudo mount /dev/vg_name/audit_lv /var/log/audit

# Add to fstab
/dev/vg_name/audit_lv /var/log/audit ext4 defaults 0 2
```

---

## Alternative: Use Separate Partition

If you have a dedicated partition (e.g., /dev/sdb1):

```bash
# Format
sudo mkfs.ext4 /dev/sdb1

# Mount
sudo mount /dev/sdb1 /var/log/audit

# Add to fstab
/dev/sdb1 /var/log/audit ext4 defaults 0 2
```

---

## Troubleshooting

### Cannot unmount /var/log/audit (target is busy)

**Problem:** When trying to unmount, you get "target is busy"

**Solution:**
```bash
# Make sure you're not in that directory
cd /root

# Stop auditd first
sudo service auditd stop

# Check what's using it
sudo fuser -vm /var/log/audit

# If still busy, force lazy unmount
sudo umount -l /var/log/audit
```

### Logs not appearing in new filesystem

**Problem:** Filesystem is mounted but no `audit.log` file appears

**Cause:** Old audit.log might be hidden under the mount point on the root filesystem

**Solution:**
```bash
# Stop auditd
sudo service auditd stop

# Unmount to see what's underneath
sudo umount /var/log/audit

# Check if old log exists
ls -lh /var/log/audit/

# Remove old logs (optional)
sudo rm -f /var/log/audit/*

# Re-mount new filesystem
sudo mount -a

# Start auditd
sudo service auditd start

# Verify log is being written to NEW filesystem
df -h /var/log/audit/audit.log
```

Should show `/dev/loop`, not root filesystem.

### Filesystem won't mount

```bash
# Check image exists
ls -lh /var/log/audit.img

# Check filesystem
sudo fsck /var/log/audit.img

# Mount manually
sudo mount -o loop /var/log/audit.img /var/log/audit
```

### Auditd won't start

```bash
# Check logs
sudo journalctl -u auditd -n 50

# Check permissions
ls -ld /var/log/audit

# Create audit.log manually if needed
sudo touch /var/log/audit/audit.log
sudo chmod 600 /var/log/audit/audit.log
```

### systemd warning about fstab modified

**Message:** "your fstab has been modified, but systemd still uses the old version"

**Solution:**
```bash
sudo systemctl daemon-reload
```

### Filesystem full
```bash
# Check usage
df -h /var/log/audit

# Check file sizes
sudo du -sh /var/log/audit/*

# Rotate logs manually
sudo service auditd rotate

# Or increase size
sudo dd if=/dev/zero bs=1M count=2048 >> /var/log/audit.img
sudo e2fsck -f /var/log/audit.img
sudo resize2fs /var/log/audit.img
```

---

## Maintenance

### Check Disk Usage
```bash
df -h /var/log/audit
du -sh /var/log/audit/*
```

### Manual Log Rotation
```bash
sudo service auditd rotate
```

### Backup Audit Logs
```bash
sudo tar -czf /backup/audit-logs-$(date +%Y%m%d).tar.gz /var/log/audit/
```

### Expand Filesystem (if needed)
```bash
# Add 2GB more
sudo dd if=/dev/zero bs=1M count=2048 >> /var/log/audit.img

# Check and resize
sudo e2fsck -f /var/log/audit.img
sudo resize2fs /var/log/audit.img

# Remount
sudo umount /var/log/audit
sudo mount -a
```

---

## Configuration in auditd.conf

Adjust these settings for 5GB filesystem:

```bash
sudo vim /etc/audit/auditd.conf
```

```
# Maximum log file size (MB)
max_log_file = 100

# Number of log files to keep
num_logs = 50

# What to do when max file size reached
max_log_file_action = rotate

# Space left threshold (MB) - alert when < 500MB free
space_left = 500
space_left_action = email

# Admin space left (MB) - critical when < 100MB
admin_space_left = 100
admin_space_left_action = halt
```

**Calculation:**
- 100MB × 50 files = 5000MB (~5GB)
- Leaves room for active log

---

## Quick Reference

### Start/Stop Audit
```bash
sudo service auditd start
sudo service auditd stop
sudo service auditd restart
sudo service auditd rotate
```

### Mount/Unmount
```bash
# Manual mount
sudo mount -o loop /var/log/audit.img /var/log/audit

# Unmount
sudo umount /var/log/audit

# Mount from fstab
sudo mount -a
```

### Check Status
```bash
df -h /var/log/audit
systemctl status auditd
auditctl -s
auditctl -l | wc -l
```

---

## Rollback (Remove Dedicated Filesystem)

If you want to revert:

```bash
# Stop auditd
sudo service auditd stop

# Unmount
sudo umount /var/log/audit

# Remove from fstab
sudo sed -i '/audit.img/d' /etc/fstab

# Remove image file
sudo rm /var/log/audit.img

# Recreate directory
sudo mkdir -p /var/log/audit
sudo chmod 750 /var/log/audit

# Restart auditd
sudo service auditd start
```

---

## Summary

**Created:**
- 5GB loop-mounted filesystem at `/var/log/audit`
- Persistent mount via `/etc/fstab`
- Proper permissions (750, root:root)

**Benefits:**
- Dedicated space for audit logs
- Prevents filling root partition
- Easy to monitor and backup
- Can be expanded if needed

**Next Steps:**
- Enable immutable mode (`-e 2`)
- Configure log rotation
- Set up log monitoring/alerts
- Regular backups

---

**File:** `var_log_audit_filesystem.md`
**Version:** 1.0
**Date:** 2025-11-16
