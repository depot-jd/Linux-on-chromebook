#!/bin/bash

# On the ChromeOS or any other arm64 device, run stage 2 of debootstrap
#
# Author: jd, 2025

if [[ ! -b $1 ]] ; then printf "Usage : $0 /dev/device_to_install # (ex: /dev/sda, /dev/mmcblk0)\n\n"; exit ; fi

DEV=$1
if [[ "$DEV" == '/dev/mmcblk0' ]] ; then P='p' ; fi

DEV=$DEV
MNT=/media/cdrom
mkdir $MNT
# Unmount from wherever ChromeOS decided to mount the device,
# remount where we want:
umount ${DEV}${P}3
umount ${DEV}${P}2
mount ${DEV}${P}3 $MNT
mount ${DEV}${P}2 ${MNT}/boot
# Complete the bootstrap
chroot ${MNT} /debootstrap/debootstrap --second-stage

echo "Set root password..."
chroot ${MNT} passwd root
echo "Add user..."
read -p "Enter username account : " name
chroot ${MNT} adduser $name 
    
# Set the hostname:
read -p "Enter hostname : " hostn
echo $hostn > ${MNT}/etc/hostname

# Install module conf
cp -Rp misc/modules ${MNT}/etc/
depmod -a

# Set sources.list
cat > ${MNT}/etc/apt/sources.list <<EOF
deb http://http.debian.net/debian stable main non-free non-free-firmware contrib
deb-src http://http.debian.net/debian stable main non-free non-free-firmware contrib
deb http://security.debian.org/debian-security stable-security main contrib non-free non-free-firmware
EOF

chroot ${MNT} apt update
# Here you can add pkg you want :
chroot ${MNT} apt install -y gnome mpv firefox-esr alsa-utils
chroot ${MNT} apt clean

# Install firmware
cp -Rp misc/firmware/ ${MNT}/lib/

# Install Alsa conf
cp -Rp misc/ucm2/ ${MNT}/usr/share/alsa/

dpkg-reconfigure locales
dpkg-reconfigure tzdata

# Unmount the filesystems:
umount ${MNT}/boot
umount $MNT 

