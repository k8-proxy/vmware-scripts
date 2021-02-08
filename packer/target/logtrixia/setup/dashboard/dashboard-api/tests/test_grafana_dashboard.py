from pprint import pprint
from unittest import TestCase
from ..src.Graphana_dashboard import GraphanaDashboard
from ..config import Config


class TestGrafanaDashboard(TestCase):

    def setUp(self):
        self.__config = Config()
        self.__grafana_test_details = self.__config.grafana_test_details()
        self.grafana_dashboard = GraphanaDashboard()
        self.dashboard_json = {
                        "dashboard": {
                            "id": None,
                            "uid": None,
                            "title": "Testing dashboard 2",
                            "tags": [ "templated" ],
                            "timezone": "browser",
                            "schemaVersion": 16,
                            "version": 0,
                            "refresh": "25s"
                        },
                        "folderId": 0,
                        "overwrite": False
                    }

        self.dashboard_id = "ehjkdlYGz"

    def test_create_dashboard(self):
        dashboard = self.grafana_dashboard.create_or_update(dashboard=self.dashboard_json)
        pprint(dashboard)

        self.assertIsNotNone(dashboard["id"]) 

    def test_update_dashboard(self):
        dashboard = self.grafana_dashboard.create_or_update(dashboard=self.dashboard_json)
        pprint(dashboard)

    def test_get_dashboard(self):
        dashboard = self.grafana_dashboard.get(dashboard_uid=self.dashboard_id)
        pprint(dashboard)

    def test_import_dashboard(self):
        # get dashboard
        # create dashboard with the json object
        dashboard_json = self.__grafana_test_details.get("dashboard_json")

        dashboard = self.grafana_dashboard.import_dashboard(dashboard=dashboard_json)
        print(dashboard)     

    def test_delete_dashboard(self):
        deleted_dashboard =  self.grafana_dashboard.delete(dashboard_uid=self.dashboard_id)
        pprint(deleted_dashboard)
