# Build HAProxy-Icap OVA/AMI with packer



## Ubuntu based HAProxy OVA build with packer on VMware ESXi 

Packer template to build Ubuntu VM with the following configuration

- Hostname: **glasswall**

- Username: **glasswall**

- Password: **Gl@$$wall**

- sudo enabled for user **glasswall** , with no password prompt

- Predictable network interfaces naming  (i.e: **eth0**)

## Build requirements

### Build machine

the machine running this packer template must have the following installed

- packer
- [ovftool](https://my.vmware.com/group/vmware/downloads/get-download?downloadGroup=OVFTOOL441)
- xorriso (or cdrtools)

### ESXi Host

- Minimum 60GB free storage, 4GB free RAM at the build time
- **Guest IP Hack** enabled, you can enable it by running the following on the ESXi host `esxcli system settings advanced set -o /Net/GuestIPHack -i 1`
- IP address accessible from the packer build machine (To use for the VM)

### Usage

- Prepare the project by running the following 
  
  - ```bash
    git clone --single-branch -b main https://github.com/k8-proxy/vmware-scripts
    cd vmware-scripts/packer/
    cp vars.json.example vars.json
    cp cdrom/user-data.example cdrom/user-data
    ```
    
    
    
  - tweak the configuration in vars.json as needed
    
    ```bash
    nano vars.json # then tweak parameters as needed, and exit
    ```
    
    Mainly :
  
    * ESXi server url, username & password (esxi_host, esxi_username & esxi_password)
    * The OVA username, password & IP address (ssh_user, ssh_password & ssh_host)
    
    
    
  - tweak the configuration in cdrom/user-data as needed, as indicated in the comments
    
    ```bash
    nano cdrom/user-data # then tweak parameters indicated in comments needed. and exit
    ```
    
    Mainly :
    
    * IP , Gateway & nameserver
    
    
  
- Replace the setup directory with the pre-configured setup directory for HAProxy ICAP
  
  ```bash
  mv setup setup.orig
  cp -r target/haproxy-icap/setup . 
  ```
  
- Start the build (this will take up to 10 mins)
  
  ```bash
  PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=ask -var-file=vars.json esxi.json
  ```

- You should be able to find the ova under **output-vmware-iso/** directory



## Ubuntu based HAProxy AMI build with packer 

### Build machine

the machine running this packer template must have the following installed

- packer
- [ovftool](https://my.vmware.com/group/vmware/downloads/get-download?downloadGroup=OVFTOOL441)
- xorriso (or cdrtools)

### Usage

- Prepare the project by running the following 

  - ```bash
    git clone --single-branch -b main https://github.com/k8-proxy/vmware-scripts
    cd vmware-scripts/packer/
    cp aws-vars.json.example aws-vars.json
    ```

  - Define aws access key and aws secret key as environment variables 

    ```bash
    export AWS_ACCESS_KEY_ID=<PLACE YOUR KEY HERE>
    export AWS_SECRET_ACCESS_KEY=<PLACE YOUR KEY HERE>
    ```

  - Tweak the configuration in aws-vars.json as needed

    ```bash
    nano aws-vars.json # then tweak parameters as needed, and exit
    ```

    Mainly :

    * the region where the AMI will be created.

- Replace the setup directory with the pre-configured setup directory for HAProxy ICAP

  ```bash
  mv setup setup.orig
  cp -r target/haproxy-icap/setup . 
  ```

- Start the build (this will take up to 5 mins)

  ```bash
  PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=ask -var-file=aws-vars.json aws-ami.json
  ```

- Your AMI id will be printed out and ready to use on the configured aws region when the build is done.

