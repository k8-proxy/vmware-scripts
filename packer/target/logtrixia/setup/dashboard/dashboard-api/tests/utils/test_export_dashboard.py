import unittest
from ...src.utils.export_dashboards import ExportDashboard

class TestExportDashboard(unittest.TestCase):

    def setUp(self):
        self.dashboard_obj = ExportDashboard()

    def test_export_dasboard(self):
        self.dashboard_obj.export_dashboard()



