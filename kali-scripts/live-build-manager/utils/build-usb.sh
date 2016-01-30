#!/bin/bash
#
## =====================================================================
#
#
## =====================================================================

## Text Colors
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


ls -l /dev/disk/by-id
# or type 'fdisk -l'

echo -e ""
read -p "[*] From the list above, locate your USB Device and enter its partition now (.e.g sdb): " -e response
if [[ $response ]]; then
    MY_USB=${response}
else
    echo -e "[-] Invalid entry. Try again"
    exit 1
fi

# Get capacity size (in bytes) of USB Device
#blockdev --getsize64 /dev/${MY_USB}

optsize=$(cat /sys/block/${MY_USB}/queue/optimal_io_size)
minsize=$(cat /sys/block/${MY_USB}/queue/minimum_io_size)
offset=$(cat /sys/block/${MY_USB}/alignment_offset)
blocksize=$(cat /sys/block/${MY_USB}/queue/physical_block_size)

# (optsize + offset) / blocksize = 1
# Also, if you use '%' it should auto-align when creating partitions
	# e.g. mkpart primary ext4 0% 100%

# One-liner
#awk -v x=$(cat /sys/block/sdb/queue/optimal_io_size) -v y=$(cat /sys/block/sdb/alignment_offset) -v z=$(cat /sys/block/sdb/queue/physical_block_size) ‘BEGIN { print ( x + y ) / z }’

echo -e "\n${BLUE}=================[  USB DEVICE SPECS  ]=================${RESET}"
echo -e "\tOptimal IO Size:\t${optsize}"
echo -e "\tMinimum IO Size:\t${minsize}"
echo -e "\tAlignment Offset:\t${offset}"
echo -e "\tPhysical Block Size:\t${blocksize}"
echo -e "${BLUE}========================================================\n${RESET}"

# Copy the ISO to the USB Drive
#dd if=d

# Launch 'parted' and setup 2 additional partitions
#parted /dev/sdb
#print
#mkpart primary 901 5000
#mkpart primary 5000 100%
#q

read -p "[*] If in a VM, you may need to disconnect and re-connect the USB at this time to proceed. Press ENTER when done."

#
#fdisk -l /dev/${MY_USB}

# Create the persistence functionality
#mkfs.ext3 /dev/sdb3
#e2label /dev/sdb3 persistence
#mkdir -p /mnt/usb
#mount /dev/sdb3 /mnt/usb
#echo "/ union" > /mnt/usb/persistence.conf
#umount /mnt/usb


# Setup Crypt/Luks
#cryptsetup --verbose --verify-passphrase luksFormat /dev/${MY_USB}4
#cryptsetup luksOpen /dev/${MY_USB}4 my_usb

#mkfs.ext3 /dev/mapper/my_usb
#e2label /dev/mapper/my_usb persistence

#ls -l /dev/disk/by-label

#mkdir -p /mnt/my_usb
#mount /dev/mapper/my_usb /mnt/my_usb
#echo "/ union" > /mnt/my_usb/persistence.conf
#umount /dev/mapper/my_usb
#cryptsetup luksClose /dev/mapper/my_usb

#cryptsetup luksAddNuke /dev/sdb4
# Enter a passphrase and done
# ----------------------- DONE -----------------------------------#


# --------------- NOTES --------------------#
# Information Available via /sys/block/sdb/
#alignment_offset
#bdi/
#capability
#dev
#device/
#discard_alignment
#events
#events_async
#events_poll_msecs
#ext_range
#holders/
#inflight
#power/
#queue/
#range
#removable
#ro
#size - 15466496 (size in sectors)







