# This script deletes VMs that it's age exceeds the number of expire days defined in scripts/script.env file
# Except for the VMs with note that include (dont_rm_note) variable defined in scripts/script.env file
# Also will delete any VM with note that include (rm_note) variable defined in scripts/script.env file
# A list of the removed VMs will be printed
from os import environ
from pathlib import Path, PurePath
import pytz
import sys
from datetime import timedelta, datetime
from dotenv import load_dotenv
from k8_vmware.vsphere.Sdk import Sdk
from k8_vmware.vsphere.VM import VM
env_path= PurePath(__file__).parent / 'script.env'
load_dotenv(dotenv_path=env_path)
load_dotenv()
rm_note=environ.get('rm_note')
dont_rm_note=environ.get('dont_rm_note')
expire_days_no=environ.get('expire_days_no','')
if not expire_days_no.isdigit():
    print(" Expire days number must be integer")
    sys.exit(1)
expire_days_no=int(expire_days_no)
sdk = Sdk()
vms_o = sdk.get_objects_Virtual_Machines()
removed_VMs = []
now = datetime.now(pytz.utc)
for vm_o in vms_o:
    vm = VM(vm_o)
    summary = vm.summary()
    info = vm.info()
    state=summary.runtime.powerState
    notes  = summary.config.annotation
    create_date=vm_o.config.createDate
    if create_date < datetime(2000,1,1):
        continue
    if rm_note.lower() in notes.lower() or (create_date < (now - timedelta(days=expire_days_no)) and dont_rm_note.lower() not in notes.lower()):
      if state == 'poweredOn':
        vm.task().power_off()  
        vm.task().delete()
      removed_VMs.append(info["Name"])

if removed_VMs:
    print("Removed VMs: ")
    print("=============")
    print("\n".join(removed_VMs))
else:
    print("No VM was removed!")



