from generator import Generator
from elasticsearch import Elasticsearch
es = Elasticsearch(['http://user:secret@91.109.26.22:9200'])

g = Generator()
#payload = g.get_payload()
#print(payload)
g.load(es, 1000000)
