#!/bin/bash

#############################################################################
# Debian Audit Hardening Check Script
# Purpose: Check auditd configuration and audit rules for security hardening
# Usage: sudo ./audit_hardening_check.sh
#############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNING=0

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

print_header() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
}

check_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNING++))
}

#############################################################################
# 1. Check auditd installation and service status
#############################################################################
print_header "1. Audit Daemon Installation and Status"

if dpkg -l | grep -q "^ii.*auditd"; then
    check_pass "auditd package is installed"
else
    check_fail "auditd package is NOT installed"
fi

if systemctl is-active --quiet auditd; then
    check_pass "auditd service is running"
else
    check_fail "auditd service is NOT running"
fi

if systemctl is-enabled --quiet auditd; then
    check_pass "auditd service is enabled at boot"
else
    check_fail "auditd service is NOT enabled at boot"
fi

#############################################################################
# 2. Check auditd configuration
#############################################################################
print_header "2. Audit Daemon Configuration"

if [ -f /etc/audit/auditd.conf ]; then
    check_pass "auditd configuration file exists"

    # Check max_log_file size
    max_log=$(grep "^max_log_file\s*=" /etc/audit/auditd.conf | awk '{print $3}')
    if [ ! -z "$max_log" ] && [ "$max_log" -ge 8 ]; then
        check_pass "max_log_file is set to ${max_log} MB (>= 8 MB recommended)"
    else
        check_warn "max_log_file is ${max_log:-not set} (>= 8 MB recommended)"
    fi

    # Check max_log_file_action
    max_action=$(grep "^max_log_file_action\s*=" /etc/audit/auditd.conf | awk '{print $3}')
    if [ "$max_action" = "keep_logs" ] || [ "$max_action" = "rotate" ]; then
        check_pass "max_log_file_action is set to '$max_action'"
    else
        check_warn "max_log_file_action is '${max_action:-not set}' (rotate/keep_logs recommended)"
    fi

    # Check space_left_action
    space_action=$(grep "^space_left_action\s*=" /etc/audit/auditd.conf | awk '{print $3}')
    if [ "$space_action" = "email" ] || [ "$space_action" = "syslog" ]; then
        check_pass "space_left_action is set to '$space_action'"
    else
        check_warn "space_left_action is '${space_action:-not set}' (email/syslog recommended)"
    fi

    # Check admin_space_left_action
    admin_action=$(grep "^admin_space_left_action\s*=" /etc/audit/auditd.conf | awk '{print $3}')
    if [ "$admin_action" = "halt" ] || [ "$admin_action" = "single" ]; then
        check_pass "admin_space_left_action is set to '$admin_action'"
    else
        check_warn "admin_space_left_action is '${admin_action:-not set}' (halt/single recommended)"
    fi
else
    check_fail "auditd configuration file NOT found"
fi

#############################################################################
# 3. Check audit rules
#############################################################################
print_header "3. Audit Rules Configuration"

# Check if audit rules file exists
if [ -f /etc/audit/rules.d/audit.rules ] || [ -f /etc/audit/audit.rules ]; then
    check_pass "Audit rules file exists"
else
    check_fail "Audit rules file NOT found"
fi

# Get active audit rules
ACTIVE_RULES=$(auditctl -l 2>/dev/null | wc -l)
if [ "$ACTIVE_RULES" -gt 0 ]; then
    check_pass "Active audit rules loaded: $ACTIVE_RULES"
else
    check_fail "No active audit rules loaded"
fi

#############################################################################
# 4. Check specific critical audit rules
#############################################################################
print_header "4. Critical Audit Rules"

# Check for time-change monitoring
if auditctl -l 2>/dev/null | grep -q "adjtimex\|settimeofday\|clock_settime"; then
    check_pass "Time change monitoring rules configured"
else
    check_fail "Time change monitoring rules NOT configured"
fi

# Check for user/group monitoring
if auditctl -l 2>/dev/null | grep -q "/etc/group\|/etc/passwd\|/etc/gshadow\|/etc/shadow"; then
    check_pass "User/group information monitoring configured"
else
    check_fail "User/group information monitoring NOT configured"
fi

# Check for network environment monitoring
if auditctl -l 2>/dev/null | grep -q "sethostname\|setdomainname\|/etc/hosts\|/etc/network"; then
    check_pass "Network environment monitoring configured"
else
    check_fail "Network environment monitoring NOT configured"
fi

# Check for login/logout monitoring
if auditctl -l 2>/dev/null | grep -q "/var/log/faillog\|/var/log/lastlog\|/var/log/tallylog"; then
    check_pass "Login/logout monitoring configured"
else
    check_fail "Login/logout monitoring NOT configured"
fi

