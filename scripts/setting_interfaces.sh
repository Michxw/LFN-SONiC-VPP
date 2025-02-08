#!/bin/bash

# Global variables 
VERBOSE=0
INT_TYPE=""
INT_NAME=""
INT_NUM=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=1  # Enable verbose mode
      shift
      ;;
    *)
      if [ -z "$INT_TYPE" ]; then
        INT_TYPE="$1"  # Set the first positional argument
      elif [ -z "$INT_NAME" ]; then
        INT_NAME="$1"  # Set the second positional argument
      elif [ -z "$INT_NUM" ]; then
        INT_NUM="$1"  # Set the third positional argument
      fi
      shift
      ;;
  esac
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
# Adding the sriov vfs
# Globals:
#   None
# Arguments:
#   $2: name of the sriov interface
#   $3: number of sriov interfaces
########################################

adding_sriov_vfs_and_vlans() {
  
  # Get the correct sriov_numvfs file
  verbose "Looking for sriov_numvfs file"
  local file
  file=$(lshw -c network -businfo | grep $INT_NAME | awk '{print $1}' | awk -F "@" '{print $2}')
  if [[ -z "$file" || "$file" == "" ]]; then
    err "Interface not found"
    exit 1
  fi

  # Add SRIOV VFs
  verbose "Creating SRIOV interfaces..."
  if ! echo $INT_NUM > /sys/class/net/$INT_NAME/device/sriov_numvfs; then
    err "Failed creating SRIOV interfaces"
    exit 1
  fi
  
  local vlan_id
  verbose "Adding vlans to SRIOV interfaces..."
  for i in $(seq 0 $(($INT_NUM - 1)))
  do
    vlan_id=$((100 + i))
    if ! ip link set dev $INT_NAME up vf $i vlan $vlan_id; then
      err "Failed adding vlan to SRIOV interface"
      exit 1
    fi
  done

}

#######################################
# Adding the veths
# Globals:
#   None
# Arguments:
#   $2: prefix for veth interfaces
#   $3: number of veth interfaces
########################################
adding_veths() {

  # Adding veths
  verbose "Creating veth interfaces..."
  for i in $(seq 0 $(($INT_NUM - 1)))
  do
    if ! sudo ip link add name ${INT_NAME}_${i}_point_a type veth peer name ${INT_NAME}_${i}_point_b; then
      err "Failed creating veth interfaces"
      exit 1
    fi
  done

}

#######################################
# Increasing devices hugepage size
# Globals:
#   None
# Arguments:
#   None
########################################

increasing_hugepage(){
  
  # Find the correct hugepages path
  verbose "Finding hugepages hugepages-2048kB directory..."
  local hugepages_path
  hugepages_path=$(find /sys/devices/system/node/ -type d -name "hugepages-2048kB" 2>/dev/null | head -n 1)
  if [ $? -ne 0 ]; then
    err "Failed to locate hugepages-2048kB directory"
    exit 1
  fi

  # Configuring hugepages
  verbose "Setting hugepages to 20..."
  if ! echo "30" | sudo tee "$hugepages_path/nr_hugepages" > /dev/null; then
    err "Failed to set hugepages"
    exit 1
  fi
  
}

#######################################
# Main function
# Globals:
#   None
# Arguments:
#   $1: Sriov or veths
########################################
main (){

  increasing_hugepage || exit 1

  if [[ $INT_TYPE == "sriov" ]]; then
    adding_sriov_vfs_and_vlans || exit 1
  elif [[ $INT_TYPE == "veths" ]]; then
    adding_veths || exit 1
  else
    err "Usage: $0 {sriov|veths}"
    exit 1
  fi
}

main