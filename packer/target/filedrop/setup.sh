#!/bin/bash
set -v 

# install k3s
if [ -f ./flush_ip.sh ] ; then
chmod +x ./flush_ip.sh
./flush_ip.sh
fi
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "Done installing kubectl"

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# get source code
git clone https://github.com/k8-proxy/k8-rebuild.git --recursive && cd k8-rebuild && git submodule foreach git pull origin main && pushd k8-rebuild-rest-api/libs/ && git pull origin master && popd

# build docker images
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# install local docker registry
sudo docker run -d -p 30500:5000 --restart always --name registry registry:2

# build images
sudo docker build k8-rebuild-rest-api -f k8-rebuild-rest-api/Source/Service/Dockerfile -t localhost:30500/k8-rebuild-rest-api
sudo docker push localhost:30500/k8-rebuild-rest-api
sudo docker build k8-rebuild-file-drop/app -f k8-rebuild-file-drop/app/Dockerfile -t localhost:30500/k8-rebuild-file-drop
sudo docker push localhost:30500/k8-rebuild-file-drop

cat >> kubernetes/values.yaml <<EOF

sow-rest-api:
  image:
    registry: localhost:30500
    repository: k8-rebuild-rest-api
    imagePullPolicy: Never
    tag: latest
sow-rest-ui:
  image:
    registry: localhost:30500
    repository: k8-rebuild-file-drop
    imagePullPolicy: Never
    tag: latest
EOF
# install UI and API helm charts
helm upgrade --install k8-rebuild \
  --set nginx.service.type=ClusterIP \
  --atomic kubernetes/

# allow password login (useful when deployed to esxi)
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd $USER
sleep 3s
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo cat /etc/ssh/sshd_config
sudo service sshd restart
