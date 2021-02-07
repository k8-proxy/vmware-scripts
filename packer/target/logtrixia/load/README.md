## Simulate load against icap-server
### Execute 100 request load.sh
```
$ bash load.sh <ICAP_SERVER/HAPROXY> result.log 100
```
### Check result.log
```
2021-01-24T01:12:45Z,18.203.254.222,20fde0d2-9cca-4207-85f3-e0083af276fa,	HTTP/1.0 200 OK,114967.000
2021-01-24T01:12:46Z,18.203.254.222,eadaeb35-6c20-4657-89bb-da7c1ccc530c,	HTTP/1.0 403 Forbidden,116182.000
```
Format: timestamp, ip address, uuid, status code, elapsed time

