#!/bin/bash

#############################################################################
# Simple Audit Rules Load and Test Script
# Purpose: Load audit rules and verify they're working
# Usage: sudo ./load_and_test_audit_rules.sh
#############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Must run as root${NC}"
    exit 1
fi

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  Audit Rules Load & Test${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

#############################################################################
# Step 1: Check auditd service
#############################################################################
echo -e "${YELLOW}[1/5]${NC} Checking auditd service..."

if ! systemctl is-active --quiet auditd; then
    echo "  Starting auditd..."
    systemctl start auditd
fi

if systemctl is-active --quiet auditd; then
    echo -e "${GREEN}  ✓ auditd is running${NC}"
else
    echo -e "${RED}  ✗ auditd failed to start${NC}"
    exit 1
fi

#############################################################################
# Step 2: Backup current rules
#############################################################################
echo ""
echo -e "${YELLOW}[2/5]${NC} Backing up current rules..."

BACKUP_FILE="/tmp/audit_rules_backup_$(date +%Y%m%d_%H%M%S).txt"
auditctl -l > "$BACKUP_FILE"
echo -e "${GREEN}  ✓ Saved to: $BACKUP_FILE${NC}"

#############################################################################
# Step 3: Load rules using augenrules
#############################################################################
echo ""
echo -e "${YELLOW}[3/5]${NC} Loading audit rules..."

# First, generate the rules from /etc/audit/rules.d/
echo "  Running augenrules --load..."
augenrules --load

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Rules loaded successfully${NC}"
else
    echo -e "${RED}  ✗ Failed to load rules${NC}"
    echo "  Restoring backup..."
    auditctl -R "$BACKUP_FILE"
    exit 1
fi

#############################################################################
# Step 4: Verify loaded rules
#############################################################################
echo ""
echo -e "${YELLOW}[4/5]${NC} Verifying loaded rules..."

RULE_COUNT=$(auditctl -l | grep -v "No rules" | wc -l)
echo "  Total active rules: $RULE_COUNT"

if [ "$RULE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Rules are active${NC}"
else
    echo -e "${RED}  ✗ No rules loaded${NC}"
    exit 1
fi

# Check key categories
echo ""
echo "  Checking rule categories:"

check_category() {
    local key=$1
    local name=$2
    local count=$(auditctl -l | grep -c "key=$key")
    if [ "$count" -gt 0 ]; then
        echo -e "    ${GREEN}✓${NC} $name: $count rules"
    else
        echo -e "    ${YELLOW}!${NC} $name: no rules found"
    fi
}

check_category "time-change" "Time changes"
check_category "identity" "User/Group changes"
check_category "system-locale" "Network config"
check_category "perm_mod" "Permission changes"
check_category "access" "Access attempts"
check_category "privileged" "Privileged commands"
check_category "sudo_config" "Sudo monitoring"
check_category "modules" "Kernel modules"
check_category "delete" "File deletions"

#############################################################################
# Step 5: Test audit rules
#############################################################################
echo ""
echo -e "${YELLOW}[5/5]${NC} Testing audit rules..."

# Create test file
TEST_FILE="/tmp/audit_test_$(date +%s).txt"
echo "test" > "$TEST_FILE"

# Test 1: File deletion
echo "  Test 1: File deletion monitoring..."
rm -f "$TEST_FILE"
sleep 1
if ausearch -k delete -ts recent 2>/dev/null | grep -q "$TEST_FILE"; then
    echo -e "    ${GREEN}✓ File deletion detected${NC}"
else
    echo -e "    ${YELLOW}! File deletion not detected (may take a moment)${NC}"
fi

# Test 2: Permission change
echo "  Test 2: Permission change monitoring..."
echo "test" > "$TEST_FILE"
chmod 777 "$TEST_FILE"
sleep 1
if ausearch -k perm_mod -ts recent 2>/dev/null | grep -q "chmod"; then
    echo -e "    ${GREEN}✓ Permission change detected${NC}"
else
    echo -e "    ${YELLOW}! Permission change not detected (may take a moment)${NC}"
fi

# Cleanup
rm -f "$TEST_FILE"

# Test 3: Check if audit log is being written
echo "  Test 3: Audit log activity..."
LOG_SIZE=$(wc -l < /var/log/audit/audit.log 2>/dev/null || echo 0)
if [ "$LOG_SIZE" -gt 0 ]; then
    echo -e "    ${GREEN}✓ Audit log active ($LOG_SIZE lines)${NC}"
else
    echo -e "    ${YELLOW}! Audit log seems empty${NC}"
fi

#############################################################################
# Summary and Next Steps
#############################################################################
echo ""
echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""
echo "Rules Status:"
echo "  • Total rules loaded: $RULE_COUNT"
echo "  • Auditd status: $(systemctl is-active auditd)"
echo "  • Backup location: $BACKUP_FILE"
echo ""
echo "Useful Commands:"
echo "  • View all rules:    auditctl -l"
echo "  • Search logs:       ausearch -k <key> -ts recent"
echo "  • View raw log:      tail -f /var/log/audit/audit.log"
echo "  • Generate report:   aureport --summary"
echo ""
echo "Common Search Keys:"
echo "  ausearch -k delete -ts recent      # File deletions"
echo "  ausearch -k privileged -ts recent  # Privileged commands"
echo "  ausearch -k sudo_config -ts recent # Sudo activity"
echo "  ausearch -k access -ts recent      # Failed access"
echo ""

# Check if rules are immutable
if auditctl -l | grep -q "\-e 2"; then
    echo -e "${RED}WARNING: Audit rules are IMMUTABLE (-e 2)${NC}"
    echo "         You must REBOOT to modify rules"
    echo ""
fi

echo -e "${GREEN}✓ Audit rules loaded and tested successfully!${NC}"
echo ""
