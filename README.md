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
export SONIC_IMG_PASSWORD=<password of the image registry>
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
In the `/scripts` folder, execute the `setting_interfaces.sh` script to create the virtual interfaces. The `setting_interfaces.sh` receives three input variables which are:
- Type of interface (sriov | veth)
- Name of the physical interface 
- Number of virtual interfaces 
   
```bash
./setting_interfaces.sh <param 1> <param 2> <param 3>
```

# Run SONIC-VPP containers
Navigate to the root repository directory and execute the `start_sonic_vpp.sh` script. The `start_sonic_vpp.sh` receives two input variables which are:
- Name of the container
- Name of the interface or PCI Bus direction (each input separated by commas ej: "0000:41:0a.0,0000:41:0a.1")

```bash
SONIC_VPP_IMG=ghcr.io/michxw/docker-sonic-vpp:latest ./start_sonic_vpp.sh start -n <param 1> -i <param 2>
```
