# SONIC_VPP Easy Start Project

The SONIC_VPP Easy Start project provides a streamlined solution to run the SONIC_VPP virtual router on top of Ubuntu 22.04 with minimal steps. This setup allows for instantiating the SONIC_VPP router and provides the flexibility to attach either SR-IOV interfaces or veth interfaces, depending on the user's requirements.

## Steps to Deploy the SONIC_VPP Docker Container on Your Server
### 1. Install Prerequisites
Navigate to the `/scripts` folder and execute the `pre_requirements.sh` script to install the necessary dependencies:
```bash
./pre_requirements.sh
```
### 2. Reboot the System
After completing the prerequisite setup, it is essential to reboot the system to apply changes made to the GRUB configuration and Docker setup:

```bash
sudo reboot
```

### 3. Pull the Docker Image
To pull the required Docker image, first, export the repository password and log in to the Docker registry:

```bash
export SONIC_IMG_PASSWORD=<passwored to image registry>
```
Next, authenticate with Docker:
```bash
docker login --username Michxw --password $SONIC_IMG_PASSWORD ghcr.io
```
Finally, pull the SONIC_VPP image:
```bash
docker pull ghcr.io/michxw/docker-sonic-vpp:latest
```
### Set the interfaces 

# Run SONIC-VPP containers
./sonic-platform-vpp/start_sonic_vpp.sh start -n sonic-vpp-2 -i
"0000:41:0a.0,0000:41:0a.1"