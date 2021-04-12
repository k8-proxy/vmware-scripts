if [ -f ./update_partition_size.sh ] ; then
chmod +x ./update_partition_size.sh
./update_partition_size.sh
fi
#sudo kubectl  create ns icap-adaptation
sudo kubectl  create ns management-ui
sudo kubectl  create ns icap-ncfs
cd rabbitmq
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
sudo helm upgrade rabbitmq --install . --namespace icap-adaptation 
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
sudo kubectl  create secret tls icap-service-tls-config --namespace icap-adaptation --key /tmp/tls.key --cert /tmp/certificate.crt
cd adaptation
sudo kubectl  create -n icap-adaptation secret generic policyupdateservicesecret --from-literal=username=policy-management --from-literal=password='long-password'
sudo kubectl  create -n icap-adaptation secret generic transactionqueryservicesecret --from-literal=username=query-service --from-literal=password='long-password'
sudo kubectl  create -n icap-adaptation secret generic  rabbitmq-service-default-user --from-literal=username=guest --from-literal=password='guest'
sudo helm upgrade adaptation --values custom-values.yaml --install . --namespace icap-adaptation
cd ..
cd ncfs
sudo kubectl  create -n icap-ncfs secret generic ncfspolicyupdateservicesecret --from-literal=username=policy-update --from-literal=password='long-password'
sudo helm upgrade ncfs --values custom-values.yaml --install . --namespace icap-ncfs
cd ..
sudo kubectl  create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
sudo kubectl  create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
sudo kubectl  create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'
cd administration
sudo helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
cd ..
sudo kubectl  create -n management-ui secret generic smtpsecret \
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
sed -i 's|<REPLACE_IMAGE_ID>|'$CS_API_IMAGE'|' deployment.yaml
sudo kubectl  apply -f deployment.yaml -n icap-adaptation
# allow password login (useful when deployed to esxi)
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd ubuntu
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service ssh restart
