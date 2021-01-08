#!/bin/bash

pushd ssl
bash gencert.sh 
crt=$(base64 -w0 server.crt)
key=$(base64 -w0 server.key)
popd

# install k3s
curl -sfL https://get.k3s.io | sh -
mkdir ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install kubectl and helm
sudo curl -L "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl
echo "Done installing kubectl"

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# get source code
git clone https://github.com/k8-proxy/s-k8-proxy-rebuild.git --recursive --single-branch --depth 1 && pushd s-k8-proxy-rebuild && git submodule foreach git pull origin main

curl https://get.docker.com | bash 

# install local docker registry
sudo docker run -d -p 30500:5000 --restart always --name registry registry:2

# build images
pushd stable-src
docker build nginx -t localhost:30500/reverse-proxy-nginx:0.0.1
docker push localhost:30500/reverse-proxy-nginx:0.0.1

docker build squid -t localhost:30500/reverse-proxy-squid:0.0.1
docker push localhost:30500/reverse-proxy-squid:0.0.1

sed -i.orig 's/<docker registry>/localhost:30500/g' chart/values.yaml


# install UI and API helm charts
helm upgrade --install --atomic \
--set image.nginx.repository=localhost:30500/reverse-proxy-nginx \
--set image.nginx.tag=0.0.1 \
--set image.squid.repository=localhost:30500/reverse-proxy-squid \
--set image.squid.tag=0.0.1 \
--set image.icap.repository=localhost:30500/reverse-proxy-c-icap \
--set image.icap.tag=0.0.1 \
--set ingress.tls.crt=$crt \
--set ingress.tls.key=$key \
reverse-proxy chart/
