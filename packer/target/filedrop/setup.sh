#!/bin/bash
bash <( curl -sfL https://get.k3s.io )
bash <( curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 )
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER
git clone --single-branch https://github.com/k8-proxy/k8-rebuild
sed -i.bak "/NodePort/ a \  nodePorts:\n    http: 30080" k8-rebuild/kubernetes/values.yaml 
cat >> k8-rebuild/kubernetes/values.yaml <<EOF

sow-rest-api:
  image:
    registry: docker.io
    repository: k8serviceaccount/sow-rest-api
    tag: latest

sow-rest-ui:
  image:
    registry: docker.io
    repository: k8serviceaccount/sow-rest-ui
    tag: latest
EOF
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install sow-rest k8-rebuild/kubernetes/
echo -e "\n\n############################\n\n"
echo "Visit http://$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'):30080"
echo -e "\n\n############################\n\n"
