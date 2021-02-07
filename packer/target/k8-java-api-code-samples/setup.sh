#!/bin/bash
bash <( curl https://get.docker.com )
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker $USER
cd ~
git clone https://github.com/k8-proxy/k8-java-api-code-samples --single-branch --recursive
pushd k8-java-api-code-samples && git submodule update --init --recursive
pushd k8-rebuild-file-drop && git pull origin main && popd
pushd k8-rebuild-rest-api && git pull origin main && pushd libs && git pull origin master && popd -1
sudo su $USER -c "docker-compose up -d"
