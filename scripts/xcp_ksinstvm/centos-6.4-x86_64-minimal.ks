cmdline
skipx
install
cdrom
lang en_US.UTF-8
keyboard us

network --onboot=yes --device=eth0 --bootproto=static --ip=10.100.1.254 --netmask=255.255.255.0 --gateway=10.100.1.1 --nameserver=10.100.1.2 --noipv6

rootpw password

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
