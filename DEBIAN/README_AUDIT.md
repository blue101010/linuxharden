# Debian Audit Hardening Toolkit

Complete audit hardening solution with syntax highlighting support.

## 📦 What's Included

### Core Audit Files
- **`etc/audit/rules.d/audit.rules`** - Comprehensive audit ruleset (30 categories, 300+ lines)
- **`audit_hardening_check.sh`** - Compliance checker
- **`load_and_test_audit_rules.sh`** - Simple loader with testing ⭐ **START HERE**
- **`deploy_audit_hardening.sh`** - Full deployment automation

### Vim Syntax Highlighting
- **`audit.vim`** - Vim syntax highlighting for .rules files
- **`install_vim_audit_syntax.sh`** - Auto-installer
- **`quick_vim_setup.sh`** - One-command setup
- **`VIM_SYNTAX_SETUP.md`** - Detailed vim setup guide

### Documentation
- **`AUDIT_QUICK_START.md`** - Quick reference guide
- **`README_AUDIT.md`** - This file

---

## 🚀 Quick Start (3 Steps)

### 1. Fix Vim Syntax Highlighting

```bash
# Quick method
chmod +x quick_vim_setup.sh
./quick_vim_setup.sh

# Now test it
vim etc/audit/rules.d/audit.rules
```

You should see beautiful syntax highlighting! 🎨

### 2. Deploy Audit Rules

```bash
# Copy rules to system
sudo cp etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules

# Load and test
chmod +x load_and_test_audit_rules.sh
sudo ./load_and_test_audit_rules.sh
```

### 3. Verify Everything

```bash
# Run compliance check
chmod +x audit_hardening_check.sh
sudo ./audit_hardening_check.sh
```

Done! ✅

---

## 📚 Detailed Usage

### Option A: Simple Load & Test (Recommended)

```bash
sudo ./load_and_test_audit_rules.sh
```

This script will:
- ✅ Check auditd service
- ✅ Backup current rules
- ✅ Load new rules via `augenrules --load`
- ✅ Verify all rule categories
- ✅ Run live tests
- ✅ Show useful commands

### Option B: Full Deployment

```bash
sudo ./deploy_audit_hardening.sh
```

This script will:
- ✅ Install auditd if missing
- ✅ Configure auditd.conf
- ✅ Deploy audit rules
- ✅ Generate privileged command rules
- ✅ Configure GRUB for audit
- ✅ Set proper permissions
- ✅ Create helper scripts
- ✅ Enable and restart service

### Option C: Manual Deployment

```bash
# Install auditd
sudo apt-get install -y auditd audispd-plugins

# Deploy rules
sudo cp etc/audit/rules.d/audit.rules /etc/audit/rules.d/
sudo chmod 640 /etc/audit/rules.d/audit.rules

# Load rules
sudo augenrules --load

# Verify
sudo auditctl -l | wc -l
```

---

## 🎨 Vim Syntax Highlighting

### Quick Install

```bash
./quick_vim_setup.sh
```

### Manual Install

```bash
# Create directories
mkdir -p ~/.vim/syntax ~/.vim/ftdetect

# Install syntax file
cp audit.vim ~/.vim/syntax/

# Enable filetype detection
echo "autocmd BufRead,BufNewFile *.rules set filetype=audit" > ~/.vim/ftdetect/audit.vim

# Update .vimrc
echo "syntax on" >> ~/.vimrc
echo "autocmd BufRead,BufNewFile *.rules set filetype=audit syntax=audit" >> ~/.vimrc
```

### What Gets Highlighted

- 🟦 **Comments** - Including TODO, FIXME, NOTE
- 🟩 **File paths** - /etc/, /var/, etc.
- 🟪 **Keywords** - Flags, actions, filters
- 🟨 **System calls** - chmod, execve, etc.
- 🟥 **Numbers** - Buffer sizes, UIDs, etc.
- 🟧 **Keys** - Rule keys for searching
- ⬜ **Section dividers** - ############

### Test Syntax Highlighting

```bash
# Edit any rules file
vim /etc/audit/rules.d/audit.rules
vim etc/audit/rules.d/audit.rules

# If colors don't show
:syntax on
:set filetype=audit
```

---

## 🔍 Monitoring & Reports

### View Active Rules

```bash
# List all rules
sudo auditctl -l

# Count rules
sudo auditctl -l | wc -l

# Search for specific key
sudo auditctl -l | grep -i sudo
```

### Search Audit Logs

```bash
# Recent events by key
sudo ausearch -k delete -ts recent
sudo ausearch -k privileged -ts recent
sudo ausearch -k sudo_config -ts recent
sudo ausearch -k access -ts recent

# By time
sudo ausearch -ts today
sudo ausearch -ts this-week

# By user
sudo ausearch -ua username

# Failed events
sudo ausearch -sv no
```

### Generate Reports

```bash
# Summary
sudo aureport --summary

# Login attempts
sudo aureport --login

# Failed logins
sudo aureport --login --failed

# File access
sudo aureport -f

# Executables
sudo aureport -x

# By user
sudo aureport -u
```

### Real-time Monitoring

```bash
# Watch audit log
sudo tail -f /var/log/audit/audit.log

# Watch with filtering
sudo tail -f /var/log/audit/audit.log | grep -i failed

# Watch specific key
sudo tail -f /var/log/audit/audit.log | grep 'key="privileged"'
```

---

## 📋 Rule Categories

The audit.rules file includes:

