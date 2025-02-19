#!/bin/bash
# security-hardening.sh - System Hardening Script
# License: AGPL-3.0
#
# This script applies security best practices to harden a Linux system.
# It disables unnecessary services, configures firewall rules, and enforces security policies.
#
# Supported OS: Ubuntu, Debian
#
# Usage: Run as root: `sudo bash security-hardening.sh`
#
# Author: ankaboot.io

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m' # No Color

# Function to prompt user to continue
prompt() {
    read -p "${GREEN}$1 (Press any key to continue or Ctrl+C to exit)...${NC}" -n1 -s
    echo ""
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

# Warning about disabling root access
echo "${YELLOW}Warning: This script will disable root SSH access. Ensure you have another accessible user with sudo privileges.${NC}"
prompt "Do you want to continue?"

# Disable root SSH login
sed -i 's/^PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "Root SSH access disabled."
prompt "Next: Disable SSH forwarding"

# Disable SSH Forwarding
sed -i '/AllowTcpForwarding/c\AllowTcpForwarding no' /etc/ssh/sshd_config
sed -i '/X11Forwarding/c\X11Forwarding no' /etc/ssh/sshd_config
systemctl restart ssh

echo "SSH forwarding disabled."
prompt "Next: Add Swap Memory"

if swapon --show | grep -q "/swapfile"; then
    echo "Swap memory is already available. Moving to next step."
else
    # Ask user for swap size (default 2GB)
    read -p "Enter the amount of swap memory to allocate 1G, 2G, 3G... (default is 2G): " swap_size
    swap_size=${swap_size:-2G}

    # Add Swap Memory
    fallocate -l $swap_size /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    bash -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
    echo "Swap memory of $swap_size added."
fi

prompt "Next: Enable TCP-SYNcookie protection"

# Enable TCP-SYNcookie protection
sysctl -w net.ipv4.tcp_syncookies=1
bash -c 'echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf'
sysctl -p

echo "TCP-SYNcookie protection enabled."

# Ask user about installing ClamAV
read -p "${GREEN}Would you like to install ClamAV? (y/n)${NC} ${RED}(PS: DON'T INSTALL IT IF YOU GOT LESS THAN 4GB TOTAL RAM):  ${NC}" install_clamav
if [[ "$install_clamav" =~ ^[Yy]$ ]]; then
    apt update && apt install -y clamav
    systemctl enable clamav-freshclam
    systemctl start clamav-freshclam
    # Conserve resources by disabling TestDatabase
    sed -i 's/^TestDatabases yes/TestDatabases no/' /etc/clamav/freshclam.conf
    systemctl restart clamav-freshclam

    # Create ClamAV scan script
    cat <<EOF > /root/clamav.sh
#!/bin/bash
QUARANTINE="/tmp/quarantine"
LOG="/var/log/clamav/scan.log"
rm /var/log/clamav/freshclam.log
freshclam
clamscan -r --move="\$QUARANTINE" / >> "\$LOG"
EOF
    chmod +x /root/clamav.sh

    echo "0 2 * * * bash /root/clamav.sh" >> /etc/crontab
    echo "ClamAV installed and scheduled."
fi

# Install Rkhunter
read -p "${GREEN}Would you like to install Rkhunter? (y/n):${NC} " install_rkhunter
if [[ "$install_rkhunter" =~ ^[Yy]$ ]]; then
    apt install -y rkhunter
    echo "0 5 * * * rkhunter -c --sk --rwo" >> /etc/crontab
    echo "Rkhunter installed and scheduled."
fi

# Install Lynis
read -p "${GREEN}Would you like to install Lynis? (y/n): ${NC}" install_lynis
if [[ "$install_lynis" =~ ^[Yy]$ ]]; then
    apt install -y lynis
    echo "0 23 * * * lynis audit system | tee -a /var/log/lynis.scan " >> /etc/crontab
    echo "Lynis installed and scheduled."
fi

# Install Debsums
read -p "${GREEN}Would you like to install Debsums? (y/n): ${NC}" install_debsums
if [[ "$install_debsums" =~ ^[Yy]$ ]]; then
    echo "Installing Debsums..."
    apt install -y debsums
    echo "Debsums installed. You can run 'debsums -s' to check package integrity."
    echo "Security hardening completed successfully!"
fi
