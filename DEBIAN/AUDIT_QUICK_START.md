# Audit Hardening Quick Start Guide

## Quick Setup (3 Steps)

### 1. Install auditd
```bash
sudo apt-get update
sudo apt-get install -y auditd audispd-plugins
```

### 2. Deploy audit rules
```bash
# Copy the rules file to the correct location
sudo cp etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules
sudo chmod 640 /etc/audit/rules.d/audit.rules
```

### 3. Load and test
```bash
sudo ./load_and_test_audit_rules.sh
```

---

## What's Included

### Files Created:
- **`etc/audit/rules.d/audit.rules`** - Comprehensive audit rules (300+ lines)
- **`load_and_test_audit_rules.sh`** - Simple load and test script
- **`audit_hardening_check.sh`** - Full compliance checker
- **`deploy_audit_hardening.sh`** - Complete deployment automation

### Monitoring Coverage:
- ✅ Time changes
- ✅ User/group modifications
- ✅ Network configuration changes
- ✅ Login/logout events
- ✅ Permission changes
- ✅ Unauthorized access attempts
- ✅ Privileged command execution
- ✅ Sudo usage
- ✅ Kernel module loading
- ✅ File deletions
- ✅ System call auditing
- ✅ Firewall changes
- ✅ Package management
- ✅ Cron jobs
- ✅ And much more...

---

## Essential Commands

### Load Rules
```bash
# Load rules from /etc/audit/rules.d/
sudo augenrules --load

# Or restart service
sudo systemctl restart auditd
```

### View Rules
```bash
# List all active rules
sudo auditctl -l

# Count active rules
sudo auditctl -l | wc -l
```

### Search Audit Logs
```bash
# Search by key (recent events)
sudo ausearch -k delete -ts recent
sudo ausearch -k privileged -ts recent
sudo ausearch -k sudo_config -ts recent
sudo ausearch -k access -ts recent

# Search by time
sudo ausearch -ts today
sudo ausearch -ts this-week
sudo ausearch -ts 01/15/2025 10:00:00

# Search for specific user
sudo ausearch -ua username

# Search for failed events
sudo ausearch -m USER_LOGIN -sv no
```

### Generate Reports
```bash
# Summary report
sudo aureport --summary

# Login report
sudo aureport --login

# Failed login attempts
sudo aureport --login --failed

# File access report
sudo aureport -f

# Executable report
sudo aureport -x
```

### Real-time Monitoring
```bash
# Watch audit log in real-time
sudo tail -f /var/log/audit/audit.log

# Watch with filtering
sudo tail -f /var/log/audit/audit.log | grep -i sudo
```

---

## Testing Your Setup

After loading rules, test them:

```bash
# Test file deletion monitoring
touch /tmp/testfile
rm /tmp/testfile
sudo ausearch -k delete -ts recent | grep testfile

# Test permission change monitoring
touch /tmp/testfile
chmod 777 /tmp/testfile
sudo ausearch -k perm_mod -ts recent | grep chmod

# Test sudo monitoring
sudo ls
sudo ausearch -k privileged -ts recent | grep sudo

# Cleanup
rm -f /tmp/testfile
```

---

## Configuration Files

### Main Config: `/etc/audit/auditd.conf`
Key settings:
```
max_log_file = 32          # MB per log file
num_logs = 10              # Keep 10 rotated logs
max_log_file_action = rotate
space_left_action = email
admin_space_left_action = halt
```

### Rules Directory: `/etc/audit/rules.d/`
- `audit.rules` - Main rules file (your custom rules)
- `privileged.rules` - Auto-generated privileged commands

### Active Rules: `/etc/audit/audit.rules`
- Generated automatically by `augenrules`
- Don't edit directly

---

## Important Notes

### Immutable Mode (`-e 2`)
The `-e 2` flag locks audit rules and requires a reboot to change them.

**Currently:** Commented out for easy testing
**For Production:** Uncomment in the rules file:
```bash
# Edit the file
sudo nano /etc/audit/rules.d/audit.rules

# Change this line:
# -e 2

# To this:
-e 2

# Then reload
sudo augenrules --load
```

⚠️ **WARNING:** After enabling `-e 2`, you MUST reboot to modify rules!

### Performance Impact
- **Low:** Basic file watches (user/group files, configs)
- **Moderate:** System call monitoring (chmod, chown, etc.)
- **High:** execve monitoring on all processes

Adjust based on your system's capacity.

### Log Rotation
Audit logs are in `/var/log/audit/audit.log`

Check size:
```bash
du -sh /var/log/audit/
```

---

## Troubleshooting

### Rules not loading?
```bash
# Check syntax errors
sudo augenrules --check

# Check auditd status
sudo systemctl status auditd

# View logs
sudo journalctl -u auditd -n 50
```

### No events being logged?
```bash
# Verify rules are active
sudo auditctl -l | wc -l

# Check audit daemon
sudo auditctl -s

# Test manually
sudo auditctl -w /tmp/test -p wa -k testkey
touch /tmp/test
sudo ausearch -k testkey
```

### Too many events?
Reduce monitoring by:
1. Increasing auid filter (only monitor UID >= 1000)
2. Removing execve monitoring
3. Limiting directory watches

---

## Common Search Keys

| Key | Purpose |
|-----|---------|
| `time-change` | Time/date modifications |
| `identity` | User/group file changes |
| `system-locale` | Network configuration |
| `perm_mod` | Permission changes |
| `access` | Failed access attempts |
| `privileged` | Setuid/setgid program execution |
| `sudo_config` | Sudo configuration changes |
| `modules` | Kernel module operations |
| `delete` | File deletions |
| `exec` | Program execution |
| `firewall` | Firewall changes |
| `software_mgmt` | Package install/remove |

---

## Next Steps

1. ✅ Load rules with `load_and_test_audit_rules.sh`
2. ✅ Verify with `audit_hardening_check.sh`
3. ✅ Monitor logs for a few days
4. ✅ Tune rules based on your needs
5. ✅ Enable immutable mode (`-e 2`) for production
6. ✅ Set up log aggregation/SIEM if needed

---

## Resources

- Manual pages: `man auditd.conf`, `man auditctl`, `man ausearch`
- Audit logs: `/var/log/audit/audit.log`
- Config: `/etc/audit/auditd.conf`
- Rules: `/etc/audit/rules.d/audit.rules`
