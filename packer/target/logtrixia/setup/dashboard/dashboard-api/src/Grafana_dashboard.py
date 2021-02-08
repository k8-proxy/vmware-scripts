import json
from ..config import Config
from .base import Base
from grafana_api.grafana_face import GrafanaFace


class GraphanaDashboard(Base):

    def __init__(self):
        
        super(GraphanaDashboard, self).__init__()
        self.grafana_api = self.login(auth_type="credentials")

    def create_or_update(self, dashboard={'dashboard': {...}, 'folderId': 0, 'overwrite': True}):
        """
        :param dashboard:
        :return:

        example dashboard arg:
            dashboard = {
                "dashboard": {
                    "id": None,
                    "uid": None,
                    "title": "Testing dashboard api 2",
                    "tags": [ "templated" ],
                    "timezone": "browser",
                    "schemaVersion": 16,
                    "version": 0,
                    "refresh": "25s"
                },
                "folderId": 0,
                "overwrite": False
            }
        """
        # Create or Update a dashboard with the dashboard json
        print(GrafanaFace)
        try:
            updated_dashboard = self.grafana_api.dashboard.update_dashboard(dashboard=dashboard)
        except Exception as e:
            print("Got error: %s" % e)

        return updated_dashboard

    def import_dashboard(self, dashboard={'dashboard': {...}, 'folderId': 0, 'overwrite': True}):
        """
        import a dashboard using dashboard object.
        """
        # make id value as None before creating the dashboard
        dashboard["dashboard"]["id"] = None
        try:
            imported_dashboard = self.create_or_update(dashboard=dashboard)
        except Exception as e:
            print("Got error: %s" % e)
        
        return imported_dashboard

    def get_by_tag(self, tag="applications"):
        # Search dashboards based on tag
        try:
            dashboard = self.grafana_api.search.search_dashboards(tag=tag)
        except Exception as e:
            print("Error: %s" % e)
            
        return dashboard

    def get(self, dashboard_uid):
        """
        :param dashboard_uid:
        :return:
        """
        try:
            dashboard = self.grafana_api.dashboard.get_dashboard(dashboard_uid=dashboard_uid)
        except Exception as e:
            print("Error: %s" % e)
        
        return dashboard

    def delete(self, dashboard_uid='abcdefgh'):
        """
        :param dashboard_uid:
        :return:
        """
        # Delete a dashboard by UID
        try:
            deleted_dashboard = self.grafana_api.dashboard.delete_dashboard(dashboard_uid=dashboard_uid)
        except Exception as e:
            print("Error: %s" % e)
        
        return deleted_dashboard

    def get_home_dashboard(self):
        """
        :return: dashboard
        """
        try:
            dashboard = self.grafana_api.dashboard.get_home_dashboard()
        except Exception as e:
            print("Error: %s" % e)
        
        return dashboard

    def get_tags(self):
        """
        :return:
        """
        try:
            dashboard_tags = self.grafana_api.dashboard.get_dashboard_tags()
        except Exception as e:
            print("Error: %s" % e)

        return dashboard_tags

    def get_permissions(self, dashboard_id):
        """
        :param dashboard_id:
        :return:
        """
        try:
            dashboard_permissions = self.grafana_api.dashboard.get_dashboard_permissions(dashboard_id=dashboard_id)
        except Exception as e:
            print("Error: %s" % e)

        return dashboard_permissions

    def update_permissions(self, dashboard_id, items):
        """
        :param dashboard_id:
        :param items:
        :return:
        """
        try:
            dashboard_permissions = self.grafana_api.dashboard.update_dashboard_permissions(dashboard_id=dashboard_id, items=items)
        except Exception as e:
            print("Error: %s" % e)
        
        return dashboard_permissions


  