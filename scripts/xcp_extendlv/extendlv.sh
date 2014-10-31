#!/bin/sh

disk=/dev/xvda
num=3
oldsize=12G
failed=/root/extendlv.failed
rebooted=/root/extendlv.rebooted

function check_root(){
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
  fi
}

function extend_lv(){
  echo "root filesystem:"
  df -hP / | grep -v Filesystem

  if [ ! -f ${rebooted} ]; then
    echo -e "n
p
${num}
\n
\n
w
q"|fdisk ${disk}
    touch ${rebooted}
    reboot
    exit 1
  fi

  vg=$(df -h  | grep root | cut -d/ -f4 | cut -d- -f1)
  lv=$(df -h  | grep root | cut -d/ -f4 | cut -d- -f2)
  
  echo "resizing ${vg}-${lv}"
  pvcreate ${disk}${num}
  pvresize ${disk}${num}
  vgextend ${vg} ${disk}${num}
  free=$(vgdisplay | grep Free | awk '{print $5}')
  lvextend -l +${free} /dev/${vg}/${lv}
  resize2fs /dev/mapper/${vg}-${lv}
  
  echo "new root filesystem:"
  df -hP / | grep -v Filesystem
}

function check_status(){
  root_size=$(df -hP / |grep -v Filesystem |awk '{print $2}')
  if [ ${root_size} != "${oldsize}" ]; then
    sed -i /extendlv/d /etc/rc.local
    if [ -f ${failed} ]; then
      rm -f ${failed}
    fi
  else
    touch ${failed}
  fi
}

check_root
extend_lv
check_status
