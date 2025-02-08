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

log("\n\n\nUpdate sshd_config")
sed -i "s|^#ClientAliveInterval.*|ClientAliveInterval 300|" /etc/ssh/sshd_config
sed -i "s|^#ClientAliveCountMax.*|ClientAliveCountMax 3|" /etc/ssh/sshd_config
systemctl restart ssh

# Update package index
log "\n\n\nUpdate package index"
apt update >> /tmp/launchscript.log

# Upgrade packages
log "\n\n\nUpgrade packages"
apt-get upgrade -y >> /tmp/launchscript.log

# Installing dialog package... 
log "\n\n\nInstalling dialog package..."
sudo apt-get install dialog -y >> /tmp/launchscript.log

# Installing Python packages... 
log "\n\n\nInstalling Python packages..."
apt install -y python3-dev python3-pip python3-wheel python3-venv python3-setuptools >> /tmp/launchscript.log

# Installing system dependencies... 
log "\n\n\nInstalling system dependencies..."
apt install -y libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev \
    libpq-dev >> /tmp/launchscript.log

# Install common dependencies
log "Install common dependencies..."
apt install -y git build-essential wget postgresql node-less >> /tmp/launchscript.log

log "\n\n\nPreinstallation Completed........\n\n"

exit 0