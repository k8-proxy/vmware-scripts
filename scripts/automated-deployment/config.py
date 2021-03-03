import os

from os import environ
from dotenv import load_dotenv

load_dotenv()

class Config():

    # vsphere server cred
    VSPHERE_HOST     = environ.get('VSPHERE_HOST')
    VSPHERE_USERNAME = environ.get('VSPHERE_USERNAME')
    VSPHERE_PASSWORD = environ.get('VSPHERE_PASSWORD')

    PORT = environ.get('SERVER_PORT', '443')

    # vsphere vm account cred
    VM_NAME     = environ.get('VM_NAME')
    VM_USERNAME = environ.get('VM_USERNAME')
    VM_PASSWORD = environ.get('VM_PASSWORD')

    # esxi ssh config
    SSH_HOST = environ.get('VSPHERE_HOST' )
    SSH_USER = environ.get('ESXI_SSH_USER')
    SSH_KEY  = environ.get('ESXI_SSH_KEY' )

    # ova path
    OVA_PATH = environ.get('OVA_PATH')

    # upload file to vm config
    UPLOAD_PATH_INSIDE_VM = environ.get('VM_UPLOAD_PATH')
    UPLOAD_FILE_NAME = environ.get('UPLOAD_FILE_NAME')

    # network configuration
    VM_IP            = os.environ.get('VM_IP')
    VM_GATEWAY       = os.environ.get('VM_GATEWAY')
    VM_DNS           = os.environ.get('VM_DNS')
    VM_SUDO_PASSWORD = os.environ.get('VM_SUDO_PASSWORD')
    VM_TO_FIND       = os.environ.get('VM_TO_FIND')

    DATACENTER       = os.environ.get('DATACENTER')
    DATASTORE        = os.environ.get('DATASTORE')
    RESOURCE_POOL    = os.environ.get('RESOURCE_POOL')

    def vsphere_host(self):
        return self.vsphere_server_details().get('host')

    def vsphere_set_server_details(self, host=None, username=None, password=None):
        if host:
            environ['VSPHERE_HOST'] = host
        if username:
            environ['VSPHERE_USERNAME'] = username
        if password:
            environ['VSPHERE_PASSWORD'] = password
        return self.vsphere_server_details()

