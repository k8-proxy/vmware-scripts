import datetime
import random
from elasticsearch import Elasticsearch
es = Elasticsearch(['http://user:secret@91.109.26.22:9200'])
ts = datetime.datetime.utcnow().isoformat()
payload={
    'service': 'ping 8.8.8.8',
    'rtt': 12.34,
    'result': 'PASS',
    'host': 'ubuntu',
    '@timestamp': ts
}
es.index(index='healthcheck', body=payload)