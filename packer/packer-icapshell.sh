#!/bin/bash
source /home/ubuntu/.env

# install k3s
if [ -f ./flush_ip.sh ] ; then
chmod +x ./flush_ip.sh
./flush_ip.sh
fi

curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube &&  install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
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
mkdir -p /var/local/rancher/host/c/userstore
cp -r default-user/* /var/local/rancher/host/c/userstore/

# Create namespaces
kubectl create ns icap-adaptation
kubectl create ns management-ui
kubectl create ns icap-ncfs
kubectl create ns minio

# Install minio
helm repo add minio https://helm.min.io/
helm install -n minio --set accessKey=minio,secretKey=$MINIO_SECRET,buckets[0].name=sourcefiles,buckets[0].policy=none,buckets[0].purge=false,buckets[1].name=cleanfiles,buckets[1].policy=none,buckets[1].purge=false,fullnameOverride=minio-server,persistence.enabled=false minio/minio --generate-name

kubectl create -n icap-adaptation secret generic minio-credentials --from-literal=username='minio' --from-literal=password=$MINIO_SECRET

kubectl create -n icap-adaptation secret docker-registry regcred \
	--docker-server=https://index.docker.io/v1/ \
	--docker-username=$DOCKER_USERNAME \
	--docker-password=$DOCKER_PASSWORD \
	--docker-email=$DOCKER_EMAIL

# Setup rabbitMQ
cd rabbitmq && helm upgrade rabbitmq --install . --namespace icap-adaptation

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

cd adaptation
kubectl create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password=$RABBIT_SECRET
helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation


# Setup icap policy management
cd ncfs
kubectl create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password=$TRANSACTIONS_SECRET
helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs


# setup management ui
kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password=$TRANSACTIONS_SECRET
kubectl create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password=$TRANSACTIONS_SECRET

cd administration
helm upgrade administration --values custom-values.yaml --install . --namespace management-ui


cd ~


# deploy new Go services
git clone https://github.com/k8-proxy/go-k8s-infra.git -b develop && cd go-k8s-infra

# Scale the existing adaptation service to 0
kubectl -n icap-adaptation scale --replicas=0 deployment/adaptation-service
kubectl  -n icap-adaptation delete cronjob --all
kubectl  -n icap-adaptation delete job --all

# Apply helm chart to create the services
cd services
helm upgrade servicesv2 --install . --namespace icap-adaptation

cd ~

# deploy monitoring solution
git clone https://github.com/k8-proxy/k8-rebuild.git && cd k8-rebuild
helm install sow-monitoring monitoring --set monitoring.elasticsearch.host=$MONITORING_IP --set monitoring.elasticsearch.username=$MONITORING_USER --set monitoring.elasticsearch.password=$MONITORING_PASSWORD


# build docker images
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker


# install local docker registry
docker run -d -p 30500:5000 --restart always --name registry registry:2

# install gw cloud sdk
git clone https://github.com/k8-proxy/cs-k8s-api.git && cd cs-k8s-api
docker build . -t localhost:30500/cs-k8s-api
sed -i "s|<REPLACE_IMAGE_ID>|localhost:30500/cs-k8s-api|"  deployment.yaml
kubectl apply -n icap-adaptation -f deployment.yaml

# wait until the pods are up
# sleep 120s

# allow password login (useful when deployed to esxi)
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | passwd $USER
sleep 3s
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
service sshd restart