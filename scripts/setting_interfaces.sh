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
# Adding the sriov vfs
# Globals:
#   None
# Arguments:
#   $2: name of the sriov interface
########################################

adding_sriov_vfs_and_vlans() {


# Add SRIOV VFs
echo 4 > /sys/class/net/enp65s0f1/device/sriov_numvfs

ip link set dev enp65s0f1 up vf 0 vlan 2132
ip link set dev enp65s0f1 up vf 1 vlan 2121
ip link set dev enp65s0f1 up vf 2 vlan 2133
ip link set dev enp65s0f1 up vf 3 vlan 2134

}

#######################################
# Adding the veths
# Globals:
#   None
# Arguments:
#   None
########################################
adding_veths() {

# Adding veths
sudo ip link add name veth_vpp1 type veth peer name vpp1
sudo ip link add name veth_vpp2 type veth peer name vpp2

}

#######################################
# Adding the veths
# Globals:
#   None
# Arguments:
#   $1: Sriov or veths
########################################
main (){
  
  if [[ $1 == "sriov" ]]; then
    adding_sriov_vfs_and_vlans || exit 1
  elif [[ $1 == "veths" ]]; then
    adding_veths || exit 1
  else
    err "Usage: $0 {sriov|veths}"
    exit 1
  fi
}