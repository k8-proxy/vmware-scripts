#!/bin/bash
source /home/ubuntu/.env
if [ -f ./update_partition_size.sh ] ; then
chmod +x ./update_partition_size.sh
./update_partition_size.sh
fi
git clone https://github.com/k8-proxy/icap-infrastructure.git -b k8-main && cd icap-infrastructure
mkdir -p /var/local/rancher/host/c/userstore
cp -r default-user/* /var/local/rancher/host/c/userstore/
#kubectl  create ns icap-adaptation
kubectl  create ns management-ui
kubectl  create ns icap-ncfs
cd rabbitmq
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm upgrade rabbitmq --install . --namespace icap-adaptation 
cd ..
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
kubectl  create secret tls icap-service-tls-config --namespace icap-adaptation --key /tmp/tls.key --cert /tmp/certificate.crt
# Clone ICAP SOW Version 
git clone https://github.com/filetrust/icap-infrastructure.git -b main /tmp/icap-infrastructure-sow
cp  /tmp/icap-infrastructure-sow/adaptation/values.yaml adaptation/
cp  /tmp/icap-infrastructure-sow/administration/values.yaml administration/
cp  /tmp/icap-infrastructure-sow/ncfs/values.yaml ncfs/
cd adaptation
kubectl  create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'
kubectl  create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
kubectl  create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password='guest'
kubectl  create -n icap-adaptation secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD} --docker-email=${DOCKER_EMAIL}
helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation
kubectl patch svc frontend-icap-lb -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":1344},{"op":"replace","path":"/spec/ports/1/nodePort","value":1345}]'
cd ..
cd ncfs
kubectl  create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password='long-password'
helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
cd ..
kubectl  create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
kubectl  create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
kubectl  create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'
cd administration
sed -i 's|traefik|nginx|' templates/management-ui/ingress.yml
helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
cd ..
kubectl delete secret/smtpsecret -n management-ui
kubectl  create -n management-ui secret generic smtpsecret \
	--from-literal=SmtpHost=$SMTPHOST \
	--from-literal=SmtpPort=$SMTPPORT \
	--from-literal=SmtpUser=$SMTPUSER \
	--from-literal=SmtpPass=$SMTPPASS \
	--from-literal=TokenSecret='12345678901234567890123456789012' \
	--from-literal=TokenLifetime='00:01:00' \
	--from-literal=EncryptionSecret='12345678901234567890123456789012' \
	--from-literal=ManagementUIEndpoint='http://management-ui:8080' \
	--from-literal=SmtpSecureSocketOptions='http://management-ui:8080'
wget https://raw.githubusercontent.com/k8-proxy/cs-k8s-api/main/deployment.yaml
echo $CS_API_IMAGE
sed -i 's|glasswallsolutions/cs-k8s-api:latest|'$CS_API_IMAGE'|' deployment.yaml
kubectl  apply -f deployment.yaml -n icap-adaptation
kubectl patch svc proxy-rest-api -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":8080}]'
