#!/usr/bin/env bash
set -e

CRYPT_FOLDERS="data home opt root srv tmp var"

# Mount folder partitions
for folder in $CRYPT_FOLDERS; do
  umount /dev/mapper/vg0-$folder; done

# Open encrypted partition (passphrase prompt)
cryptsetup luksClose sda2_crypt

echo "Unmounting process finished"
