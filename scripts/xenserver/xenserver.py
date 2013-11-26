#!/usr/bin/env python
#-*- coding:utf-8 -*-

# Author: Dong Guo
# Last Modified: 2013/11/26

import os
import sys
import fileinput
from fabric.api import env,execute,cd,sudo,run,hide,settings

def parse_opts():
    """Help messages (-h, --help)"""
    
    import textwrap
    import argparse

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent(
        '''
        examples:
          {0} -s iad2-vm1003 -f iad2-vm1003.list
          {0} -s iad2-vm1003 -t t_ads_50 -n iad2-ads21 -i 172.16.8.65 -e 255.255.252.0 -g 172.16.8.1 -c 4 -m 8G

          iad2-vm1003.list:
            t_ads_50,iad2-ads21,172.16.8.65,255.255.252.0,172.16.8.1,4,8G
            t_ads_50,iad2-ads41,172.16.8.66,255.255.252.0,172.16.8.1,4,8G
            ...
        '''.format(__file__)
        ))

    exclusion = parser.add_mutually_exclusive_group(required=True)

    parser.add_argument('-s', metavar='server', type=str, required=True, help='hostname of xenserver')
    exclusion.add_argument('-f', metavar='filename', type=str, help='filename of list')
    exclusion.add_argument('-t', metavar='template', type=str, help='template of vm')
    parser.add_argument('-n', metavar='hostname', type=str, help='hostname of vm')
    parser.add_argument('-i', metavar='ipaddr', type=str, help='ipaddress of vm')
    parser.add_argument('-e', metavar='netmask', type=str, help='netmask of vm')
    parser.add_argument('-g', metavar='gateway', type=str, help='gateway of vm')
    parser.add_argument('-c', metavar='cpu', type=int, help='cpu cores of vm')
    parser.add_argument('-m', metavar='memory', type=str, help='memory of vm')

    args = parser.parse_args()
    return {'server':args.s, 'filename':args.f, 'template':args.t, 'hostname':args.n,
            'ipaddr':args.i, 'netmask':args.e, 'gateway':args.g, 'cpu':args.c, 'memory':args.m}

def isup(host):
    """Check if host is up"""

    import socket

    conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    conn.settimeout(1)
    try:
        conn.connect((host,22))
        conn.close()
    except:
        print "Connect to host {0} port 22: Network is unreachable".format(host)
        sys.exit(1)

def fab_execute(host,task):
    """Execute the task in class FabricSupport."""

    user = "adsymp"
    keyfile = "/home/dong.guo/workspace/sshkeys/adsymp"
    
    myfab = FabricSupport()
    return myfab.execute(host,task,user,keyfile)

class FabricSupport(object):
    """Remotely get information about servers"""
    
    def __init__(self):
        self.server = opts['server']
        self.template = opts['template']
        self.hostname = opts['hostname']
        self.ipaddr = opts['ipaddr']
        self.netmask = opts['netmask']
        self.gateway = opts['gateway']
        self.cpu = opts['cpu']
        self.memory = opts['memory']

    def execute(self,host,task,user,keyfile):
        env.parallel = True
        env.user = user
        env.key_filename = keyfile

        get_task = "task = self.{0}".format(task)
        exec get_task
        
        with settings(warn_only=True):
            with hide('warnings', 'running', 'stdout', 'stderr'):
                return execute(task,host=host)[host]

    def clone(self):
        sr_uuid = sudo("""xe sr-list |grep -A 2 -B 3 -w %s |grep -A 4 -B 1 "Local storage" |grep -w uuid |awk -F ":" '{print $2}'""" % (self.server))

        print "Copying the vm:{0} from template:{1}...".format(self.hostname,self.template)
        vm_uuid = sudo("""xe vm-copy new-name-label={0} vm={1} sr-uuid={2}""".format(self.hostname,self.template,sr_uuid))
        if vm_uuid.failed:
            print "Failed to copy vm: {0}".format(self.hostname)
            return False
        
        print "Setting up the bootloader,vcpus,memory of vm:{0}...".format(self.hostname)
        sudo('''xe vm-param-set uuid={0} HVM-boot-policy=""''').format(vm_uuid)
        sudo('''xe vm-param-set uuid={0} PV-bootloader="pygrub"''').format(vm_uuid)

        sudo('''xe vm-param-set VCPUs-max={0} uuid={1}''').format(self.cpu,vm_uuid)
        sudo('''xe vm-param-set VCPUs-at-startup={0} uuid={1}''').format(self.cpu,vm_uuid)

        sudo('''xe vm-memory-limits-set uuid={0} dynamic-min={1}iB dynamic-max={1}iB static-min={1}iB static-max={1}iB''').format(vm_uuid,self.memory)

        print "Setting up the network of vm:{0}...".format(self.hostname)
        sudo('''xe vm-param-set uuid={0} PV-args="_hostname={1} _ipaddr={2} _netmask={3} _gateway={4}"'''.format(vm_uuid,self.hostname,self.ipaddr,self.netmask,self.gateway))

        print "Starting vm:{0}...".format(self.hostname)
        vm_start = sudo('''xe vm-start uuid={0}'''.format(vm_uuid))
        if vm_start.failed:
            print "Failed to start vm: {0}".format(self.hostname)
            return False
        return True

if __name__=='__main__':
    argv_len = len(sys.argv)
    if argv_len < 2:
        os.system(__file__ + " -h")
        sys.exit(1)
    opts = parse_opts()

    # check if host is up
    isup(opts['server'])

    # clone
    if opts['filename'] != None:
        for i in fileinput.input(opts['filename']):
            a = i.split(',')
            opts = {'server':opts['server'], 'template':a[0], 'hostname':a[1], 'ipaddr':a[2], 'netmask':a[3], 'gateway':a[4], 'cpu':a[5], 'memory':a[6]}
            fab_execute(opts['server'],"clone")
        sys.exit(0)
    fab_execute(opts['server'],"clone")
