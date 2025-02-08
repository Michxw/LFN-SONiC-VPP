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
#   $3: number of sriov interfaces
########################################

adding_sriov_vfs_and_vlans() {
  
  # Add SRIOV VFs
  verbose "Creating SRIOV interfaces..."
  if ! echo $3 > /sys/class/net/$2/device/sriov_numvfs; then
    err "Failed creating SRIOV interfaces"
    exit 1
  fi
  
  verbose "Adding vlans to SRIOV interfaces..."
  for i in $(seq 0 $(($3 - 1)))
  do
    VLAN_ID=$((100 + i))
    if ! ip link set dev $2 up vf $i vlan $VLAN_ID; then
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
  for i in $(seq 0 $(($3 - 1)))
  do
    if ! sudo ip link add name ${2}_${i}_point_a type veth peer name ${2}_${i}_point_b; then
      err "Failed creating veth interfaces"
      exit 1
    fi
  done

}

#######################################
# Main function
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