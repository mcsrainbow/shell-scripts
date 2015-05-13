#!/bin/bash
#
# Manage sftp users for customers
#  
# Author: Dong Guo
# Last Modified: 2013/09/06 by Dong Guo

userfile=/etc/passwd
groupfile=/etc/group
homedir=/home/sftp
loginshell=/sbin/nologin
groupname=sftpusers
username=$2

function check_root()
{
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function print_help(){
  #Print help messages then exit
  echo "Usage: $0 {create|disable|enable|passwd|sshkey|delete} {username}" >&2
  exit 1
}

function check_usergroup(){
  #Create usergroup if NOT exist
  cut -d : -f 1 $groupfile | grep -wq $groupname
  if [ $? -ne 0 ];then
    groupadd $groupname
  fi
}

function check_homedir(){
  #Create homedir if NOT exist
  if [ ! -d "$homedir" ];then
    mkdir $homedir
  fi
}

function check_username_exist(){
  #Check if user already exist
  cut -d : -f 1 $userfile | grep -wq $username
  if [ $? -eq 0 ];then
    echo "User $username ALREADY exist." && exit
  fi
}

function check_username_notexist() {
  #Check if user not exist
  cut -d : -f 1 $userfile | grep -wq $username
  if [ $? -ne 0 ];then
    echo "User $username NOT exist." && exit
  fi
}

function check_user_disabled(){
  #Check if user ALREADY disabled
  lockfile=$homedir/$username/sftpuser.locked
  if [ -a "$lockfile" ]; then
    echo "User $username ALREADY disabled." && exit
  fi
}

function update_sshkey(){
  #Get the sshkey
  echo -n "Input ssh public key: "
  read sshkey
  #Check if sshkey is empty
  if [ -z "$sshkey" ];then
    echo "Empty ssh public key." && exit
  fi
  #Check if sshkey not correct
  echo $sshkey | grep -Ewq '^ssh-rsa|^ssh-dss'
  if [ $? -ne 0 ];then
    echo "String \"ssh-rsa\" or \"ssh-dss\" NOT found." && exit
  fi
  mkdir $homedir/$username/.ssh
  chmod 700 $homedir/$username/.ssh
  echo "$sshkey" > $homedir/$username/.ssh/authorized_keys
  chmod 600 $homedir/$username/.ssh/authorized_keys
  chown -R $username:$groupname $homedir/$username/.ssh
}


if [ $# != 2 ];then
  print_help
fi

check_root
check_usergroup
check_homedir

case "$1" in
  'create')
    check_username_exist
    useradd -m -d "$homedir/$username" -g $groupname -s $loginshell -c "$username sftp" $username
    chmod 755 $homedir/$username
    chown $username:$groupname $homedir/$username
    if [ $? -eq 0 ]; then
      echo "User $username was created."
    fi
    ;;
   
  'disable')
    check_username_notexist
    passwd -l $username
    touch $homedir/$username/sftpuser.locked
    authfile=$homedir/$username/.ssh/authorized_keys
    if [ -a "$authfile" ]; then
      mv $authfile $authfile.disabled
    fi
    if [ $? -eq 0 ]; then
      echo "User $username was disabled."
    fi
    ;;
  
  'enable')
    check_username_notexist
    passwd -u $username
    rm -f $homedir/$username/sftpuser.locked
    authfile=$homedir/$username/.ssh/authorized_keys
    if [ -a "$authfile.disabled" ]; then
      mv $authfile.disabled $authfile
    fi
    if [ $? -eq 0 ]; then
      echo "User $username was enabled."
    fi
    ;;
   
  'delete')
    check_username_notexist
    echo -n "Delete all the data and account of user $username? [yes|no] "
    read yesorno
    if [ "$yesorno" == "yes" ];then
      userdel -rf $username
      if [ $? -eq 0 ]; then
        echo "User $username was deleted."
      fi
    fi
    ;;

  'passwd')
    check_username_notexist
    check_user_disabled
    passwd $username
    ;;
   
  'sshkey')
    check_username_notexist
    check_user_disabled
    update_sshkey
    if [ $? -eq 0 ]; then
      echo "The sshkey of user $username was updated."
    fi
    ;;
       
  *)
    print_help
    ;;
esac
