#!/bin/bash

#############################################################################
# Audit Hardening Deployment Script for Debian
# Purpose: Deploy comprehensive audit configuration and fix common issues
# Usage: sudo ./deploy_audit_hardening.sh
#############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Audit Hardening Deployment Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

#############################################################################
# 1. Install auditd if not present
#############################################################################
echo -e "${YELLOW}[STEP 1]${NC} Checking auditd installation..."

if ! dpkg -l | grep -q "^ii.*auditd"; then
    echo "  Installing auditd..."
    apt-get update
    apt-get install -y auditd audispd-plugins
    echo -e "${GREEN}  ✓ auditd installed${NC}"
else
    echo -e "${GREEN}  ✓ auditd already installed${NC}"
fi

#############################################################################
# 2. Backup existing configuration
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 2]${NC} Backing up existing configuration..."

BACKUP_DIR="/root/audit_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f /etc/audit/auditd.conf ]; then
    cp /etc/audit/auditd.conf "$BACKUP_DIR/"
    echo -e "${GREEN}  ✓ Backed up auditd.conf${NC}"
fi

if [ -f /etc/audit/rules.d/audit.rules ]; then
    cp /etc/audit/rules.d/audit.rules "$BACKUP_DIR/"
    echo -e "${GREEN}  ✓ Backed up audit.rules${NC}"
fi

if [ -f /etc/audit/audit.rules ]; then
    cp /etc/audit/audit.rules "$BACKUP_DIR/"
    echo -e "${GREEN}  ✓ Backed up /etc/audit/audit.rules${NC}"
fi

echo "  Backup location: $BACKUP_DIR"

#############################################################################
# 3. Configure auditd.conf
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 3]${NC} Configuring auditd.conf..."

if [ -f /etc/audit/auditd.conf ]; then
    # Configure log file settings
    sed -i 's/^max_log_file\s*=.*/max_log_file = 32/' /etc/audit/auditd.conf
    sed -i 's/^num_logs\s*=.*/num_logs = 10/' /etc/audit/auditd.conf
    sed -i 's/^max_log_file_action\s*=.*/max_log_file_action = rotate/' /etc/audit/auditd.conf

    # Configure space management
    sed -i 's/^space_left_action\s*=.*/space_left_action = email/' /etc/audit/auditd.conf
    sed -i 's/^admin_space_left_action\s*=.*/admin_space_left_action = halt/' /etc/audit/auditd.conf
    sed -i 's/^disk_full_action\s*=.*/disk_full_action = halt/' /etc/audit/auditd.conf
    sed -i 's/^disk_error_action\s*=.*/disk_error_action = halt/' /etc/audit/auditd.conf

    # Configure email alerts (set appropriate email)
    sed -i 's/^action_mail_acct\s*=.*/action_mail_acct = root/' /etc/audit/auditd.conf

    # Flush settings
    sed -i 's/^flush\s*=.*/flush = INCREMENTAL_ASYNC/' /etc/audit/auditd.conf

    echo -e "${GREEN}  ✓ auditd.conf configured${NC}"
else
    echo -e "${RED}  ✗ auditd.conf not found${NC}"
fi

#############################################################################
# 4. Deploy audit rules
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 4]${NC} Deploying audit rules..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RULES_SOURCE="$SCRIPT_DIR/etc/audit/audit.rules"

if [ -f "$RULES_SOURCE" ]; then
    # Copy to rules.d directory (preferred location)
    cp "$RULES_SOURCE" /etc/audit/rules.d/audit.rules
    chmod 640 /etc/audit/rules.d/audit.rules
    echo -e "${GREEN}  ✓ Deployed audit rules to /etc/audit/rules.d/audit.rules${NC}"

    # Generate privileged command rules dynamically
    echo "  Generating privileged command rules..."
    PRIV_RULES="/etc/audit/rules.d/privileged.rules"
    echo "# Automatically generated privileged command rules" > "$PRIV_RULES"
    echo "# Generated on: $(date)" >> "$PRIV_RULES"

    find /bin /usr/bin /sbin /usr/sbin /usr/local/bin /usr/local/sbin -type f -perm /6000 2>/dev/null | \
    while read cmd; do
        echo "-a always,exit -F path=$cmd -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged" >> "$PRIV_RULES"
    done

    echo -e "${GREEN}  ✓ Generated privileged command rules${NC}"
else
    echo -e "${RED}  ✗ Source audit.rules not found at: $RULES_SOURCE${NC}"
    echo "     Please ensure the audit.rules file is in etc/audit/ relative to this script"
fi

