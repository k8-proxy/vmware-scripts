#!/bin/bash
pushd $( dirname $0 )

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
# install k3s (kubectl included)
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube && sudo install -T /etc/rancher/k3s/k3s.yaml ~/.kube/config -m 600 -o $USER

# install helm
curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Done installing helm"

# install docker
curl https://get.docker.com | bash 


#sudo tee /etc/docker/daemon.json <<EOF
#{
#  "registry-mirrors": ["http://localhost:30500"]
#}
#EOF

git clone https://github.com/k8-proxy/k8-reverse-proxy.git --recursive --single-branch --depth 1 && pushd k8-reverse-proxy/stable-src && git submodule foreach git pull origin main
# install local docker registry
sudo docker run -d -p 30500:5000 --restart always --name registry registry:2

# build images
sudo docker build nginx/ -t localhost:30500/reverse-proxy-nginx
sudo docker push localhost:30500/reverse-proxy-nginx

sudo docker build squid/ -t localhost:30500/reverse-proxy-squid
sudo docker push localhost:30500/reverse-proxy-squid
#sudo rm -f /etc/docker/daemon.json

popd

git clone https://github.com/k8-proxy/s-k8-proxy-rebuild.git ~/s-k8-proxy-rebuild --recursive --single-branch --depth 1 && pushd s-k8-proxy-rebuild/stable-src && git submodule foreach git pull origin main && popd
git clone https://github.com/k8-proxy/vmware-scripts.git --recursive --single-branch --depth 1 && pushd vmware-scripts/proxy-rebuild && git submodule foreach git pull origin main
bash gencert.sh
cp ca.pem ~/ca.pem
ICAP_IP=${ICAP_IP:-78.159.113.46}
GOVUK_IP=${GOVUK_IP:-151.101.0.144}
GOVUK_IP=$(echo $GOVUK_IP | sed 's|\.|\\.|g')
WORDPRESS_IP=${WORDPRESS_IP:-192.0.78.17}
WORDPRESS_IP=$(echo $WORDPRESS_IP | sed 's|\.|\\.|g')

key=$(cat ./server.key | base64 | tr -d '\n')
crt=$(cat ./server.crt ./ca.pem | base64 | tr -d '\n')

helm upgrade --install \
--set image.nginx.repository=localhost:30500/reverse-proxy-nginx \
--set image.nginx.tag=latest \
--set image.squid.repository=localhost:30500/reverse-proxy-squid \
--set image.squid.tag=latest \
--set application.nginx.env.ALLOWED_DOMAINS='glasswallsolutions.com\,www.glasswallsolutions.com\,example.local\,www.example.local\,gov.uk\,www.gov.uk\,assets.publishing.service.gov.uk\,owasp.org\,www.owasp.org' \
--set application.nginx.env.ROOT_DOMAIN='glasswall-icap.com' \
--set application.nginx.env.SUBFILTER_ENV='' \
--set application.squid.env.ALLOWED_DOMAINS='glasswallsolutions.com\,www.glasswallsolutions.com\,example.local\,www.example.local\,gov.uk\,www.gov.uk\,assets.publishing.service.gov.uk\,owasp.org\,www.owasp.org' \
--set application.squid.env.ROOT_DOMAIN='glasswall-icap.com' \
--set application.squid.env.ICAP_URL="icap://$ICAP_IP:1344/gw_rebuild" \
--set application.squid.env.ICAP_ALLOW_ONLY_MIME_TYPE='application/pdf' \
--set service.nginx.additionalHosts={"glasswallsolutions.com"\,"www.glasswallsolutions.com"\,"example.local"\,"www.example.local"\,"gov.uk"\,"www.gov.uk"\,"owasp.org"\,"www.owasp.org"\,"assets.publishing.service.gov.uk"} \
--set hostAliases.\""$WORDPRESS_IP"\"={"www.example.local"\,"example.local"} \
--set hostAliases.\""$GOVUK_IP"\"={"www.gov.uk"\,"gov.uk"\,"assets.publishing.service.gov.uk"} \
--set ingress.tls.crt=$crt \
--set ingress.tls.key=$key \
reverse-proxy ~/s-k8-proxy-rebuild/stable-src/chart/
rm -rf ~/s-k8-proxy-rebuild
