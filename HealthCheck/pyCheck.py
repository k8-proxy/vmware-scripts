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
import time
import pathlib
from datetime import datetime

def checksum(filename, hashfunc):
    with open(filename, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            hashfunc.update(byte_block)
    return hashfunc.hexdigest()


def main(args):
    retcode = 0
# Get public ip address of host
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    ipaddr =s.getsockname()[0]
    s.close()

    FAIL = "FAIL"
    PASS = "PASS"
    SSLVerify = False
    logging.captureWarnings(True)
    # SonHa : Start fix hardcode path
    with open(pathlib.Path(pathlib.Path(__file__).parent.absolute(), 'config.yml')) as file:
        # SonHa: End fix hardcode path
        config = yaml.load(file, Loader=yaml.Loader)
# Read data from config.yml file and execute commands such as ping, https, icap ...
# Output format like this :
# -> Dec 23 12:11:43 78.159.113.57 ping 8.8.8.8: PASS 13.23
# Dec 23 12:11:43 : timestamp
# 78.159.113.57: host
# ping 8.8.8.8: checkpoint
# PASS: result
# 13.23: round trip time in ms
    for i in config['hosts']:
        try:
            addr = i['address']
            try:
                addr = str(ipaddress.ip_address(addr))
                url = urllib.parse.urlparse(f'http://{addr}')
            except ValueError:
                url = urllib.parse.urlparse(addr, scheme='http')
                if url.netloc == '' and url.path != '':
                    url = urllib.parse.urlparse(f'{url.scheme}://{url.path}')
                addr = url.hostname
        except KeyError:
            continue
        now = datetime.now()
        if i['prot'] == 'icmp':
            print(f'{now:%b %d %H:%M:%S} {ipaddr} ping {addr}: ',end='', flush=True)
            start = time.perf_counter()
            cp = subprocess.run(['ping', '-c1', '-w2', addr], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            end = time.perf_counter()
            PASS_TIME = PASS + f' {((end - start) * 1000):.2f}'
            print(f'{FAIL if cp.returncode else PASS_TIME}')
            retcode = retcode + cp.returncode
        elif i['prot'] == "tcp":
         #   print(f'tcp/{i["tcpport"]:<6} {addr:30}: ', end='', flush=True)
            print(f'{now:%b %d %H:%M:%S} {ipaddr} tcp/{i["tcpport"]:<6} {addr}: ',end='', flush=True)
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
                    start = time.perf_counter()
                    s.connect(sa)
                except socket.error:
                    s.close()
                    s = None
                    continue
                break
            end = time.perf_counter()
            PASS_TIME = PASS + f' {((end - start) * 1000):.2f}'
            print(f'{PASS_TIME if s else FAIL}')
            retcode = retcode + (0 if s else 1)
            if s: s.close()
        elif i['prot'] == 'httpstatus':
            #print(f'httpstatus {url.geturl():30}: ', end='', flush=True)
            print(f'{now:%b %d %H:%M:%S} {ipaddr} httpstatus {url.geturl()}: ',end='', flush=True)
            start = time.perf_counter()
            try:
                r = requests.get(url.geturl(), verify=SSLVerify, timeout=5)
            except requests.exceptions.ConnectTimeout:
                r = None
            except requests.exceptions.ConnectionError:
                r = None
            end = time.perf_counter()
            PASS_TIME = PASS + f' {((end - start) * 1000):.2f}'
            print(f'{PASS_TIME if r and r.status_code == i["httpstatus"] else FAIL}')
            retcode = retcode + (0 if r and r.status_code == i["httpstatus"] else 1)
        elif i['prot'] == 'httpstring':
            #print(f'httpstring {url.geturl():30}: ', end='', flush=True)
            print(f'{now:%b %d %H:%M:%S} {ipaddr} httpstring {url.geturl()}: ',end='', flush=True)
            start = time.perf_counter()
            try:
                r = requests.get(url.geturl(), verify=SSLVerify, timeout=5)
            except requests.exceptions.ConnectTimeout:
                r = None
            except requests.exceptions.ConnectionError:
                r = None
            end = time.perf_counter()
            PASS_TIME = PASS + f' {((end - start) * 1000):.2f}'
            print(f'{PASS_TIME if r and re.search(i["httpstring"], r.text) else FAIL}')
            retcode = retcode + (0 if r and re.search(i["httpstring"], r.text) else 1)
        elif i['prot'] == 'icap':
            print(f'{now:%b %d %H:%M:%S} {ipaddr} icap     {addr}: ', end='', flush=True)
            suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
            try:
                start = time.perf_counter()
                cp = subprocess.run(['c-icap-client', '-i', addr, '-s', i["icapservice"], '-f', i["icaptestfile"], '-o',
                                     i["icaptestfile"] + suffix], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                    timeout=i['icaptimeout'])
                end = time.perf_counter()
                PASS_TIME = PASS + f' {((end - start) * 1000):.2f}'
            except subprocess.TimeoutExpired:
                cp.returncode == 1
            if cp.returncode == 0:
                if os.path.isfile(i['icaptestfile'] + suffix):
                    c2 = checksum(i['icaptestfile'] + suffix, hashlib.md5())
                    os.remove(i['icaptestfile'] + suffix)
                    if checksum(i['icaptestfile'], hashlib.md5()) != c2:
                        print(PASS_TIME)
                        continue

            print(FAIL)
            retcode += 1
            continue

    return retcode


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
