# Health Functiona Check script for File Drop

This script can be used to do Functional checks. This solution uses JavaScript End to End Testing Framework - cypress.io.

### Steps 
* Open http://3.133.161.191/
* Login
* Send a.pdf
* Receive rebuild a.pdf and XML report.

### Install NodeJS Windows

Download and install NodeJS and coresponding files https://nodejs.org/dist/v14.15.3/node-v14.15.3-x64.msi

### Install NodeJS Linux
```bash
sudo su -
curl -sL https://deb.nodesource.com/setup_15.x | bash -
apt-get install -y nodejs
apt-get -y install libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb
exit
```

### Download and install solution
```bash
git clone --recursive https://github.com/MariuszFerdyn/vmware-scripts.git
cd vmware-scripts/HealthFunctionalTests/filedrop
npm ci
```

### Start tests
```bash
npm test
```

Please ignore save files error - just check test successfull message or in CI/CD you can use errorlevel:
```bash
npm test 2>&1 | grep ' All specs passed! '
echo $?
```

### On Desktop - visual interface 
```bash
npm start
```
File with test scenario vmware-scripts/HealthFunctionalTests/filedrop/cypress/integration/filedrop.spec.js