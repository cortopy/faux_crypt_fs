#!/usr/bin/env bash

#################################################
# PART I: PREPARE PARTITIONS AND LAUNCH FDISK   #
#################################################


swapoff /dev/sda2
sed --in-place '/dev[/]sda2/ d' /etc/fstab
fdisk /dev/sda

# For this operation partprobe is not sufficient. REBOOT after running part I.
#partprobe
