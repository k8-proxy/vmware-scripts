#!/bin/bash

# enable tls
echo "TLS is enabled"
sudo mkdir -p /var/lib/rancher/k3s/server/manifests/
sudo touch /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
sudo chmod 777 /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
sudo cat >> /var/lib/rancher/k3s/server/manifests/traefik-config.yaml <<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ssl:
      enabled: true
      insecureSkipVerify: true
      generateTLS: true
EOF

# install k3s
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "Done installing kubectl"

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# clone repos
cd ~
git clone https://github.com/k8-proxy/s-k8-proxy-rebuild.git
git clone https://github.com/k8-proxy/vmware-scripts.git

# generate self signed certificates
cd vmware-scripts/proxy-rebuild
chmod +x gencert.sh
./gencert.sh
echo "Generated certificates"

# setup proxy
chmod +x 02-setup-proxy.sh
echo "Using ICAP server IP $ICAP_SERVER_IP"
printf "$ICAP_SERVER_IP\n\n\n" | ./02-setup-proxy.sh

# wait for pods to be ready
sleep 120s
