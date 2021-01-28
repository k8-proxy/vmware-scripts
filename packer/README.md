# Ubuntu Packer template for VMware vSphere

## Overview

Packer template to build a single node Compliant Kubernetes workload cluster VM with ICAP adaptation service.

## Build requirements

### Build machine

the machine running this packer template must have the following installed

- packer
- [ovftool](https://my.vmware.com/group/vmware/downloads/get-download?downloadGroup=OVFTOOL441)
- xorriso (or cdrtools)

### ESXi Host

- Minimum 60GB free storage, 4GB free RAM at the build time
- IP address accessible from the packer build machine (To use for the VM)

### Usage

- Prepare the project by running the following
  
  - ```bash
    git clone --single-branch -b vsphere-clone https://github.com/elastisys/vmware-scripts
    cd vmware-scripts/packer/
    cp vsphere-vars.json.example vsphere-vars.json
    cp cdrom/user-data.example cdrom/user-data
    ```
  - tweak the configuration in vsphere-vars.json as needed
    
    ```bash
    nano vsphere-vars.json # then tweak parameters as needed, and exit
    ```
  - tweak the configuration in cdrom/user-data as needed, as indicated in the comments
    
    ```bash
    nano cdrom/user-data # then tweak parameters indicated in comments needed. and exit
    ```

- If you have some custom setup you need to append to the build process (**i.e:** installing a service), move your project directory in place of **setup/** , your project is expected to have a **setup.sh** script that will be ran to install your project after **setup/** directory is copied to the build VM under **/tmp/setup** path
  
  ```bash
  mv setup setup.orig
  cp -r ~/myproject setup # replace the placeholder source directory 
  ls setup/setup.sh
  ```

- Start the build
  
  ```bash
  PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=ask -var-file=vsphere-vars.json vsphere.json
  ```

- You should be able to find the ova under **output-vmware-iso/** directory
