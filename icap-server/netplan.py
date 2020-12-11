import yaml
import os
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("--ipaddress", "-i", help="ip address")
parser.add_argument("--gateway", "-g", help="gateway address")

args = parser.parse_args()

with open(r'/etc/netplan/01-netcfg.yaml') as netplan_file:
    netplan_dict = yaml.load(netplan_file, Loader=yaml.FullLoader)

if netplan_dict:
    if args.ipaddress and args.gateway:
        if netplan_dict['network']['ethernets']['ens160']['addresses'][0] !=  args.ipaddress and netplan_dict['network']['ethernets']['ens160']['gateway4'] != args.gateway:
            netplan_dict['network']['ethernets']['ens160']['addresses'][0] = args.ipaddress
            netplan_dict['network']['ethernets']['ens160']['gateway4'] = args.gateway
            with open(r'/etc/netplan/01-netcfg.yaml', 'w') as netplan_file:
                yaml.dump(netplan_dict, netplan_file)
                print ("Successfully updated netplan file")
                os.system('netplan apply')
                print ("Netplan configuration applied")
        else:
            print ("Network configuration has already been set - reapplying")
            os.system('netplan apply')
