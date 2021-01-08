# Installing fail2ban.service to created images with packer

Append the content of file2ban.setup file to the end of setup.sh of your requested image before starting packer build

* Make sure that you current working directory is **vmware-scripts/packer/target/**
* Replace the placeholder with the name of your requested image directory

```bash
sudo cat file2ban.setup >> <YOUR IMAGE DIRECTORY NAME>/setup.sh
```



