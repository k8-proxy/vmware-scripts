#!/usr/bin/env python3

import sys
import yaml
import ipaddress
import urllib.parse
import subprocess
import socket
import requests
import re
import logging
import random
import string
import hashlib
import os

def checksum(filename, hashfunc):
    with open(filename,"rb") as f:
        for byte_block in iter(lambda: f.read(4096),b""):
            hashfunc.update(byte_block)
    return hashfunc.hexdigest()

def main(args):
    retcode = 0

    FAIL = "\033[1;91m" + "FAIL" + "\033[0m"
    PASS = "\033[1;92m" + "PASS" + "\033[0m"

    SSLVerify = False
    logging.captureWarnings(True)

    with open('config.yml') as file:
        config = yaml.load(file, Loader=yaml.Loader)
    
    for i in config['hosts']:
        try:
            addr = i['address']
            try:
                addr = str(ipaddress.ip_address(addr))
            except ValueError:
                url = urllib.parse.urlparse(addr,scheme='http')
                if url.netloc=='' and url.path != '':
                    url = urllib.parse.urlparse(f'{url.scheme}://{url.path}')
                addr =  url.hostname
        except KeyError:
            continue

        if i['prot'] == 'icmp':
            print(f'ping       {addr:30}: ', end='', flush=True)
            cp = subprocess.run(['ping','-c1','-w2',addr],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            print(f'{FAIL if cp.returncode else PASS}')
            retcode = retcode + cp.returncode
        elif i['prot'] == "tcp":
            print(f'tcp/{i["tcpport"]:<6} {addr:30}: ', end='', flush=True)
            s = None
            for res in socket.getaddrinfo(addr, i['tcpport'], socket.AF_UNSPEC, socket.SOCK_STREAM):
                af, socktype, proto, canonname, sa = res
                try:
                    s = socket.socket(af, socktype, proto)
                    s.settimeout(5)
                except socket.error:
                    s = None
                    continue
                try:
                    s.connect(sa)
                except socket.error:
                    s.close()
                    s = None
                    continue
                break
            print(f'{PASS if s else FAIL}')
            retcode = retcode + (0 if s else  1)
            if s: s.close()
        elif i['prot'] == 'httpstatus':
            print(f'httpstatus {url.geturl():30}: ', end='', flush=True)
            r = requests.get(url.geturl(), verify=SSLVerify)
            print(f'{PASS if r.status_code==i["httpstatus"] else FAIL}')
            retcode = retcode + (0 if r.status_code==i["httpstatus"] else 1)
        elif i['prot'] == 'httpstring':
            print(f'httpstring {url.geturl():30}: ', end='', flush=True)
            r = requests.get(url.geturl(), verify=SSLVerify)
            print(f'{PASS if re.search(i["httpstring"],r.text) else FAIL}')
            retcode = retcode + (0 if re.search(i["httpstring"],r.text) else 1)
        elif i['prot'] == 'icap':
            print(f'icap       {addr:30}: ', end='', flush=True)
            suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
            cp = subprocess.run(['c-icap-client','-i',addr,'-s',i["icapservice"],'-f',i["icaptestfile"],'-o',i["icaptestfile"]+suffix],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            if cp.returncode == 0:
                if os.path.isfile(i['icaptestfile']+suffix):
                    c2 = checksum(i['icaptestfile']+suffix,hashlib.md5())
                    os.remove(i['icaptestfile']+suffix)
                    if checksum(i['icaptestfile'],hashlib.md5()) != c2:
                        print(PASS)
                        continue

            print(FAIL)
            retcode += 1
            continue

    return retcode

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
