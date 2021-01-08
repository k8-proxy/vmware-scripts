# Installing fail2ban.service to created images with packer to protect our open SSH access.

Append the content of file2ban.setup file to the end of setup.sh of your requested image before starting packer build

* Make sure that you current working directory is **vmware-scripts/packer/target/**
* Replace the placeholder with the name of your requested image directory

```bash
sudo cat file2ban.setup >> <YOUR IMAGE DIRECTORY NAME>/setup.sh
```

* If needed you can change the default configuration by opening file2ban.setup file before appending it's content and change the following settings:

  * **bantime** : Ban time is the length of time a specific client IP Address will be  banned when its behavior violates the specific ban policy that will be  defined.
  * **findtime** : findtime is the duration between the number of failures before a ban is set.
  * **maxretrey** : number of failed login attempts within the findtime before the ip address is banned 

  