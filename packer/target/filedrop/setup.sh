#!/bin/bash
curl -sfL https://get.k3s.io | sh -
curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER
git clone https://github.com/k8-proxy/sow-rest ~/sow-rest && cd ~/sow-rest/kubernetes
bash ./deploy.sh
echo -e "\n\n############################\n\n"
echo "Visit http://$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')"
echo -e "\n\n############################\n\n"
