## Automating the creation of monitoring OVA
### Copy setup files
Copy visualog/setup folder to packer/setup 
### Run packer
```
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build -on-error=ask -var-file=vars.json esxi.json
```