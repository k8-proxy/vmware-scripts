## Dashboard 
## Export 
```
curl --user httpuser:httppass \
'http://91.109.26.22:8881/api/kibana/dashboards/export?dashboard=6bc74ce0-55e4-11eb-bdf6-c7f1cb7a4637' > healthcheck.json
```
## Import
```
curl -X POST --user httpuser:httppass \
-H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
'http://91.109.26.22:8881/api/kibana/dashboards/import' \
-d @healthcheck.json
```
