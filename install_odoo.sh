#!/bin/bash

# Odoo Installation Script
# Author: Prince PARK
# Inspired From: https://github.com/moaaz1995/odoo-install-script (Moaaz Gafar)
# Created: 2025
# Description: Automated installation script for Odoo (versions 12.0+) on Ubuntu systems
# Repository: https://github.com/princeppy/odoo-install-scripts
#
# This script is provided under MIT License
# Copyright (c) 2024 Moaaz Gafar

# Usage: sudo bash install_odoo.sh
# Example: sudo bash install_odoo.sh

clear 

# Exit script on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display messages
log() {    
    # Check if the first argument is "-nodate"
    if [[ "$1" == "-nodate" ]]; then
        shift  # Remove the first argument (-nodate)
        echo -e "${GREEN}$@${NC}"
    else
        echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@${NC}"
    fi
}
error() {
    echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $1${NC}"
}

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)

# Function to check and install package
install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        apt install -y "$1"
    else 
        warning "$1 package already exist !!!"
    fi
}

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to handle package manager locks
handle_locks() {
    log "Handling package manager locks..."
    killall apt apt-get 2>/dev/null || true
    rm /var/lib/apt/lists/lock 2>/dev/null || true
    rm /var/cache/apt/archives/lock 2>/dev/null || true
    rm /var/lib/dpkg/lock* 2>/dev/null || true
    dpkg --configure -a
}

TEMP_FILE=$(mktemp)

# Function to clean the TEMP_FILE before each dialog
clean_temp() {
    : > "$TEMP_FILE"  # Clears file contents without deleting it
}

log "Welcome to Odoo setup"

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (sudo)"
    exit 1
fi

clean_temp
dialog --clear --title "Odoo Setup - Powered by Prince" \
    --default-item "17.0" \
    --menu "Select an Odoo Version:" 12 50 3 \
    "16.0" "Odoo 16.0" \
    "17.0" "Odoo 17.0" \
    "18.0" "Odoo 18.0" 2>$TEMP_FILE

ODOO_VERSION=$(<"$TEMP_FILE")

clean_temp
dialog --title "Odoo Setup - Powered by Prince" --inputbox "Odoo Username" 8 50 "odoo" 2>$TEMP_FILE
OE_USER=$(<"$TEMP_FILE")
OE_HOME="/$OE_USER"

clean_temp
dialog --title "Odoo Setup - Powered by Prince" --inputbox "${OE_USER} Home Folder" 8 50 "${OE_HOME}" 2>$TEMP_FILE
OE_HOME=$(<"$TEMP_FILE")

clean_temp
dialog --title "Odoo Setup - Powered by Prince" --inputbox "Odoo Master Password" 8 50 "admin" 2>$TEMP_FILE
OE_MASTER_PASSWORD=$(<"$TEMP_FILE")

clear

log "Odoo User: ${OE_USER}"
log "Odoo User Home: ${OE_HOME}"
log "Odoo version: ${ODOO_VERSION}"

if [ -z "$ODOO_VERSION" ]; then
    error "Invalid Odoo Version"
    exit 1
fi

if systemctl is-active --quiet "odoo-${ODOO_VERSION}"; then
    echo "🚀 Stopping odoo-${ODOO_VERSION} service..."
    sudo systemctl stop "odoo-${ODOO_VERSION}"
    echo "✅ odoo-${ODOO_VERSION} service stopped."
fi

# Install common dependencies
log "Installing common dependencies..."
COMMON_PACKAGES="git build-essential wget postgresql node-less"
for package in $COMMON_PACKAGES; do
    install_package $package
done

# Install wkhtmltopdf based on Ubuntu version
log "Installing wkhtmltopdf..."
if version_gt $UBUNTU_VERSION "22.04"; then
    install_package wkhtmltopdf
else
    if ! dpkg -l | grep -q "^ii  wkhtmltopdf "; then
        # For older Ubuntu versions, install from website
        wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
        apt install -y ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb
        rm wkhtmltox_0.12.6.1-2.jammy_amd64.deb    
    else 
        warning "wkhtmltopdf package already exist !!!"
    fi
fi

# Check if the user "odoo" exists, if not, create it
if id "odoo" &>/dev/null; then
    warning "✅ Odoo user already exists."
else
    log "🚀 Creating Odoo user..."
    useradd -m -d $OE_HOME -U -r -s /bin/bash $OE_USER && log "✅ $OE_USER user created successfully." || log "❌ Failed to create $OE_USER user!"
fi

# Check if the PostgreSQL user "odoo" exists, if not, create it
if su - postgres -c "psql -tAc \"SELECT 1 FROM pg_user WHERE usename = '$OE_USER'\"" | grep -q 1; then
    warning "✅ PostgreSQL user '$OE_USER' already exists."
else
    log "🚀 Creating PostgreSQL user '$OE_USER'..."
    su - postgres -c "createuser -s $OE_USER" && log "✅ PostgreSQL user '$OE_USER' created successfully." || log "❌ Failed to create PostgreSQL user '$OE_USER'!"
fi

