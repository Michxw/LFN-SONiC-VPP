#!/bin/bash

# Global variables 
VERBOSE=0

# Global Inpunts
for arg in "$@"; do
  if [[ "$arg" == "-v" || "$arg" == "--verbose" ]]; then
    VERBOSE=1
  fi
done

#######################################
# err function used to track errors
# in bash scripts
# Globals:
#   None
# Arguments:
#   any ($*) : strings will be combined 
#              into a single one
#######################################
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
  return 1  # Return a non-zero status code
}

#######################################
# Verbose function used to explain in
# detail each command
# Globals:
#   None
# Arguments:
#   any ($*) : strings will be combined 
#              into a single one
#######################################
verbose() {
  if [ $VERBOSE -eq 1 ]; then
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
  fi
}

#######################################
# Install all the pre requirements on 
# the server
# Globals:
#   None
# Arguments:
#   None
########################################

setup_ubuntu_packages() {

  # Updating package lists
  verbose "Updating the apt-get packages..."
  if ! sudo apt-get update; then
    err "Failed apt-get update"
    exit 1
  fi

  # Installing required packages in a single command
  verbose "Installing required packages: make, automake, autoconf, python3-pip..."
  if ! sudo apt-get install -y make automake autoconf python3-pip; then
    err "Failed installing required packages"
    exit 1
  fi

  # Installing j2cli using pip3
  verbose "Installing j2cli with pip3..."
  if ! sudo -H pip3 install j2cli; then
    err "Failed installing j2cli with pip3"
    exit 1
  fi
}

#######################################
# Installing docker in Ubuntu server
# Globals:
#   None
# Arguments:
#   None
########################################

setup_docker() {
  
  # Updating package lists
  verbose "Updating the apt-get packages..."
  if ! sudo apt-get update; then
    err "Failed apt-get update"
    exit 1
  fi

  # Installing docker packages dependencies
  verbose "Installing ca-certificate curl..."
  if ! sudo apt-get install -y ca-certificates curl; then
    err "Failed installing ca-certificates curl"
    exit 1
  fi

  # Creating the /etc/apt/keyrings directory with the correct permissions
  verbose "Setting up the keyrings directory..."
  if ! sudo install -m 0755 -d /etc/apt/keyrings; then
    err "Failed to create /etc/apt/keyrings directory with the correct permissions"
    exit 1
  fi
  
  # Downloading and storing the Docker GPG key
  verbose "Downloading Docker GPG key..."
  if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    err "Failed to download Docker GPG key"
    exit 1
  fi

  # Setting correct permissions for the Docker GPG key
  verbose "Setting permissions for Docker GPG key..."
  if ! sudo chmod a+r /etc/apt/keyrings/docker.asc; then
    err "Failed to set permissions for Docker GPG key"
    exit 1
  fi

  # Adding Docker repository to APT sources
  verbose "Adding Docker repository to APT sources..."
  if ! echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    err "Failed to add Docker repository"
    exit 1
  fi


  # Updating package lists
  verbose "Updating apt-get packages..."
  if ! sudo apt-get update; then
    err "Failed apt-get update"
    exit 1
  fi
  

  # Installing Docker and related components
  verbose "Installing Docker components..."
  if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    err "Failed to install Docker components"
    exit 1
  fi

  # Creating Docker group if it doesn't exist
  verbose "Checking if Docker group exists..."
  if ! getent group docker >/dev/null; then
  verbose "Creating Docker group..."
  if ! sudo groupadd docker; then
    err "Failed to create Docker group"
    exit 1
  fi
  else
  verbose "Docker group already exists. Skipping creation."
  fi

  # Adding the current user to the Docker group
  verbose "Adding current user to the Docker group..."
  if ! sudo usermod -aG docker $USER; then
    err "Failed to add user to Docker group"
    exit 1
  fi

  # Applying new group membership
  verbose "Applying new group membership..."
  if ! newgrp docker; then
    err "Failed to apply new group membership"
    exit 1
  fi

}

#######################################
# Enable VFIO and Configure 
# IOMMU for PCI Passthrough
# Globals:
#   None
# Arguments:
#   None
########################################
  
enable_vfio (){
  # Loading vfio-pci kernel module
  verbose "Loading vfio-pci kernel module..."
  if ! sudo modprobe vfio-pci; then
    err "Failed to load vfio-pci module"
    exit 1
  fi

  # enabling unsafe noiummu mode
  verbose "Enabling unsafe noiommu mode..."
  if ! echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode; then
    err "Failed to enabling noiu"
    exit 1
  fi
  
  # Ensuring #GRUB_CMDLINE_LINUX is uncomment
  if grep -q "^#GRUB_CMDLINE_LINUX=" /etc/default/grub; then
  verbose "Uncommenting and appending intel_iommu=on to GRUB_CMDLINE_LINUX..."
    if ! sudo sed -i 's/^#GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="/' /etc/default/grub; then
      err "Failed to uncomment GRUB configuration"
      exit 1
    fi
  fi

  # Ensuring intel_iommu=on is set in GRUB configuration
  verbose "Checking and updating GRUB configuration..."
  if ! grep -q "intel_iommu=on" /etc/default/grub; then
    verbose "Appending intel_iommu=on to GRUB_CMDLINE_LINUX..."
    if ! sudo sed -i 's/^GRUB_CMDLINE_LINUX="\s*\([^"]*\)"/GRUB_CMDLINE_LINUX="\1intel_iommu=on"/' /etc/default/grub; then
      err "Failed to update GRUB configuration"
      exit 1
    fi
  else
    verbose "intel_iommu=on already set in GRUB configuration"
  fi

  # Updating GRUB
  verbose "Updating GRUB bootloader..."
  if ! sudo update-grub; then
    err "Failed to update GRUB"
    exit 1
  fi

}

#######################################
# Enable all the needed things in the 
# Server so SONiC can work
# Globals:
#   None
# Arguments:
#   None
########################################

main (){
  
  setup_ubuntu_packages || exit 1

  enable_vfio  || exit 1
  
  setup_docker || exit 1
}

# Running the main function
main 
