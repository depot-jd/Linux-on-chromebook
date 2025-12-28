#!/bin/bash

# Linux could not be installed easily in one pass on chromebook. 
# Need to install on sdcard first, and after on chromebook.
# First stage could be run on any linux arch.
# Second stage need to be run ON arm64 chromebook.
# Author: jd, 2025

printf "$0 needs cgpt/tune2fs/parted/debootstrap, enter ctrl-c for cancel installation : "
for((i=9;i;i--)) ; do printf "$i sec"; sleep 1 ; printf '\b\b\b\b\b' ;  done
printf "\n";

if [[ ! -b $1 ]] ; then printf "Usage : $0 /dev/device_to_install # (ex: /dev/sda, /dev/mmcblk0)\n\n"; exit ; fi

DEV=$1
if [[ "$DEV" == '/dev/mmcblk0' ]] ; then P='p' ; fi
read -p "WARNING !!! [$DEV] will be erased, to continue enter Y :" reply

if [[ "$reply" != 'Y' ]] ; then echo "Abort installation" ; exit ; fi

dd if=/dev/zero of=$DEV bs=1M count=10

MNT=/media/cdrom
# Partitioning the device
parted --script $DEV mklabel gpt
cgpt create $DEV

ROOT_START=854016

LAST_BLOCK=$(cgpt show $DEV | awk '/Last usable sector:/ {gsub(/ /,"",$4); print $4}')

if [ -z "$LAST_BLOCK" ]; then
    TOTAL_BLOCKS=$(blockdev --getsz $DEV)
    # on enlève 33 secteurs réservés pour GPT
    LAST_BLOCK=$((TOTAL_BLOCKS - 33))
fi

ROOT_SIZE=$((LAST_BLOCK - ROOT_START))

# Add partitions
# uboot : 96Mo
cgpt add -t kernel -l uboot/kernel -b 2048 -s 196608 $DEV
# boot : 320Mo
cgpt add -t data -l /boot -b 198656 -s 655360 $DEV
# rootfs : the remaining space 
cgpt add -t data -l / -b 854016 -s $ROOT_SIZE $DEV
# If you want a seperate home directory, comment line before and uncomment two next line.
#cgpt add -t data -l / -b 854016 -s 48234496 $DEV
#cgpt add -t data -l /home -b 49088512 -s 0 $DEV

blockdev --rereadpt $DEV
# boot filesystem:
mkfs.ext3 ${DEV}${P}2
# root fs
mkfs.ext4 ${DEV}${P}3

# Needs for kernel blob
tune2fs ${DEV}${P}2 -U 925f33ed-7e80-486b-a684-616e0838f9c6
tune2fs ${DEV}${P}3 -U ae206ac8-43da-4fb0-a691-e0cd675b3463

# bootstrap first stage
mkdir -p $MNT
mount ${DEV}${P}3 $MNT
mkdir -p ${MNT}/boot
mount ${DEV}${P}2 ${MNT}/boot

debootstrap --arch=arm64 --foreign stable $MNT http://httpredir.debian.org/debian

# Install kernel
dd if=kernel/kernel_sd of=${DEV}${P}1
mkdir -p ${MNT}/lib/modules
# Make uboot partition bootable by depthcharge
cgpt add -i 1 -S 1 -T 5 -P 12 $DEV

cp -Rp kernel/6.12.36-mt81/ ${MNT}/lib/modules/

# Add fstab with righ UUID (You could use your own but need to repack kernel)
cp -Rp misc/fstab ${MNT}/etc

# Set the hostname:
read -p "Enter hostname : " hostn
echo $hostn > ${MNT}/etc/hostname

# Unmount the filesystems:
umount ${MNT}/boot
umount $MNT
