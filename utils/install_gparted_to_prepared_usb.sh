#!/bin/sh

set -x

DISK_NAME="$1"
DISK_DEVICE="/dev/${DISK_NAME}"

#latest_gparted_release_version=$(curl --silent https://gparted.org/download/ | grep "Current Release" | cut --delimiter=':' --fields=2 | cut --delimiter=' ' --fields=2 | cut --delimiter='<' --fields=1)

if [ ! -f "/tmp/gparted_latest.iso" ]
then
  latest_gparted_iso_stable_URL=$(curl --silent https://gparted.org/download.php | grep gparted-live | head --lines=1 | cut --delimiter='"' --fields=2)

  printf "%s\n" "Downloading GParted ISO in version"
  printf "%s\n" "${latest_gparted_iso_stable_URL}"

  axel --verbose --num-connections=10 \
      "${latest_gparted_iso_stable_URL}" --output="/tmp/gparted_latest.iso"
fi

gparted_checksums_URL="$(curl --silent https://gparted.org/download.php | grep --ignore-case checksums\.txt\" | sed 's/<a href="//g' | sed 's/ target=.*//g' | tr --delete '"' | tr --delete ' ')"
curl --location https://gparted.org/${gparted_checksums_URL} --output "/tmp/gparted_latest-checksums.txt"
GPARTED_ISO_SHA256SUM_LOCAL="$(sha256sum /tmp/gparted_latest.iso | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=1)"
GPARTED_ISO_SHA256SUM_REMOTE="$(grep --ignore-case "^$GPARTED_ISO_SHA256SUM_LOCAL" /tmp/gparted_latest-checksums.txt | head --lines=1)"

if [ -z "${GPARTED_ISO_SHA256SUM_REMOTE}" ]
then
  echo "File integrity compromised. Local and remote checksums are different."
  echo "Try to download the archive from different source and make sure the verification file is belonging to the archive you downloaded"
  exit 1
fi

echo
echo "*********************************************************************"
echo
echo "File integrity check passed. Local and remote checksums are matching."
echo "Proceeding..."
echo
echo "*********************************************************************"
echo

echo "Unmount all partitions of the device '/dev/${DISK_NAME}'"
PARTITION_NAME=$(cat /proc/partitions | grep "${DISK_NAME}" | rev | cut -d' ' -f1 | rev | grep -v ""${DISK_NAME}"$")
PARTITION_DEVICE="/dev/${PARTITION_NAME}"

udisksctl unmount --block-device ${PARTITION_DEVICE}
udisksctl mount --block-device ${PARTITION_DEVICE}
USB_MOUNT_DIR="$(lsblk -oNAME,MOUNTPOINTS "${PARTITION_DEVICE}" | tail --lines=1 | cut --delimiter=' ' --fields=1 --complement)/"

sudo 7z x -y "/tmp/gparted_latest.iso" -o"${USB_MOUNT_DIR}"

sync
sudo sync

udisksctl unmount --block-device ${PARTITION_DEVICE}

