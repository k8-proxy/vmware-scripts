sudo kubectl patch svc proxy-rest-api -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":8080}]'
SSH_PASSWORD=${SSH_PASSWORD:-glasswall}
printf "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd $USER
sleep 3s
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo service sshd restart
ICAP_BRANCH=k8-main
git clone https://github.com/k8-proxy/icap-infrastructure.git -b $ICAP_BRANCH && cd icap-infrastructure
ICAP_SOW_BRANCH=main
sudo kubectl patch svc proxy-rest-api -n icap-adaptation --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":1346}]'
git clone https://github.com/filetrust/icap-infrastructure.git -b $ICAP_SOW_BRANCH /tmp/icap-infrastructure-sow
cp  /tmp/icap-infrastructure-sow/administration/values.yaml administration/
sudo kubectl create ns management-ui
sudo kubectl create -n management-ui secret generic transactionqueryserviceref --from-literal=username=query-service --from-literal=password='long-password'
sudo kubectl create -n management-ui secret generic policyupdateserviceref --from-literal=username=policy-management --from-literal=password='long-password'
sudo kubectl create -n management-ui secret generic ncfspolicyupdateserviceref --from-literal=username=policy-update --from-literal=password='long-password'
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
pushd administration
sudo helm upgrade administration --values custom-values.yaml --install . --namespace management-ui
popd
sudo kubectl delete secret/smtpsecret -n management-ui
sudo kubectl create -n management-ui secret generic smtpsecret \
	--from-literal=SmtpHost=$SMTPHOST \
	--from-literal=SmtpPort=$SMTPPORT \
	--from-literal=SmtpUser=$SMTPUSER \
	--from-literal=SmtpPass=$SMTPPASS \
	--from-literal=TokenSecret='12345678901234567890123456789012' \
	--from-literal=TokenLifetime='00:01:00' \
	--from-literal=EncryptionSecret='12345678901234567890123456789012' \
	--from-literal=ManagementUIEndpoint='http://management-ui:8080' \
	--from-literal=SmtpSecureSocketOptions='http://management-ui:8080'
rm -rf /home/ubuntu/icap-infrastructure