#!/usr/bin/env bash
set -e

###############################################################
# PART II: CREATE ENCRYPTED LVM                               #
# Create a second partition with targeted folders             #
###############################################################

# Get dependencies

yum update
yum install -y cryptsetup

# Define an associative array with folders and sizes

declare -A CRYPT_FOLDERS

CRYPT_FOLDERS+=([home]=200g
                [opt]=5g
                [root]=10g
                [srv]=1g
                [tmp]=10g
                [var]=100g )

# Create a mount point parent folder
TEMPDIR=$(mktemp -d /mnt/XXXXXXXX)

echo "Creating dump folders for data restore...."

# Dump existing contents into temp folder handlers
for folder in ${!CRYPT_FOLDERS[@]}; do
  cp -pr /$folder $TEMPDIR/$folder; done

echo "Starting encryption of /dev/sda2"

# Encrypt the new /dev/sda2
# It's a good idea to run "cryptsetup benchmark" when customising this script
cryptsetup --key-size 512 --cipher twofish-xts-plain64 luksFormat /dev/sda2
#cryptsetup luksUUID /dev/sda2

echo "Encryption finished!"
echo "About to open new encrypted partition..."

# Unlock encrypted partition as /dev/mapper/sda2_crypt
cryptsetup luksOpen /dev/sda2 sda2_crypt

# Create physical volume with required size
pvcreate /dev/mapper/sda2_crypt

#create a volume group called vg0
vgcreate vg0 /dev/mapper/sda2_crypt

# Create logical volumes with predetermined sizes

for folder in ${!CRYPT_FOLDERS[@]}; do
  lvcreate -L ${CRYPT_FOLDERS[$folder]} -n $folder vg0; done

# Create swap
lvcreate -L 16g -n swap vg0
mkswap -L swap /dev/mapper/vg0-swap

for folder in ${!CRYPT_FOLDERS[@]}; do
  mkfs.xfs /dev/mapper/vg0-$folder; done

# Mount encrypted logical volumes temporarily to restore data
for folder in ${!CRYPT_FOLDERS[@]}; do
  mkdir -p $TEMPDIR/new/$folder; done
for folder in ${!CRYPT_FOLDERS[@]}; do
  mount /dev/mapper/vg0-$folder $TEMPDIR/new/$folder; done

#Restore contents in new encrypted logical volumes
for folder in ${!CRYPT_FOLDERS[@]}
do
  if test "$(ls -A $TEMPDIR/$folder)"; then
    echo "Transferring data for /$folder...."
    cp -pr $TEMPDIR/$folder $TEMPDIR/new
  else
    echo "$folder is empty. Nothing to copy"
  fi
done

# Now that all data has been safely transfered, unmount lvs
for folder in ${!CRYPT_FOLDERS[@]}; do
  umount /dev/mapper/vg0-$folder; done

# OPTIONAL: Let's also create a lv for /data and a mount point for it
lvcreate -L 300g -n data vg0
mkfs.xfs /dev/mapper/vg0-data;
mkdir /data

# Mount logical volumes into their appropriate mount points
for folder in ${!CRYPT_FOLDERS[@]}; do
  mount /dev/mapper/vg0-$folder /$folder; done

# IMPORTANT! Restore SELINUX security contexts
for folder in ${!CRYPT_FOLDERS[@]}; do
  restorecon -FR /$folder; done

# Enable new swap
swapon /dev/mapper/vg0-swap

#Remove the copies
rm -rf $TEMPDIR

echo "Encryption finished!"
echo "Your encrypted folders are mounted and ready to use"
