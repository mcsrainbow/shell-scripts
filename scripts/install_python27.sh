#!/bin/bash 
# 
# Install the latest verion of Python 2.7
#

function check_root(){
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function update_pip_conf(){
  mkdir -p ~/.pip

  if ! $(grep -wq trusted-host ~/.pip/pip.conf); then
    echo "Updating ~/.pip/pip.conf..."
    cat > ~/.pip/pip.conf <<EOF
[global]
trusted-host = mirrors.aliyun.com
index-url = http://mirrors.aliyun.com/pypi/simple/
EOF
  fi
}

function install_rpm_packages(){
  echo "Installing required RPM packages..."
  yum install -y openssl-devel openssl blas-devel openblas-devel cmake
}

function install_python(){
  latest_version=$(curl -s https://www.python.org/ftp/python/ | grep 'href="2.7' | tail -n 1 | cut -d\" -f 2 | cut -d\/ -f1)

  if [[ ! -f /usr/local/bin/python2.7 ]]; then
    echo "Installing the Python ${latest_version}..."
    cd /tmp
    /usr/bin/wget --no-check-certificate https://www.python.org/ftp/python/${latest_version}/Python-${latest_version}.tgz
    if [[ $? -eq 0 ]]; then
      tar xzf Python-${latest_version}.tgz
      cd Python-${latest_version}
      ./configure && make && make altinstall
    fi
  fi
  
  if [[ ! -f /usr/local/bin/pip2.7 ]]; then
    echo "Installing the easy_install-2.7 and pip commands..."
    cd /tmp
    /usr/bin/wget --no-check-certificate https://bootstrap.pypa.io/ez_setup.py -O - | /usr/local/bin/python2.7
    if [[ $? -eq 0 ]]; then
      /usr/local/bin/easy_install-2.7 pip
      rm -rf /tmp/Python-${latest_version}*
    fi
  fi

  echo "Linking the python2.7 and pip2.7 commands from /usr/local/bin to /usr/bin..."
  for binfile in python2.7 pip2.7; do
    ln -sf /usr/local/bin/${binfile} /usr/bin/${binfile}
  done
}

function install_pip_packages(){
  echo "Installing the Python modules packages by pip2.7 command..."
  for package in scipy sklearn sklearn-pandas panda execnet xgboost numpy; do 
    /usr/local/bin/pip2.7 install -b /tmp ${package}
  done
}

check_root
update_pip_conf # Chinese users only
install_rpm_packages
install_python
install_pip_packages
