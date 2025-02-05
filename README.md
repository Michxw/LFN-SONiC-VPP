# SONIC_VPP PROJECT
We offer two key components: a Docker image named **docker-sonic-vpp:latest** and an enhanced startup script named **start_sonic_vpp.sh**, which addresses driver binding issues found in the original script.
## FOLLOW THE NEXT STEPS
### Run pre requirements


### pull the image

docker login --username Michxw --password {password} ghcr.io
docker pull ghcr.io/michxw/docker-sonic-vpp:latest

### set the interfaces 

### run the container

# Run SONIC-VPP containers
./sonic-platform-vpp/start_sonic_vpp.sh start -n sonic-vpp-2 -i
"0000:41:0a.0,0000:41:0a.1"