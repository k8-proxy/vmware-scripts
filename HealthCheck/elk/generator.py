import datetime
import random
import numpy 
import time

class Generator:
    def get_payload(self):
        service_list = [
            'icap',
            'k8-rebuild',
            'k8-proxy'
        ]
        result_list = [
            'PASS',
            'FAIL'
        ]
        host_list = [
            'ubuntu-ireland',
            'ubuntu-frankfurt',
            'ubuntu-london'
        ]
        error_list = [
            'service is unreachable',
            'network exception',
            'system exception'
        ]
        service = random.choice(service_list)
        rtt = numpy.random.normal(10, 3, 1)[0]
        result = random.choices(result_list, weights=(80, 20), k=1)[0]
        if result == 'FAIL':
            error = random.choice(error_list)
        else:
            error = None
        host = random.choice(host_list)
        ts = datetime.datetime.utcnow().isoformat()
        payload={
            'service': service,
            'rtt': rtt,
            'result': result,
            'error': error,
            'host': host,
            '@timestamp': ts
        }
        return payload

    def load(self, es, number):
        for i in range(number):
            payload = self.get_payload()
            random_wait = random.randint(10,100)
            #print(payload)
            time.sleep(random_wait/1000)
            es.index(index='healthcheck', body=payload)