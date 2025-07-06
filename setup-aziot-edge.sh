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

configure_nvidia_runtime() {
    print_status "Configuring NVIDIA container runtime..."

    # Create Docker daemon directory if it doesn't exist
    sudo mkdir -p /etc/docker

    # Create or overwrite daemon.json with NVIDIA runtime configuration
    sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
    "log-driver": "local",
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
EOF

    # Restart Docker service to apply changes
    print_status "Restarting Docker service..."
    sudo systemctl restart docker
    check_status
}

# Detect Ubuntu version
get_ubuntu_version() {
    if ! command -v lsb_release &> /dev/null; then
        print_error "lsb_release command not found. Unable to detect Ubuntu version."
    fi

    UBUNTU_VERSION=$(lsb_release -rs)
    if [[ ! $UBUNTU_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid Ubuntu version detected: $UBUNTU_VERSION"
    fi

    # List of supported Ubuntu versions
    SUPPORTED_VERSIONS=("18.04" "20.04" "22.04")
    if [[ ! " ${SUPPORTED_VERSIONS[@]} " =~ " ${UBUNTU_VERSION} " ]]; then
        print_error "Unsupported Ubuntu version: $UBUNTU_VERSION\nSupported versions are: ${SUPPORTED_VERSIONS[*]}"
    fi

    echo "$UBUNTU_VERSION"
}

# Function to install Docker on Ubuntu 18.04
install_docker_18_04() {
    print_status "Installing Docker for Ubuntu 18.04..."
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Function to install Moby Engine on Ubuntu 20.04/22.04
install_moby() {
    print_status "Installing Moby Engine..."
    sudo apt-get update
    sudo apt-get install moby-engine=27.3.1-ubuntu22.04u1 --allow-downgrades
}

# Main script execution starts here
print_status "Detecting Ubuntu version..."
UBUNTU_VERSION=$(get_ubuntu_version)
print_success "Detected Ubuntu $UBUNTU_VERSION"

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
print_status "Setting up Microsoft package repository..."
# Install Microsoft package repository
if [ "$UBUNTU_VERSION" = "22.04" ]; then
    curl -fsSL https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/prod.list | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
else
    curl -fsSL https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/multiarch/prod.list | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
fi
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg
check_status

# Install container runtime based on Ubuntu version
if [ "$UBUNTU_VERSION" = "18.04" ]; then
    install_docker_18_04
else

    install_moby
fi
check_status


# configure docker
print_status "Configuring Docker Daemo..."
configure_nvidia_runtime
check_status

# Install Azure IoT Edge
print_status "Installing Azure IoT Edge..."
sudo apt-get update
sudo apt-get install -y aziot-edge
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
