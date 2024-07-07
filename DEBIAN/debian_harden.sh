

# 0001 - Ensure at/cron is restricted to authorized users
#  File /etc/cron.deny should not exist
# N/A


# 0002 - Ensure mounting of USB storage devices is disabled
#Audit lines matching '^install\s+usb-storage\s+/bin/true' in /etc/modprobe.d/

# Step 1: Blacklist USB Storage Module
echo "Blacklisting usb_storage module..."
echo "blacklist usb_storage" >> /etc/modprobe.d/blacklist.conf

# Step 2: Update Initramfs
echo "Updating initramfs..."
update-initramfs -u

# 0003 - Disable the installation and use of file systems that are not required (cramfs)
# files with lines matching '^install\s+cramfs\s+/bin/true' in /etc/modprobe.d/


# 0017 - Ensure packet redirect sending is disabled.
# Audit sysctl -a' to match '^net\.ipv4\.conf\.default\.send_redirects\s*=\s*0\s*$'
# Check the current setting
current_setting=$(sysctl net.ipv4.conf.default.send_redirects | awk '{print $3}')

if [ "$current_setting" -ne "0" ]; then
  # Set the parameter to 0 if it's not already
  echo "Setting net.ipv4.conf.default.send_redirects to 0..."
  sysctl -w net.ipv4.conf.default.send_redirects=0
  
  # Check if the configuration is already in /etc/sysctl.conf or in any file in /etc/sysctl.d/
  conf_file_found=$(grep -Els "^net\.ipv4\.conf\.default\.send_redirects\s*=\s*0\s*$" /etc/sysctl.conf /etc/sysctl.d/* || true)
  
  if [ -z "$conf_file_found" ]; then
    # If the setting is not preserved, add it to sysctl.conf
    echo "Preserving setting across reboots in /etc/sysctl.conf..."
    echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
  else
    echo "Setting is already preserved in $conf_file_found"
  fi
else
  echo "net.ipv4.conf.default.send_redirects is already set to 0."
fi


# [] the system should not permit source routing from incoming packets
sysctl -a | grep net.ipv4.conf | grep source_route
current_setting=$(sysctl net.ipv4.conf.default.accept_source_route | awk '{print $3}')
### net.ipv4.conf.all.accept_source_route = 0
### net.ipv4.conf.default.accept_source_route = 0

echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route