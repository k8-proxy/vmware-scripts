from ..config import Config
from grafana_api.grafana_face import GrafanaFace


class GrafanaDatasource:
    
    def __init__(self, api):
            
        grafana_api = GrafanaFace(
            auth=Config().graphana_api_details()["auth_key"], 
            host=Config().graphana_api_details()["host"]
            )
        # grafana_api = GrafanaFace(
        #   auth=("username","password"),
        #   host='api.my-grafana-host.com'
        #   )

    def get_by_id(self, datasource_id):
        """
        :param datasource_id:
        :return:
        """
        datasource = self.grafana_api.datasource.get_datasource_by_id(datasource_id=datasource_id)
        return datasource

    def get_by_name(self, datasource_name):
        """
        :param datasource_name:
        :return:
        """
        datasource = self.grafana_api.datasource.get_datasource_by_name(datasource_name=datasource_name)
        return datasource

    def get_id_by_name(self, datasource_name):
        """
        :param datasource_name:
        :return:
        """
        datasource = self.grafana_api.datasource.get_datasource_id_by_name(datasource_name=datasource_name)
        return datasource

    def create(self, datasource):
        """
        :param datasource:
        :return:
        """
        datasource = self.grafana_api.datasource.create_datasource(datasource=datasource)
        return datasource

    def update(self, datasource_id, datasource):
        """
        :param datasource_id:
        :param datasource:
        :return:
        """
        datasource = self.grafana_api.datasource.update_datasource(datasource_id=datasource, datasource=datasource)
        return datasource

    def list_all(self):
        """
        :return:
        """
        list_datasources = self.grafana_api.datasource.list_datasources()
        return list_datasources

    def delete_by_id(self, datasource_id):
        """
        :param datasource_id:
        :return:
        """
        datasource = self.grafana_api.datasource.delete_datasource_by_id(datasource_id=datasource_id)
        return datasource

    def delete_by_name(self, datasource_name):
        """
        :param datasource_name:
        :return:
        """
        datasource = self.grafana_api.datasource.delete_datasource_by_name(datasource_name=datasource_name)
        return datasource