# Check for session monitoring
if auditctl -l 2>/dev/null | grep -q "/var/run/utmp\|/var/log/wtmp\|/var/log/btmp"; then
    check_pass "Session monitoring configured"
else
    check_fail "Session monitoring NOT configured"
fi

# Check for permission modification monitoring
if auditctl -l 2>/dev/null | grep -q "chmod\|chown\|fchmod\|fchown\|setxattr"; then
    check_pass "Permission modification monitoring configured"
else
    check_fail "Permission modification monitoring NOT configured"
fi

# Check for unauthorized access attempts
if auditctl -l 2>/dev/null | grep -q "EACCES\|EPERM"; then
    check_pass "Unauthorized access attempt monitoring configured"
else
    check_fail "Unauthorized access attempt monitoring NOT configured"
fi

# Check for privileged command monitoring
if auditctl -l 2>/dev/null | grep -q "perm=x.*-F.*auid"; then
    check_pass "Privileged command monitoring configured"
else
    check_warn "Privileged command monitoring may not be configured"
fi

# Check for sudo usage monitoring
if auditctl -l 2>/dev/null | grep -q "/var/log/sudo.log\|/etc/sudoers"; then
    check_pass "Sudo usage monitoring configured"
else
    check_fail "Sudo usage monitoring NOT configured"
fi

# Check for kernel module monitoring
if auditctl -l 2>/dev/null | grep -q "init_module\|delete_module\|finit_module"; then
    check_pass "Kernel module loading/unloading monitoring configured"
else
    check_fail "Kernel module monitoring NOT configured"
fi

# Check for file deletion monitoring
if auditctl -l 2>/dev/null | grep -q "unlink\|rename\|rmdir"; then
    check_pass "File deletion monitoring configured"
else
    check_fail "File deletion monitoring NOT configured"
fi

# Check for system call auditing
if auditctl -l 2>/dev/null | grep -q "execve"; then
    check_pass "System call auditing (execve) configured"
else
    check_warn "System call auditing (execve) NOT configured"
fi

# Check for audit configuration immutability
if auditctl -l 2>/dev/null | grep -q "\-e 2"; then
    check_pass "Audit configuration is immutable (locked)"
else
    check_warn "Audit configuration is NOT immutable (add '-e 2' to lock it)"
fi

#############################################################################
# 5. Check grub audit configuration
#############################################################################
print_header "5. Kernel Audit Parameters"

if [ -f /etc/default/grub ]; then
    if grep -q "audit=1" /etc/default/grub; then
        check_pass "Kernel audit parameter 'audit=1' found in grub config"
    else
        check_fail "Kernel audit parameter 'audit=1' NOT found in grub config"
    fi

    if grep -q "audit_backlog_limit=" /etc/default/grub; then
        backlog=$(grep "audit_backlog_limit=" /etc/default/grub | grep -o 'audit_backlog_limit=[0-9]*' | cut -d'=' -f2)
        if [ ! -z "$backlog" ] && [ "$backlog" -ge 8192 ]; then
            check_pass "audit_backlog_limit set to $backlog (>= 8192 recommended)"
        else
            check_warn "audit_backlog_limit is $backlog (>= 8192 recommended)"
        fi
    else
        check_warn "audit_backlog_limit NOT set in grub config (>= 8192 recommended)"
    fi
else
    check_warn "Grub configuration file not found"
fi

#############################################################################
# 6. Check log file permissions
#############################################################################
print_header "6. Audit Log Security"

if [ -d /var/log/audit ]; then
    check_pass "Audit log directory exists"

    dir_perms=$(stat -c %a /var/log/audit)
    if [ "$dir_perms" = "750" ] || [ "$dir_perms" = "700" ]; then
        check_pass "Audit log directory permissions are secure ($dir_perms)"
    else
        check_warn "Audit log directory permissions are $dir_perms (750 or 700 recommended)"
    fi

    if [ -f /var/log/audit/audit.log ]; then
        file_perms=$(stat -c %a /var/log/audit/audit.log)
        if [ "$file_perms" = "600" ] || [ "$file_perms" = "640" ]; then
            check_pass "Audit log file permissions are secure ($file_perms)"
        else
            check_warn "Audit log file permissions are $file_perms (600 or 640 recommended)"
        fi
    fi
else
    check_fail "Audit log directory NOT found"
fi

#############################################################################
# Summary
#############################################################################
print_header "Summary"

TOTAL=$((PASSED + FAILED + WARNING))
echo "Total Checks: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNING${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNING -eq 0 ]; then
    echo -e "${GREEN}All audit hardening checks passed!${NC}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}Audit configuration is good but has some warnings.${NC}"
    exit 0
else
    echo -e "${RED}Audit hardening needs attention. Please review failed checks.${NC}"
    exit 1
fi
