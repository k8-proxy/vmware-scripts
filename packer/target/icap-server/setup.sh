#!/bin/bash
pushd $( dirname $0 )
if [ -f ./env ] ; then
source ./env
fi

# install docker
# sudo yum-config-manager \
#     --add-repo \
#     https://download.docker.com/linux/centos/docker-ce.repo
# sudo yum install -y docker-ce docker-ce-cli containerd.io
# sudo systemctl start docker
# sudo systemctl enable docker

# install local docker registry
# sudo docker run -d -p 5000:5000 --restart always --name registry registry:2
sudo hostnamectl set-hostname icap-server
sudo tee -a /etc/hosts << EOF
127.0.0.1 icap-server
EOF
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

# pull docker images
# sudo docker pull rancher/pause:3.1
cd ~/icap-infrastructure
request_processing_repo="glasswallsolutions/icap-request-processing"
request_processing_tag=$(yq read adaptation/values.yaml 'imagestore.requestprocessing.tag')
echo "using $request_processing_repo:$request_processing_tag for icap-request-processing"
# sudo docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
# sudo docker pull $request_processing_repo:$request_processing_tag
# sudo docker tag $request_processing_repo:$request_processing_tag localhost:5000/$request_processing_repo:$request_processing_tag
# sudo docker push localhost:5000/$request_processing_repo:$request_processing_tag
# yq write -i adaptation/values.yaml 'imagestore.requestprocessing.registry' localhost:5000/

# Admin ui default credentials
sudo mkdir -p /var/local/rancher/host/c/userstore
sudo cp -r default-user/* /var/local/rancher/host/c/userstore/

# Create namespaces
kubectl create ns icap-adaptation
kubectl create ns management-ui
kubectl create ns icap-ncfs

kubectl create -n icap-adaptation secret docker-registry regcred \
	--docker-server=https://index.docker.io/v1/ \
	--docker-username=$DOCKER_USERNAME \
	--docker-password=$DOCKER_PASSWORD \
	--docker-email=$DOCKER_EMAIL

n=0; until ((n >= 60)); do kubectl -n icap-adaptation get serviceaccount default -o name && break; n=$((n + 1)); sleep 1; done; ((n < 60))
kubectl run rebuild -n icap-adaptation -i --restart=Never --rm \
 --image $request_processing_repo:$request_processing_tag --pod-running-timeout 5m\
 --overrides='{ "spec": { "imagePullSecrets": [{"name": "regcred"}] } }' -- sh

kubectl run fluent-bit --restart=Never --image fluent/fluent-bit:1.5 -- sh
kubectl delete pod fluent-bit

# Setup rabbitMQ
helm -nicap-adaptation delete rabbitmq
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
kubectl create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'
kubectl create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
kubectl create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password='guest'
helm upgrade adaptation --values custom-values.yaml --set cicapservice.conf.DebugLevel=7 --set icapserviceconfig.processingtimeoutduration="00.01.00" --set prometheus.pushgatewayendpoint="http://127.0.0.1:9090/metrics" --install . --namespace icap-adaptation
popd

# Setup icap policy management
pushd ncfs
kubectl create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password='long-password'
helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
popd

# setup management ui
kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
kubectl create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
kubectl create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'

pushd administration
helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
popd

kubectl delete secret/smtpsecret -n management-ui
kubectl create -n management-ui secret generic smtpsecret \
	--from-literal=SmtpHost=$SMTPHOST \
	--from-literal=SmtpPort=$SMTPPORT \
	--from-literal=SmtpUser=$SMTPUSER \
	--from-literal=SmtpPass=$SMTPPASS \
	--from-literal=TokenSecret='12345678901234567890123456789012' \
	--from-literal=TokenLifetime='00:01:00' \
	--from-literal=EncryptionSecret='12345678901234567890123456789012' \
	--from-literal=ManagementUIEndpoint='http://management-ui:8080' \
	--from-literal=SmtpSecureSocketOptions='http://management-ui:8080' || true

cd ~

# deploy monitoring solution
# git clone https://github.com/k8-proxy/k8-rebuild.git && cd k8-rebuild
# helm install sow-monitoring monitoring --set monitoring.elasticsearch.host=$MONITORING_IP --set monitoring.elasticsearch.username=$MONITORING_USER --set monitoring.elasticsearch.password=$MONITORING_PASSWORD

# wait until the pods are up
sleep 300s

# allow password login (useful when deployed to esxi)
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd $USER
sleep 3s
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart

