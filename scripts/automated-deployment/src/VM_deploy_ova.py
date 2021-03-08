#!/usr/bin/env python
"""
Script to deploy ova to esxi server and also power it on after deployment.
"""
import atexit
import os
import os.path
import ssl
import sys
import time

from argparse import ArgumentParser
from getpass import getpass

from .tools import cli

from pyVim.connect import SmartConnectNoSSL, Disconnect
from pyVmomi import vim, vmodl

# from .ovf_handler import OvfHandler
from k8_vmware.vsphere.ova_utils.OVA import OVA
from k8_vmware.vsphere.ova_utils.OVF_Handler import Ovf_Hanlder
from k8_vmware.vsphere.Sdk import Sdk

from ..config import Config


class VMDeployOVA:

    def __init__(self):
        self.sdk = Sdk()
        self.__config = Config()
    
        # print(self.args.host, args.user, args.password, args.port)
        try:
            self.si = SmartConnectNoSSL(host=self.__config.VSPHERE_HOST,
                                        user=self.__config.VSPHERE_USERNAME,
                                        pwd=self.__config.VSPHERE_PASSWORD,
                                        port=self.__config.PORT)

            atexit.register(Disconnect, self.si)

            print("connected successfully to esxi server %s!" % self.__config.VSPHERE_HOST)
        
        except Exception as e:
            
            print("Unable to connect to %s" % self.__config.VSPHERE_HOST)
            raise e

    @staticmethod
    def get_dc(si, name):
        """
        Get a datacenter by its name.
        """
        for dc in si.content.rootFolder.childEntity:
            if dc.name == name:
                return dc
        raise Exception('Failed to find datacenter named %s' % name)

    @staticmethod
    def get_rp(si, dc, name):
        """
        Get a resource pool in the datacenter by its names.
        """
        viewManager = si.content.viewManager
        containerView = viewManager.CreateContainerView(dc, [vim.ResourcePool],
                                                        True)
        try:
            for rp in containerView.view:
                if rp.name == name:
                    return rp
        finally:
            containerView.Destroy()
        raise Exception("Failed to find resource pool %s in datacenter %s" %
                        (name, dc.name))

    @staticmethod
    def get_largest_free_rp(si, dc):
        """
        Get the resource pool with the largest unreserved memory for VMs.
        """
        viewManager = si.content.viewManager
        containerView = viewManager.CreateContainerView(dc, [vim.ResourcePool],
                                                        True)
        largestRp = None
        unreservedForVm = 0
        try:
            for rp in containerView.view:
                if rp.runtime.memory.unreservedForVm > unreservedForVm:
                    largestRp = rp
                    unreservedForVm = rp.runtime.memory.unreservedForVm
        finally:
            containerView.Destroy()
        if largestRp is None:
            raise Exception("Failed to find a resource pool in dc %s" % dc.name)
        return largestRp

    @staticmethod
    def get_ds(dc, name):
        """
        Pick a datastore by its name.
        """
        for ds in dc.datastore:
            try:
                if ds.name == name:
                    return ds
            except:  # Ignore datastores that have issues
                pass
        raise Exception("Failed to find %s on datacenter %s" % (name, dc.name))


    @staticmethod
    def get_largest_free_ds(dc):
        """
        Pick the datastore that is accessible with the largest free space.
        """
        largest = None
        largestFree = 0
        for ds in dc.datastore:
            try:
                freeSpace = ds.summary.freeSpace
                if freeSpace > largestFree and ds.summary.accessible:
                    largestFree = freeSpace
                    largest = ds
            except:  # Ignore datastores that have issues
                pass
        if largest is None:
            raise Exception('Failed to find any free datastores on %s' % dc.name)
        return largest

    def power_on_vm(self, host, user, pwd, vm_name):

        try:
            vm = self.sdk.find_by_name(vm_name)
            vm.task().power_on()
        except Exception as e:
            print(e)
            raise e
        
        return 0

    def deploy(self):
        
        # vm name
        if self.__config.VM_NAME:
            vm_name = self.__config.VM_NAME
        else:
            vm_name = ""

        # get datacenter
        if self.__config.DATACENTER:
            dc = self.sdk.datacenter()
        else:
            dc = self.si.content.rootFolder.childEntity[0]
        
        # define datastore
        if self.__config.DATASTORE:
            ds = self.sdk.datastore()
        else:
            ds = VMDeployOVA.get_largest_free_ds(dc)

        # get resource pool from args or get the largest
        if self.__config.RESOURCE_POOL:
            rp = get_rp(si, dc, self.__config.resource_pool)
        else:
            rp = VMDeployOVA.get_largest_free_rp(self.si, dc)

        # pass the ova tarball to ovfhandler
        ovf_handle = Ovf_Handler(self.__config.OVA_PATH)

        ovfManager = self.si.content.ovfManager
        # CreateImportSpecParams can specify many useful things such as
        # diskProvisioning (thin/thick/sparse/etc)
        # networkMapping (to map to networks)
        # propertyMapping (descriptor specific properties)
        cisp = vim.OvfManager.CreateImportSpecParams(entityName=vm_name)
        cisr = ovfManager.CreateImportSpec(ovf_handle.get_descriptor(),
                                        rp, ds, cisp)

        # These errors might be handleable by supporting the parameters in
        # CreateImportSpecParams
        if len(cisr.error):
            print("The following errors will prevent import of this OVA:")
            for error in cisr.error:
                print("%s" % error)
            return 1

        ovf_handle.set_spec(cisr)

        lease = rp.ImportVApp(cisr.importSpec, dc.vmFolder)
        while lease.state == vim.HttpNfcLease.State.initializing:
            print("Waiting for lease to be ready...")
            time.sleep(1)

        if lease.state == vim.HttpNfcLease.State.error:
            print("Lease error: %s" % lease.error)
            return 1
        if lease.state == vim.HttpNfcLease.State.done:
            return 0

        print("Starting deploy...")
        print("ovf_handle:", ovf_handle)
        
        try:
            ovf_handle.upload_disks(lease, self.__config.VSPHERE_HOST)
        except Exception as e:
            print("Got exception %s while uploading ova to disk." % e)
            raise e

    def main(self):

        # deploy the ova
        self.deploy() 
        # ova = OVA() # TODO: edit k8-vmware upload-ova method with entity name param
        # ova.upload_ova(self.__config.OVA_PATH, vm_name=self.__config.VM_NAME)

        # power on the vm
        return(self.power_on_vm(self.__config.VSPHERE_HOST, 
                                self.__config.VSPHERE_USERNAME, 
                                self.__config.VSPHERE_PASSWORD, 
                                self.__config.VM_NAME))


if __name__ == "__main__":

    exit(VMDeployOVA().main())
