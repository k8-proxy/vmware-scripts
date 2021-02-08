from .base import Base
from grafana_api.grafana_face import GrafanaFace

class GraphanaUser(Base):

    def __init__(self):
        super(GraphanaDashboard, self).__init__()
        self.grafana_api = self.login(auth_type="credentials")

    def create(self):
        # Create user
        user = self.grafana_api.admin.create_user({"name": "User", "email": "user@domain.com", "login": "user", "password": "userpassword", "OrgId": 1})
        return user
    
    def change_password(self):   
        # Change user password
        user = self.grafana_api.admin.change_user_password(2, "newpassword")
        return user

    def find_by_email(self)
        # Find a user by email
        user = self.grafana_api.users.find_user('test@test.com')
        return user

    def add_team_member(self):
        # Add user to team 2
        member = self.grafana_api.teams.add_team_member(2, user["id"])
        return member


        