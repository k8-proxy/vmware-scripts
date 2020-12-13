#!/bin/bash

if [ -z $1 ]
then
  echo "Please give IP address of ICAP as argument"
  echo "Usage: $0 <ICAP server IP address> "
  exit -1
else
  ICAP_IP=$1
fi

helm upgrade --install \
--set image.nginx.repository=pranaysahith/reverse-proxy-nginx \
--set image.nginx.tag=0.0.1 \
--set image.squid.repository=pranaysahith/reverse-proxy-squid \
--set image.squid.tag=0.0.7 \
--set application.nginx.env.ALLOWED_DOMAINS='glasswallsolutions.com\,www.glasswallsolutions.com\,example.local\,www.example.local\,gov.uk\,www.gov.uk\,owasp.org\,www.owasp.org' \
--set application.nginx.env.ROOT_DOMAIN='glasswall-icap.com' \
--set application.nginx.env.SUBFILTER_ENV='' \
--set application.squid.env.ALLOWED_DOMAINS='glasswallsolutions.com\,www.glasswallsolutions.com\,example.local\,www.example.local\,gov.uk\,www.gov.uk\,owasp.org\,www.owasp.org' \
--set application.squid.env.ROOT_DOMAIN='glasswall-icap.com' \
--set application.squid.env.ICAP_URL="icap://$ICAP_IP:1344/gw_rebuild" \
--set application.squid.env.ICAP_ALLOW_ONLY_MIME_TYPE='application/pdf' \
--set service.nginx.additionalHosts={"glasswallsolutions.com"\,"www.glasswallsolutions.com"\,"example.local"\,"www.example.local"\,"gov.uk"\,"www.gov.uk"\,"owasp.org"\,"www.owasp.org"} \
--set hostAliases."78\\.159\\.113\\.39"={"www.example.local"\,"example.local"} \
--set hostAliases."151\\.101\\.0\\.144"={"www.gov.uk"\,"gov.uk"} \
reverse-proxy /home/glasswall/s-k8-proxy-rebuild/stable-src/chart/
