from os import environ
from dotenv import load_dotenv

class Config():

    def __init__(self):
        load_dotenv()

    def graphana_api_details(self):
        return {
                    "host"    : environ.get('GRAFANA_HOST'),
                    "api_key": environ.get('GRAFANA_API_KEY'),
                    "auth_key": environ.get('GRAFANA_AUTH_KEY'),
                    "username": environ.get('GRAFANA_USERNAME'),
                    "password": environ.get('GRAFANA_PASSWORD')
                }

    def grafana_test_details(self):
        return {
            "dashboard_json" : {'dashboard': 
                                    {
                                        'id': 15,
                                        'refresh': '25s',
                                        'schemaVersion': 16,
                                        'tags': ['templated'],
                                        'timezone': 'browser',
                                        'title': 'Testing dashboard 2',
                                        'uid': 'ehjkdlYGz',
                                        'version': 1
                                    },
                                'meta': {
                                    'canAdmin': True,
                                    'canEdit': True,
                                    'canSave': True,
                                    'canStar': True,
                                    'created': '2021-02-05T03:44:55+05:30',
                                    'createdBy': 'admin',
                                    'expires': '0001-01-01T00:00:00Z',
                                    'folderId': 0,
                                    'folderTitle': 'General',
                                    'folderUrl': '',
                                    'hasAcl': False,
                                    'isFolder': False,
                                    'provisioned': False,
                                    'provisionedExternalId': '',
                                    'slug': 'testing-dashboard-2',
                                    'type': 'db',
                                    'updated': '2021-02-05T03:44:55+05:30',
                                    'updatedBy': 'admin',
                                    'url': '/d/ehjkdlYGz/testing-dashboard-2',
                                    'version': 1
                                }
                            }
        }

