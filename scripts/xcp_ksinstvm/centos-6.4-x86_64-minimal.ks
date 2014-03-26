cmdline
skipx
install
cdrom
lang en_US.UTF-8
keyboard us

network --onboot=yes --device=eth0 --bootproto=static --ip=172.16.4.254 --netmask=255.255.252.0 --gateway=172.16.4.1 --nameserver=172.16.4.10 --noipv6

rootpw drawbridge

firewall --disabled
authconfig --enableshadow --passalgo=sha512
selinux --disabled
timezone --utc Etc/UTC

bootloader --location=mbr --driveorder=xvda --append="crashkernel=auto"

zerombr
clearpart --all --initlabel
autopart

reboot

%packages --nobase
@core
%end