#!/usr/bin/env python

"""Grafana dashboard exporter"""

import json
import os
import requests
from ..config import Config


class ExportDashboard:

    def __init__(self, dashboard_id=None):
        self.host = Config().graphana_api_details()["host"]
        self.api_key = Config().graphana_api_details()["api_key"]

        self.DIR = 'exported-dashboards/'

        self.headers = {'Authorization': 'Bearer %s' % (API_KEY,)}
        self.dashboard_id = dashboard_id

    def export_dashboards(self):
        
        response = requests.get('%s/api/search?query=&' % (self.host,), headers=self.headers)
        response.raise_for_status()
        dashboards = response.json()

        if not os.path.exists(self.DIR):
            os.makedirs(self.DIR)

        try:
            for d in dashboards:
                print("Saving: " + d['title'])
                response = requests.get('%s/api/dashboards/%s' % (self.host, d['uri']), headers=self.headers)
                data = response.json()['dashboard']
                dash = json.dumps(data, sort_keys=True, indent=4, separators=(',', ': '))
                name = data['title'].replace(' ', '_').replace('/', '_').replace(':', '').replace('[', '').replace(']', '')
                tmp = open(self.DIR + name + '.json', 'w')
                tmp.write(dash)
                tmp.write('\n')
                tmp.close()
        
        Exception as e:
            print("Exception faced: %s" % e)
        
        print("Exported dashboard successfuly to %s." % self.DIR)

    def main():
        dashboard = ExportDashboard()
        dashboard.export_dashboard()


if __name__ == '__main__':
    main()