1. **Time Changes** - System date/time modifications
2. **User/Group Info** - /etc/passwd, /etc/shadow changes
3. **Network Config** - Hostname, hosts file, network changes
4. **MAC Policy** - AppArmor/SELinux configuration
5. **Login/Logout** - faillog, lastlog, tallylog
6. **Sessions** - utmp, wtmp, btmp
7. **Permissions** - chmod, chown, setxattr
8. **Access Attempts** - Failed opens with EACCES/EPERM
9. **Privileged Commands** - sudo, su, passwd, etc.
10. **Sudo Usage** - /etc/sudoers monitoring
11. **Kernel Modules** - insmod, rmmod, modprobe
12. **File Deletions** - unlink, rename, rmdir
13. **Executions** - execve system call
14. **Systemd** - Service management
15. **Critical Files** - sysctl, SSH config
16. **Firewall** - iptables, nftables, ufw
17. **PAM** - Authentication modules
18. **Boot Config** - GRUB configuration
19. **Package Mgmt** - apt, dpkg
20. **Log Files** - auth.log, syslog
21. **Cron Jobs** - Scheduled tasks
22. **Special Dirs** - /tmp, /var/tmp, /root
23. **Databases** - MySQL, PostgreSQL (optional)
24. **Web Servers** - Apache, Nginx (optional)
25. **Containers** - Docker (optional)
26. **Audit Config** - Self-monitoring

---

## 🔧 Configuration

### Immutable Mode

The `-e 2` flag makes audit rules immutable (requires reboot to change).

**Default:** Commented out for testing
**Production:** Uncomment the last line in audit.rules

```bash
# Edit rules
sudo vim /etc/audit/rules.d/audit.rules

# Uncomment this line:
# -e 2  →  -e 2

# Reload
sudo augenrules --load
```

⚠️ After enabling `-e 2`, you MUST reboot to modify rules!

### Performance Tuning

**Low Impact:**
- Keep file watches only
- Remove syscall monitoring

**Moderate Impact:** (default)
- File watches + syscall monitoring for specific actions
- Filter by auid >= 1000

**High Impact:**
- Monitor all execve calls
- No auid filtering
- Monitor everything

Adjust in the rules file based on your needs.

---

## 🛠️ Troubleshooting

### Vim syntax not working?

```bash
# Run the installer
./install_vim_audit_syntax.sh

# Or quick setup
./quick_vim_setup.sh

# Manually enable in vim
:syntax on
:set filetype=audit
```

### Rules not loading?

```bash
# Check for syntax errors
sudo augenrules --check

# Check service status
sudo systemctl status auditd

# View service logs
sudo journalctl -u auditd -n 50

# Try manual load
sudo auditctl -R /etc/audit/rules.d/audit.rules
```

### No events in logs?

```bash
# Verify rules are active
sudo auditctl -l

# Check daemon status
sudo auditctl -s

# Test manually
sudo auditctl -w /tmp/test -p wa -k testkey
touch /tmp/test
sudo ausearch -k testkey
```

### Too many log entries?

```bash
# Check log size
du -sh /var/log/audit/

# Increase auid filter (only monitor regular users)
# Edit rules, change from:
-F auid>=1000
# To:
-F auid>=1000 -F auid<=60000

# Or remove execve monitoring if too verbose
```

---

## 📖 Files Reference

| File | Purpose | Usage |
|------|---------|-------|
| `audit.rules` | Main ruleset | Deploy to /etc/audit/rules.d/ |
| `load_and_test_audit_rules.sh` | Load & test | Run after deploying rules |
| `audit_hardening_check.sh` | Compliance check | Verify configuration |
| `deploy_audit_hardening.sh` | Full deployment | Complete setup automation |
| `audit.vim` | Vim syntax | Copy to ~/.vim/syntax/ |
| `install_vim_audit_syntax.sh` | Vim installer | Automatic syntax setup |
| `quick_vim_setup.sh` | Quick vim fix | One-command syntax install |
| `AUDIT_QUICK_START.md` | Quick reference | Command cheatsheet |
| `VIM_SYNTAX_SETUP.md` | Vim guide | Detailed vim instructions |

---

## 🎯 Common Tasks

### Edit Rules with Syntax Highlighting

```bash
# Setup vim first
./quick_vim_setup.sh

# Edit system rules
sudo vim /etc/audit/rules.d/audit.rules

# Edit local copy
vim etc/audit/rules.d/audit.rules
```

### Load New Rules

```bash
# Best method (uses rules.d/)
sudo augenrules --load

# Alternative (direct)
sudo auditctl -R /etc/audit/rules.d/audit.rules

# Or restart service
sudo systemctl restart auditd
```

### Check What Changed

```bash
# Show recent activity
sudo ausearch -ts today | aureport -f

# Show by user
sudo ausearch -ts today | aureport -u

# Show failed access
sudo ausearch -ts today -sv no
```

### Export Logs

```bash
# Export to file
sudo ausearch -ts today > audit_report_$(date +%Y%m%d).txt

# Summary report
sudo aureport --summary > audit_summary_$(date +%Y%m%d).txt

# JSON export (if ausearch supports it)
sudo ausearch -ts today --format json > audit_$(date +%Y%m%d).json
```

---

## 📞 Support

For issues or questions:
1. Check `AUDIT_QUICK_START.md` for commands
2. Check `VIM_SYNTAX_SETUP.md` for vim issues
3. Review troubleshooting section above
4. Check man pages: `man auditd`, `man auditctl`, `man ausearch`

---

## 📄 License

These audit configurations are provided as-is for security hardening purposes.
Adjust rules based on your specific compliance requirements (CIS, NIST, PCI-DSS, STIG).

---

**Quick Commands Summary:**

```bash
# Vim syntax
./quick_vim_setup.sh

# Deploy rules
sudo cp etc/audit/rules.d/audit.rules /etc/audit/rules.d/
sudo ./load_and_test_audit_rules.sh

# Check compliance
sudo ./audit_hardening_check.sh

# View logs
sudo ausearch -k privileged -ts recent
sudo aureport --summary
```

Happy auditing! 🔐