#############################################################################
# 5. Configure GRUB for audit
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 5]${NC} Configuring GRUB kernel parameters..."

if [ -f /etc/default/grub ]; then
    # Backup grub config
    cp /etc/default/grub "$BACKUP_DIR/"

    # Add or update audit parameters
    if grep -q "GRUB_CMDLINE_LINUX=" /etc/default/grub; then
        # Check if audit parameters already exist
        if ! grep "GRUB_CMDLINE_LINUX=" /etc/default/grub | grep -q "audit=1"; then
            # Add audit=1 and audit_backlog_limit
            sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 audit=1 audit_backlog_limit=8192"/' /etc/default/grub
            # Clean up potential double spaces
            sed -i 's/GRUB_CMDLINE_LINUX=" /GRUB_CMDLINE_LINUX="/' /etc/default/grub
            echo -e "${GREEN}  ✓ Added audit parameters to GRUB${NC}"

            echo "  Updating GRUB configuration..."
            update-grub
            echo -e "${YELLOW}  ! Reboot required for kernel parameters to take effect${NC}"
        else
            echo -e "${GREEN}  ✓ Audit parameters already present in GRUB${NC}"
        fi
    fi
else
    echo -e "${YELLOW}  ! GRUB configuration not found (may not be applicable)${NC}"
fi

#############################################################################
# 6. Set proper permissions
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 6]${NC} Setting proper permissions..."

# Audit log directory
if [ -d /var/log/audit ]; then
    chmod 750 /var/log/audit
    echo -e "${GREEN}  ✓ Set /var/log/audit permissions to 750${NC}"
fi

# Audit log files
if [ -f /var/log/audit/audit.log ]; then
    chmod 600 /var/log/audit/audit.log
    echo -e "${GREEN}  ✓ Set audit.log permissions to 600${NC}"
fi

# Audit configuration
chmod 640 /etc/audit/auditd.conf
chmod 640 /etc/audit/rules.d/*.rules 2>/dev/null
echo -e "${GREEN}  ✓ Set configuration file permissions${NC}"

#############################################################################
# 7. Load audit rules
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 7]${NC} Loading audit rules..."

# Load the rules
augenrules --load
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Audit rules loaded successfully${NC}"
else
    echo -e "${RED}  ✗ Failed to load audit rules${NC}"
fi

# Show number of loaded rules
RULE_COUNT=$(auditctl -l | wc -l)
echo "  Total active rules: $RULE_COUNT"

#############################################################################
# 8. Enable and restart auditd
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 8]${NC} Enabling and restarting auditd service..."

systemctl enable auditd
systemctl restart auditd

if systemctl is-active --quiet auditd; then
    echo -e "${GREEN}  ✓ auditd service is running${NC}"
else
    echo -e "${RED}  ✗ auditd service failed to start${NC}"
fi

#############################################################################
# 9. Create audit report helper script
#############################################################################
echo ""
echo -e "${YELLOW}[STEP 9]${NC} Creating audit report helper script..."

cat > /usr/local/bin/audit-report << 'EOF'
#!/bin/bash
# Quick audit report generator

echo "Audit Summary Report - $(date)"
echo "======================================"
echo ""
echo "Recent Failed Access Attempts:"
ausearch -k access -ts recent 2>/dev/null | grep -i denied | tail -10
echo ""
echo "Recent Privilege Escalations:"
ausearch -k priv_esc -ts recent 2>/dev/null | tail -10
echo ""
echo "Recent Sudo Commands:"
ausearch -k sudo_config -ts recent 2>/dev/null | tail -10
echo ""
echo "Recent File Deletions:"
ausearch -k delete -ts recent 2>/dev/null | tail -10
echo ""
echo "Active Audit Rules:"
auditctl -l | wc -l
echo ""
echo "Audit Log Size:"
du -sh /var/log/audit/
EOF

chmod +x /usr/local/bin/audit-report
echo -e "${GREEN}  ✓ Created /usr/local/bin/audit-report${NC}"

#############################################################################
# Summary
#############################################################################
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓ Audit hardening has been deployed${NC}"
echo ""
echo "Next Steps:"
echo "1. Review the configuration in /etc/audit/"
echo "2. ${YELLOW}REBOOT the system${NC} to activate kernel audit parameters"
echo "3. Run the check script: ./audit_hardening_check.sh"
echo "4. Generate reports with: audit-report"
echo ""
echo "To make audit configuration immutable (prevent runtime changes):"
echo "  Uncomment '-e 2' at the end of /etc/audit/rules.d/audit.rules"
echo "  Then reload: augenrules --load"
echo "  ${RED}Warning: System reboot required to modify rules after this!${NC}"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
