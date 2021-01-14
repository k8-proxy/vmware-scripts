#!/bin/bash

# install k3s
curl -sfL https://get.k3s.io | sh -
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "Done installing kubectl"

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# get source code
git clone https://github.com/k8-proxy/icap-infrastructure.git
cd icap-infrastructure

# Create namespaces
kubectl create ns icap-adaptation
kubectl create ns management-ui

# Setup rabbitMQ
cd rabbitmq
helm upgrade rabbitmq --install . --namespace icap-adaptation

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

kubectl create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'

kubectl create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
kubectl create -n icap-adaptation secret docker-registry regcred \
	--docker-server=https://index.docker.io/v1/ \
	--docker-username=$docker_username \
	--docker-password=$docker_password \
	--docker-email=$docker_email

cd ../adaptation
helm upgrade adaptation --install . --namespace icap-adaptation

# setup management ui
kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'

cd ../administration
helm upgrade administration --install . --namespace management-ui

# deploy monitoring solution
git clone https://github.com/k8-proxy/k8-rebuild.git && cd k8-rebuild
helm install sow-monitoring monitoring --set monitoring.elasticsearch.host=$monitoring_ip

# wait until the pods are up
# sleep 120s
