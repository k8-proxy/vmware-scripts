from __future__ import with_statement
import os
import atexit
import re
import time
from ..tools import cli
from pyVim import connect
from pyVmomi import vim, vmodl

from .get_vm_info import GetVMInfo

from k8_vmware.vsphere.VM_Keystroke import VM_Keystroke
from k8_vmware.vsphere.VM_Screenshot import VM_Screenshot
from k8_vmware.vsphere.Sdk import Sdk

from ...config import Config


class VMExecuteScript: 

    def __init__(self):

        self.__config = Config()

        self.sdk = Sdk()

        # get network config variables
        self.vm_ip = self.__config.VM_IP
        self.vm_gateway = self.__config.VM_GATEWAY
        self.vm_dns = self.__config.VM_DNS
        self.vm_sudo_pwd = self.__config.VM_SUDO_PASSWORD

        try:
            self.service_instance = connect.SmartConnectNoSSL(host=self.__config.VSPHERE_HOST,
                                                            user=self.__config.VSPHERE_USERNAME,
                                                            pwd=self.__config.VSPHERE_PASSWORD,
                                                            port=self.__config.PORT)

            atexit.register(connect.Disconnect, self.service_instance)
            print("connected successfully to esxi server %s!" % self.__config.VSPHERE_HOST)
        
        except Exception as e:     
            print("Unable to connect to %s" % self.__config.VSPHERE_HOST)
            return

    def get_instance_uuid(self):
        vm_info_data = GetVMInfo(si=self.service_instance).main()
        print(vm_info_data)
        inst_uuid = vm_info_data.get("instance_uuid")
        return inst_uuid

    def execute_program(self, content, vm, creds):
        try:
            # initialize process manager
            pm = content.guestOperationsManager.processManager
            
            # getting ready to send the command through keystroke interaction
            ks_inst = VM_Keystroke(vm)

            # convert the bash file from dos to unix
            ps = vim.vm.guest.ProcessManager.ProgramSpec(
                programPath="/usr/bin/sed", #TODO: get these values from config
                arguments="-i 's/\r$//' %s" % "/home/glasswall/network.sh"
            )
            res = pm.StartProgramInGuest(vm.vm, creds, ps)

            command = "/usr/bin/sudo /usr/bin/bash /home/glasswall/network.sh %s %s %s" % (self.vm_ip, self.vm_gateway, self.vm_dns)
            res = ks_inst.send_text(command).enter().send_text(self.vm_sudo_pwd).enter()

            print("finishing task :%s!" % res)
            return res

            # TODO: Not necessary right now, can be used later on to track errors
            # if res > 0:
            #     print("Program submitted, PID is %d" % res)
            #     pid_exitcode = pm.ListProcessesInGuest(vm, creds,
            #                                            [res]).pop().exitCode
            #     # If its not a numeric result code, it says None on submit
            #     while (re.match('[^0-9]+', str(pid_exitcode))):
            #         print("Program running, PID is %d" % res)
            #         time.sleep(5)
            #         pid_exitcode = pm.ListProcessesInGuest(vm, creds,
            #                                                [res]).pop().\
            #             exitCode
            #         if (pid_exitcode == 0):
            #             print("Program %d completed with success" % res)
            #             break
            #         # Look for non-zero code to fail
            #         elif (re.match('[1-9]+', str(pid_exitcode))):
            #             print("ERROR: Program %d completed with Failute" % res)
            #             print("  tip: Try running this on guest %r to debug" \
            #                 % summary.guest.ipAddress)
            #             print("ERROR: More info on process")
            #             print(pm.ListProcessesInGuest(vm, creds, [res]))
            #             break
        
        except IOError as e:
                print(e)

    def main(self):
        """
        Simple command-line program for executing a process in the VM without the
        network requirement to actually access it.
        """

        instance_uuid = self.get_instance_uuid()
        try:
            content = self.service_instance.RetrieveContent()

            # if instanceUuid is false it will search for VM BIOS UUID instead
            # vm = content.searchIndex.FindByUuid(datacenter=None,
            #                                     uuid=instance_uuid,
            #                                     vmSearch=True,
            #                                     instanceUuid=True)
            vm = self.sdk.find_by_uuid(instance_uuid)

            if not vm:
                raise SystemExit("Unable to locate the virtual machine.")

            tools_status = vm.vm.guest.toolsStatus
            if (tools_status == 'toolsNotInstalled' or
                    tools_status == 'toolsNotRunning'):
                raise SystemExit(
                    "VMwareTools is either not running or not installed. "
                    "Rerun the script after verifying that VMwareTools "
                    "is running")

            creds = vim.vm.guest.NamePasswordAuthentication(
                username=self.__config.VM_USERNAME, password=self.__config.VM_PASSWORD
            )

            print(vm.vm)
            result = self.execute_program(content, vm, creds)
            print("Finished with executing script: %s" % result)

        except vmodl.MethodFault as error:
            print("Caught vmodl fault : " + error.msg)
            return -1

        return 0

# Start program
if __name__ == "__main__":
    VMExecuteScript().main()