# Linux on ARM Chromebook (MT8186)

Two scripts to install Debian on ARM Chromebooks (MT8186) using debootstrap.  
Tested on model 14M868.  
Other chipsets require kernel and firmware adjustments.


The UEFI firmware on ARM Chromebooks does not allow booting a standard ISO to install a Linux distribution.
The approach used here is to rely on an SD card as an intermediate system. Once the system is booted from the SD card, the installation can be repeated on the Chromebook’s internal storage (eMMC). The first stage of debootstrap can be performed on any Linux system, regardless of CPU architecture. However, the second stage must be executed on an ARM64 machine, namely the Chromebook itself. It is not possible to run the second stage directly on the eMMC while running ChromeOS, because ChromeOS already uses this storage device. Therefore, when executing the second stage from ChromeOS, the SD card must be used as the target. If you want to keep a dual-boot setup with ChromeOS and Linux, you can also run Linux entirely from the SD card. This works reliably, but using a high-performance SD card is required (for example, SanDisk A2, Class 3, minimum 64 GB). Slower cards result in significantly reduced application load times.

---

## Disclaimer

This project is provided "as is", without warranty of any kind.  
Any use of this software is entirely at the user's own responsibility.

---

## Author

jd

---

## Credits

Thanks to PostmarketOS for the kernel.

---

## Installation

```bash
# install required tools on a Debian-based system
apt update
apt install cgpt debootstrap parted e2fsprogs

# clone repository
cd /usr/local/src
git clone git@github.com:depot-jd/Linux-on-chromebook.git
cd Linux-on-chromebook

# make scripts executable
chmod +x first_stage.sh on_chrome.sh

# prepare Debian system on target device (SD card or eMMC)
./first_stage.sh /dev/<device>

# reboot Chromebook
# enable Developer Mode
# press CTRL+T and type: shell

# run second stage directly on the Chromebook
chmod +x on_chrome.sh
# On Linux
./on_chrome.sh
# On chromeOS
sudo bash ./on_chrome.sh </dev/<device>>

# reboot and select the new dev boot menu : "Boot from external disk"

# optional: repeat the same procedure on internal eMMC (device for model 14M868: /dev/mmcblk0)

# optional: custom kernel packaging
conf="kern_guid=%U console=tty0 console=tty1 loglevel=7 plymouth.enable=0 PMOS_NOSPLASH \
pmos_boot_uuid=925f33ed-7e80-486b-a684-616e0838f9c5 \
pmos_root_uuid=ae206ac8-43da-4fb0-a691-e0cd675b3462 \
pmos_rootfsopts=defaults"

# devkeys from ChromeOS
# dtb, vmlinuz and initramfs from PostmarketOS

mkdepthcharge -o my_kernel \
  --keydir kernel/devkeys/ \
  -c $conf \
  -b kernel/mt8186-corsola-magneton-sku393217.dtb \
  -d kernel/vmlinuz \
  -i kernel/initramfs

# write kernel to first partition of the target device
dd if=my_kernel of=/dev/<first_partition_of_device>

# GNOME touchpad configuration
# two-finger press
# tap to click
# side or edge scrolling
# natural scroll direction

# known issue: 
##no sound on internal speakers : 
rm /var/lib/alsa/asound.state
reboot

## Suspend mode does not works well.
