#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        print_success "Success"
    else
        print_error "Failed"
    fi
}

# Detect Debian version
get_debian_version() {
    if ! command -v lsb_release &> /dev/null; then
        print_error "lsb_release command not found. Unable to detect Debian version."
    fi
    
    DEBIAN_VERSION=$(lsb_release -rs)
    if [[ -z "$DEBIAN_VERSION" ]]; then
        print_error "Invalid Debian version detected."
    fi

    # Only testing for Debian 12 (bookworm)
    SUPPORTED_VERSIONS=("12")
    if [[ ! " ${SUPPORTED_VERSIONS[@]} " =~ " ${DEBIAN_VERSION} " ]]; then
        print_error "Unsupported Debian version: $DEBIAN_VERSION\nSupported versions are: ${SUPPORTED_VERSIONS[*]}"
    fi
    
    echo "$DEBIAN_VERSION"
}

configure_docker_daemon() {
    # Create Docker daemon directory if it doesn't exist
    sudo mkdir -p /etc/docker
    
    # Create or overwrite daemon.json with NVIDIA runtime configuration
    sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
    "log-driver": "local"
}
EOF
    
    # Restart Docker service to apply changes
    print_status "Restarting Docker service..."
    sudo systemctl restart docker
    check_status
}


# Function to install Docker on Raspberry Pi
install_docker_rpi() {
    print_status "Installing Moby_Engine for Debian on Raspberry Pi..."
    sudo apt-get update; 
    sudo apt-get install moby-engine
}

# Main script execution starts here
print_status "Detecting Debian version..."
DEBIAN_VERSION=$(get_debian_version)
print_success "Detected Debian $DEBIAN_VERSION"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
fi

# Prompt for connection string
echo -e "${YELLOW}Please enter your IoT Edge connection string:${NC}"
read -r CONNECTION_STRING
if [ -z "$CONNECTION_STRING" ]; then
    print_error "Connection string cannot be empty"
fi

# Install Microsoft package repository for Debian
print_status "Setting up Microsoft package repository..."
curl https://packages.microsoft.com/config/debian/$DEBIAN_VERSION/packages-microsoft-prod.deb > ./packages-microsoft-prod.deb
sudo apt install ./packages-microsoft-prod.deb
check_status

# Install Docker
install_docker_rpi
check_status

print_status "Configuring Docker Daemo..."
configure_docker_daemon
check_status

# Install Azure IoT Edge
print_status "Installing Azure IoT Edge..."
sudo apt-get update;
sudo apt-get install aziot-edge
check_status

# Configure IoT Edge
print_status "Configuring IoT Edge..."
sudo iotedge config mp --force --connection-string "$CONNECTION_STRING"
sudo iotedge config apply
check_status

# Check system status
print_status "Checking IoT Edge system status..."
sudo iotedge system status
check_status

print_success "Setup completed successfully!"
