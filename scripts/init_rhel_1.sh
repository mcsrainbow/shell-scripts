#!/bin/bash

function check_root(){
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function disable_service(){
  echo "1. Disable services: NetworkManager,iptables,ip6tables"
  chkconfig NetworkManager off
  chkconfig iptables off
  chkconfig ip6tables off

  service NetworkManager stop
  service iptables stop
  service ip6tables stop
}

function disable_selinux(){
  echo "2. Disable SELinux"
  sed -i s/'SELINUX=enable'/'SELINUX=disabled'/g /etc/selinux/config
  setenforce 0
}

function configure_network(){
  echo "3. Specify the IPADDR/NETMASK/GATEWAY settings"
  echo -n "IPADDR: "
  read ipaddr

  echo -n "NETMASK: "
  read netmask

  echo -n "GATEWAY: "
  read gateway

  if [[ -z "${ipaddr}" ]] || [[ -z "${netmask}" ]] || [[ -z "${gateway}" ]]; then
    echo "ERROR: Incorrect IPADDR/NETMASK/GATEWAY"
    exit 1
  fi

  echo "4. Backup /etc/sysconfig/network-scripts/{ifcfg-eth0,ifcfg-eth2}"
  if [[ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]]; then
    cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.$(date +%Y%m%d%H%M%S)
  if

  if [[ -f /etc/sysconfig/network-scripts/ifcfg-eth2 ]]; then
    cp /etc/sysconfig/network-scripts/ifcfg-eth2 /etc/sysconfig/network-scripts/ifcfg-eth2.$(date +%Y%m%d%H%M%S)
  if

  echo "5. Configure /etc/sysconfig/network-scripts/{ifcfg-bond0,ifcfg-eth0,ifcfg-eth2}"  
  cat > /etc/sysconfig/network-scripts/ifcfg-bond0 <<EOF
DEVICE=bond0
ONBOOT=yes
BOOTPROTO=static
IPADDR=${ipaddr}
NETMASK=${netmask}
GATEWAY=${gateway}
USERCTL=no
EOF

  cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=none
MASTER=bond0
ONBOOT=yes
SLAVE=yes
USERCTL=no
EOF

  cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
BOOTPROTO=none
MASTER=bond0
ONBOOT=yes
SLAVE=yes
USERCTL=no
EOF

  echo "6. Update /etc/modprobe.conf"
  if ! $(grep -q 'alias bond0 bonding' /etc/modprobe.conf); then
    echo 'alias bond0 bonding' >> /etc/modprobe.conf
  fi

  if ! $(grep -q 'options bond0 miimon=100 mode=1' /etc/modprobe.conf); then
    echo 'options bond0 miimon=100 mode=1' >> /etc/modprobe.conf
  fi
}

check_root
disable_service
disable_selinux
configure_network
