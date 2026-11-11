#!/bin/bash
set -euo pipefail

# Purpose: Install basic DevOps tools on Ubuntu.
# Target: Ubuntu automation/build machine.
# Usage: sudo bash scripts/install.sh
# This does not deploy or host the web application.

# Check that the script runs as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script using sudo."
    exit 1
fi

# Check operating system
. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "This script supports Ubuntu only."
    exit 1
fi

echo "Updating package lists..."
apt-get update

echo "Installing required tools..."
apt-get install -y \
    git \
    docker.io \
    python3 \
    python3-pip \
    ansible

echo "Starting and enabling Docker..."
systemctl enable --now docker

echo "Installation completed successfully!"
