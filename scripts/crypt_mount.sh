#!/usr/bin/env bash
set -e

#########################################################
# PART III: MOUNT PARTITIONS AFTER REBOOT               #
# Open and mount crypted LUKS partition after reboot    #
#########################################################

CRYPT_FOLDERS="data home opt root srv tmp var"

# Open encrypted partition (passphrase prompt)
cryptsetup luksOpen /dev/sda2 sda2_crypt
partprobe

# FROM THE DOCS:
# Before running xfs_check or xfs_repair -n, the file system to be checked must
# be unmounted cleanly using normal system administration procedures (the umount
# command or system shutdown), not as a result of a crash or system reset. If the
# file system has not been unmounted cleanly, mount it and unmount it cleanly
# before running xfs_check or xfs_repair -n.

# # Mount and umount folders
# # Prevents xfs_repair malfunctioning
for folder in $CRYPT_FOLDERS; do
  mount /dev/mapper/vg0-$folder /$folder; done

for folder in $CRYPT_FOLDERS; do
  umount /dev/mapper/vg0-$folder; done

# Since our encrypted LVM is not mounted at boot, perform a fs check
# Choose the utility appropriate for filesystem
for folder in $CRYPT_FOLDERS; do
  xfs_repair /dev/mapper/vg0-$folder; done
  #fsck /dev/mapper/vg0-$folder /$folder; done

echo "File check seems OK"

# Mount folder partitions
for folder in $CRYPT_FOLDERS; do
  mount /dev/mapper/vg0-$folder /$folder; done

# Enable swap
swapon /dev/mapper/vg0-swap

#Flush tmp
rm -rf $TEMPDIR

echo "Mounting process finished"
echo "Your encrypted folders are mounted and ready to use"