# Directory structure
log "Creating directory structure..."
mkdir -p $OE_HOME
mkdir -p /var/log/odoo
mkdir -p /etc/odoo
chown -R $OE_USER:$OE_USER $OE_HOME
chown -R $OE_USER:$OE_USER /var/log/odoo
chown -R $OE_USER:$OE_USER /etc/odoo

# Clone Odoo
log "Cloning ${OE_USER} ${ODOO_VERSION}..."
if [ ! -d "${OE_HOME}/odoo-${ODOO_VERSION}" ]; then
    su - ${OE_USER} -c "git clone --depth 1 --branch ${ODOO_VERSION} https://github.com/odoo/odoo ${OE_HOME}/odoo-${ODOO_VERSION}"
    # else
    #     log "Updating existing Odoo installation..."
    #     su - ${OE_USER} -c "cd ${OE_HOME}/odoo-${ODOO_VERSION} && git pull"
fi

# Setup virtual environment
# log "Setting up Python virtual environment..."
# su - ${OE_USER} -c "python3 -m venv ${OE_HOME}/odoo-${ODOO_VERSION}-venv"
if [ ! -d "${OE_HOME}/odoo-${ODOO_VERSION}-venv" ]; then
    log "🚀 Creating Python Virtual Environment..."
    su - ${OE_USER} -c "python3 -m venv ${OE_HOME}/odoo-${ODOO_VERSION}-venv"
    log "✅ Virtual Environment created successfully."
else
    log "⚠️ Virtual Environment already exists, skipping creation."
fi
VENV_PATH="${OE_HOME}/odoo-${ODOO_VERSION}-venv"
VENV_PYTHON="${VENV_PATH}/bin/python3"
VENV_PIP="${VENV_PATH}/bin/pip"

# Install Python dependencies
log "Installing Python packages in virtual environment..."
su - ${OE_USER} -c "${VENV_PIP} install wheel"
su - ${OE_USER} -c "cd ${OE_HOME}/odoo-${ODOO_VERSION} && ${VENV_PIP} install -r requirements.txt"

# Create Odoo config
log "Creating Odoo configuration..."
cat > /etc/odoo/odoo-${ODOO_VERSION}.conf << EOF
[options]
admin_passwd = ${OE_MASTER_PASSWORD}
db_host = False
db_port = False
db_user = ${OE_USER}
db_password = False
addons_path = ${OE_HOME}/odoo-${ODOO_VERSION}/addons
logfile = /var/log/odoo/odoo-${ODOO_VERSION}.log
http_port = 8069
EOF

chown ${OE_USER}:${OE_USER} /etc/odoo/odoo-${ODOO_VERSION}.conf
chmod 640 /etc/odoo/odoo-${ODOO_VERSION}.conf

# Create systemd service
log "Creating systemd service..."
cat > /etc/systemd/system/odoo-${ODOO_VERSION}.service << EOF
[Unit]
Description=Odoo ${ODOO_VERSION}
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo-${ODOO_VERSION}
PermissionsStartOnly=true
User=${OE_USER}
Group=${OE_USER}
Environment="PATH=${VENV_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=${VENV_PYTHON} ${OE_HOME}/odoo-${ODOO_VERSION}/odoo-bin -c /etc/odoo/odoo-${ODOO_VERSION}.conf
StandardOutput=journal+console
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 755 /etc/systemd/system/odoo-${ODOO_VERSION}.service
systemctl daemon-reload

# Start and enable Odoo service
log "Starting Odoo service..."
systemctl start odoo-${ODOO_VERSION}
systemctl enable odoo-${ODOO_VERSION}

# Create an update script
log "Creating update script..."
cat > ${OE_HOME}/update-odoo-${ODOO_VERSION}.sh << EOF
#!/bin/bash
systemctl stop odoo-${ODOO_VERSION}
su - ${OE_USER} -c "cd ${OE_HOME}/odoo-${ODOO_VERSION} && git pull"
su - ${OE_USER} -c "${VENV_PIP} install -r ${OE_HOME}/odoo-${ODOO_VERSION}/requirements.txt"
systemctl start odoo-${ODOO_VERSION}
EOF

chmod +x ${OE_HOME}/update-odoo-${ODOO_VERSION}.sh
chown ${OE_USER}:${OE_USER} ${OE_HOME}/update-odoo-${ODOO_VERSION}.sh

log "Installation complete!"
echo "========================================"
echo "Odoo ${ODOO_VERSION} Installation Summary"
echo "========================================"
echo "Web interface: http://localhost:8069"
echo "Service name: odoo-${ODOO_VERSION}"
echo "Config file: /etc/odoo/odoo-${ODOO_VERSION}.conf"
echo "Log file: /var/log/odoo/odoo-${ODOO_VERSION}.log"
echo "Virtual environment: ${VENV_PATH}"
echo "Admin password: ${OE_MASTER_PASSWORD}"
echo ""
echo "To update Odoo in the future, run:"
echo "sudo ${OE_HOME}/update-odoo-${ODOO_VERSION}.sh"
echo ""
echo "Useful commands:"
echo "- Check status: systemctl status odoo-${ODOO_VERSION}"
echo "- View logs: tail -f /var/log/odoo/odoo-${ODOO_VERSION}.log"
echo "- Restart service: systemctl restart odoo-${ODOO_VERSION}"

log -nodate "\n\n\nDone \n\n\n"
