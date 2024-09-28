#! /bin/bash
# list disks and make partitions
CORES=$(nproc)
echo This script will download and make a live bootstrap on the designated disk
fdisk -l | grep /dev
#echo In fdisk, make four partions. one swap partion and three partitions.
read -p 'Select the disk /dev node to put the bootstrap on.> ' DISKTOUSE
#fdisk /dev/$DISKTOUSE
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DISKTOUSE
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +8G # 8G swap parttion
  t # change type
  82 # linux swap
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +20G # 20G livebootstrap partion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
  +32G # 32G LFS partion
n # new partition
  p # primary partition
  4 # partion number 4
    # default, start immediately after preceding partition
    # default use the rest of the disk
  w # write the partition table
  q # and we're done
EOF

# Setup and enable a swap partition
mkswap /dev/$DISKTOUSE'1'
swapon /dev/$DISKTOUSE'1' 
# format and mount the target partition
mkfs.ext4 /dev/$DISKTOUSE'2'
mount /dev//$DISKTOUSE'2' /mnt
cd /mnt
# format the rest of the partitions
mkfs.ext4 /dev/$DISKTOUSE'3'
mkfs.ext4 /dev/$DISKTOUSE'4'
#github
cd /mnt
git clone https://github.com/ajherchenroder/live-bootstrap-with-lfs.git
cd /mnt/live-bootstrap-with-lfs
git submodule update --init --recursive
cd /mnt
mkdir /mnt/live-bootstrap
cp -R /mnt/live-bootstrap-with-lfs/* /mnt/live-bootstrap
rm -Rf /mnt/live-bootstrap-with-lfs
#make sure the new scripts are +x
chmod +x,+x,+x /mnt/live-bootstrap/steps/after/*
chmod +x,+x,+x /mnt/live-bootstrap/steps/lfs/*
#cd into live bootstrap and download the dist files
cd /mnt/live-bootstrap
# parse the flags
while getopts L flag; 
do
     case "${flag}" in
        L) REMOTE="local";; #download from the local repositories
     esac
done
if test "$REMOTE" = "local"; then 
   echo "local"
   #local
   curl http://192.168.2.102/livebootstrap_backups/distfiles.tar.gz -O --limit-rate 20M
   # extract the dist files
   gzip -d /mnt/live-bootstrap/distfiles.tar.gz
   tar -xvf /mnt/live-bootstrap/distfiles.tar
fi
./download-distfiles.sh
echo "Ready to bootstrap"
./rootfs.py -c --external-sources --cores $CORES