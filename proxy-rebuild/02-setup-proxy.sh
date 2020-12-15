#!/bin/bash

read -p "Enter the IP address of ICAP server: " ICAP_IP
ICAP_IP=${ICAP_IP}

if [[ -z "$ICAP_IP" ]]; then
  echo "Please pass IP address of ICAP server."
  exit -1
fi

read -p "Enter the IP address of gov.uk website [151.101.0.144] : " GOVUK_IP
GOVUK_IP=${GOVUK_IP:-151.101.0.144}
GOVUK_IP=$(echo $GOVUK_IP | sed 's|\.|\\.|g')

read -p "Enter the IP address of wordpress website [192.0.78.17] : " WORDPRESS_IP
WORDPRESS_IP=${WORDPRESS_IP:-192.0.78.17}
WORDPRESS_IP=$(echo $WORDPRESS_IP | sed 's|\.|\\.|g')

key=$(cat ./server.key | base64 | tr -d '\n')
crt=$(cat ./server.crt | base64 | tr -d '\n')

helm upgrade --install \
--set image.nginx.repository=pranaysahith/reverse-proxy-nginx \
--set image.nginx.tag=0.0.1 \
--set image.squid.repository=pranaysahith/reverse-proxy-squid \
--set image.squid.tag=0.0.8 \
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
reverse-proxy /home/glasswall/s-k8-proxy-rebuild/stable-src/chart/

echo ""
echo "Add below line to your system's host file and browse the websites in the firefox"
echo "vm_ip_address glasswallsolutions.com www.glasswallsolutions.com example.local www.example.local gov.uk www.gov.uk assets.publishing.service.gov.uk owasp.org www.owasp.org"
