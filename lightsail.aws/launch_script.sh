#!/bin/bash

# Exit script on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display messages
log() {
    # # echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}"

    # Check if the first argument is "-nodate"
    if [[ "$1" == "-nodate" ]]; then
        shift  # Remove the first argument (-nodate)
        echo -e "${GREEN}$@${NC}"
    else
        echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@${NC}"
    fi
}


# Create the log file
touch /tmp/launchscript.log

# Add text to the log file if you so choose
echo 'Starting' >> /tmp/launchscript.log

sudo su

log "\n\n\nUpdate sshd_config" >> /tmp/launchscript.log
sed -i "s|^#ClientAliveInterval.*|ClientAliveInterval 300|" /etc/ssh/sshd_config
sed -i "s|^#ClientAliveCountMax.*|ClientAliveCountMax 3|" /etc/ssh/sshd_config
systemctl restart ssh

# Update package index
log "\n\n\nUpdate package index" >> /tmp/launchscript.log
apt update >> /tmp/launchscript.log

# Upgrade packages
log "\n\n\nUpgrade packages" >> /tmp/launchscript.log
apt-get upgrade -y >> /tmp/launchscript.log

# Installing dialog package... 
log "\n\n\nInstalling dialog package..." >> /tmp/launchscript.log
sudo apt-get install dialog -y >> /tmp/launchscript.log

# Installing Python packages... 
log "\n\n\nInstalling Python packages..." >> /tmp/launchscript.log
apt install -y python3-dev python3-pip python3-wheel python3-venv python3-setuptools >> /tmp/launchscript.log

# Installing system dependencies... 
log "\n\n\nInstalling system dependencies..." >> /tmp/launchscript.log
apt install -y libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev \
    libpq-dev curl wget >> /tmp/launchscript.log

# Install common dependencies
log "Install common dependencies..." >> /tmp/launchscript.log
apt install -y git build-essential wget postgresql node-less >> /tmp/launchscript.log

# Define the installation directory
INSTALL_DIR="/InstallScript"
log "Installation directory: $INSTALL_DIR" >> /tmp/launchscript.log

# Create the directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Change ownership to the Ubuntu user (in case script runs as root)
chown ubuntu:ubuntu "$INSTALL_DIR" >> /tmp/launchscript.log

# Download the script using wget (or curl)
wget -O "$INSTALL_DIR/install_odoo.sh" "https://raw.githubusercontent.com/princeppy/odoo-install-scripts/main/install_odoo.sh" >> /tmp/launchscript.log

# Make the script executable
chmod +x "$INSTALL_DIR/install_odoo.sh"

# Print success message
log "✅ Odoo install script downloaded to $INSTALL_DIR and made executable!" >> /tmp/launchscript.log

log "\n\n\nPreinstallation Completed........\n\n" >> /tmp/launchscript.log

exit 0