#!/bin/sh

set -x

DISK_NAME="$1"
DISK_DEVICE="/dev/${DISK_NAME}"

PARTITION="/dev/$(cat /proc/partitions | grep "${DISK_NAME}" | grep -v "${DISK_NAME}"$ | tr -s ' \t' | rev | cut -d' ' -f1 | rev)"
sudo fatlabel "${PARTITION}" "GPARTED"

echo "Verification"
lsblk -o NAME,FSTYPE,LABEL,UUID "${DISK_DEVICE}"
echo "========================================="
sudo parted --script "${DISK_DEVICE}" print

