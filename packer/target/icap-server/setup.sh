#!/bin/bash
pushd $( dirname $0 )
if [ -f ./env ] ; then
source ./env
fi

# install wizard to setup network (for OVA)
# if [ -f ./update_partition_size.sh ] ; then
# chmod +x ./update_partition_size.sh
# ./update_partition_size.sh
# fi

# Integrate Instance based healthcheck
# sudo apt update -y
# sudo apt install c-icap -y
# cp -r healthcheck ~
# chmod +x ~/healthcheck/healthcheck.sh
# sudo apt install python3-pip -y
# export PATH=$PATH:$HOME/.local/bin
# pip3 install fastapi
# pip3 install uvicorn
# pip3 install uvloop
# pip3 install httptools
# pip3 install requests
# pip3 install aiofiles
# sudo apt install gunicorn -y
# sudo mv ~/healthcheck/gunicorn.service /etc/systemd/system/
# sudo systemctl start gunicorn
# sudo systemctl enable gunicorn
# crontab -l 2>/dev/null | { cat; echo "* * * * *  flock -n /home/ubuntu/healthcheck/status.lock /home/ubuntu/healthcheck/healthcheck.sh 2>> /home/ubuntu/healthcheck/cronstatus.log"; } | crontab -

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

# get source code, we clone in in home dir so we can easilly update in place
cd ~
ICAP_BRANCH=${ICAP_BRANCH:-k8-develop}
git clone https://github.com/k8-proxy/icap-infrastructure.git -b $ICAP_BRANCH && cd icap-infrastructure

# Clone ICAP SOW Version 
ICAP_SOW_BRANCH=${ICAP_SOW_BRANCH:-main}
git clone https://github.com/filetrust/icap-infrastructure.git -b $ICAP_SOW_BRANCH /tmp/icap-infrastructure-sow
cp  /tmp/icap-infrastructure-sow/adaptation/values.yaml adaptation/
cp  /tmp/icap-infrastructure-sow/administration/values.yaml administration/
cp  /tmp/icap-infrastructure-sow/ncfs/values.yaml ncfs/

# Admin ui default credentials
sudo mkdir -p /var/local/rancher/host/c/userstore
sudo cp -r default-user/* /var/local/rancher/host/c/userstore/

# Create namespaces
kubectl create ns icap-adaptation
kubectl create ns management-ui
kubectl create ns icap-ncfs
kubectl create ns minio

# Install minio
helm repo add minio https://helm.min.io/
helm install -n minio --set accessKey=minio,secretKey=$MINIO_SECRET,buckets[0].name=sourcefiles,buckets[0].policy=none,buckets[0].purge=false,buckets[1].name=cleanfiles,buckets[1].policy=none,buckets[1].purge=false,fullnameOverride=minio-server,persistence.enabled=false minio/minio --generate-name

kubectl create -n icap-adaptation secret generic minio-credentials --from-literal=username='minio' --from-literal=password=$MINIO_SECRET

# Setup rabbitMQ
pushd rabbitmq && helm upgrade rabbitmq --install . --namespace icap-adaptation && popd

# Setup icap-server
cat >> openssl.cnf <<EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name

[ req_distinguished_name ]
C = GB
ST = London
L = London
O = Glasswall
OU = IT
CN = icap-server
emailAddress = admin@glasswall.com
EOF

openssl req -newkey rsa:2048 -config openssl.cnf -nodes -keyout  /tmp/tls.key -x509 -days 365 -out /tmp/certificate.crt
kubectl create secret tls icap-service-tls-config --namespace icap-adaptation --key /tmp/tls.key --cert /tmp/certificate.crt

pushd adaptation
kubectl create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password=$RABBIT_SECRET
helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation
popd

# Setup icap policy management
pushd ncfs
kubectl create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password=$TRANSACTIONS_SECRET
helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
popd

# setup management ui
kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password=$TRANSACTIONS_SECRET

pushd administration
helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
popd

cd ~

# deploy new Go services
git clone https://github.com/k8-proxy/go-k8s-infra.git -b develop && cd go-k8s-infra

# Scale the existing adaptation service to 0
kubectl -n icap-adaptation scale --replicas=0 deployment/adaptation-service

# Apply helm chart to create the services
pushd services
helm upgrade servicesv2 --install . --namespace icap-adaptation
popd

cd ~

# deploy monitoring solution
git clone https://github.com/k8-proxy/k8-rebuild.git && cd k8-rebuild
helm install sow-monitoring monitoring --set monitoring.elasticsearch.host=$MONITORING_IP --set monitoring.elasticsearch.username=$MONITORING_USER --set monitoring.elasticsearch.password=$MONITORING_PASSWORD
popd

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

# install gw cloud sdk
git clone https://github.com/k8-proxy/cs-k8s-api.git && pushd cs-k8s-api
sudo docker build . -t localhost:30500/cs-k8s-api
sed -i "s|<REPLACE_IMAGE_ID>|localhost:30500/cs-k8s-api|"  deployment.yaml
kubectl apply -nicap-adaptation -f deployment.yaml && popd

# allow password login (useful when deployed to esxi)
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd $USER
sleep 3s
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart

