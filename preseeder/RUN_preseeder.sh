#!/bin/bash

####################
# ERROR MANAGEMENT #
####################

set -e
set -u

if [ "$#" -ne 1 ]; then
    echo "Need the original iso as argument - run as sudo"
    exit 1
fi

# required packages (apt-get install)
apt-get install xorriso

###################
# INIT CONF FILES #
###################

source config.sh
./config.sh


ISOFILE=$1
ISOFILE_FINAL=$ISO_MOD
ISODIR=debian-iso
ISODIR_WRITE=$ISODIR-rw

#####################
# MOUNTING ISO FILE #
#####################

echo 'mounting ISO9660 filesystem...'
[ -d $ISODIR ] || mkdir -p $ISODIR
sudo mount -o loop $ISOFILE $ISODIR

#####################
# CREATE EDIT COPY  #
#####################

echo 'coping to writable dir...'
rm -rf $ISODIR_WRITE || true
[ -d $ISODIR_WRITE ] || mkdir -p $ISODIR_WRITE
rsync -a -H --exclude=TRANS.TBL $ISODIR/ $ISODIR_WRITE
echo 'correcting permissions...'
chmod 755 -R $ISODIR_WRITE

#####################
#   UNMOUNT ISO     #
#####################

echo 'unmount iso dir'
sudo umount $ISODIR


#####################
#  SWITCHING FILES  #
#####################

echo 'copying preseed file...'
cp preseed.cfg $ISODIR_WRITE/preseed.cfg


echo 'adding post-install script'
mv postinstall.sh $ISODIR_WRITE/postinstall.sh

echo 'switching  isolinux.cfg to skip install grub'
mv isolinux.cfg $ISODIR_WRITE/isolinux/isolinux.cfg

#################################
#  ADDING PRESEED TO INITRD.GZ  #
#################################

sudo rm -rf irmod
sudo mkdir irmod
cd irmod
sudo gzip -d < ../$ISODIR_WRITE/install.amd/initrd.gz | \
sudo cpio --extract --make-directories --no-absolute-filenames
sudo mv ../preseed.cfg preseed.cfg
sudo chown root:root preseed.cfg
sudo chmod o+w ../$ISODIR_WRITE/install.amd/initrd.gz
find . | cpio -H newc --create | \
        gzip -9 > ../$ISODIR_WRITE/install.amd/initrd.gz
sudo chmod o-w ../$ISODIR_WRITE/install.amd/initrd.gz
cd ../
sudo rm -fr irmod/

echo 'edit isolinux/txt.cfg...'
sed 's/initrd.gz/initrd.gz file=\/cdrom\/preseed.cfg/' -i $ISODIR_WRITE/isolinux/txt.cfg

#################################
#  FIXING DIRECTORY CHECKSUM    #
#################################

echo 'fixing MD5 checksums...'
pushd $ISODIR_WRITE
  md5sum $(find -type f) > md5sum.txt
popd


#################################
#  GETTING TEMPLATE FROM ISO    #
#################################
MBR_TEMPLATE=isohdpfx.bin

# Extract MBR template file to disk
dd if="$ISOFILE" bs=1 count=432 of="$MBR_TEMPLATE"

######################
#  BUILDING NEW ISO  #
######################

# Create the new ISO image
xorriso -as mkisofs \
   -r -J --joliet-long \
   -V 'Debian jessie 20160402-22:24' \
   -o "$ISOFILE_FINAL" \
   -isohybrid-mbr "$MBR_TEMPLATE" \
   -partition_offset 16 \
   -c isolinux/boot.cat \
   -b isolinux/isolinux.bin \
   -no-emul-boot -boot-load-size 4 -boot-info-table \
   "$ISODIR_WRITE"

###############
# CLEANING UP #
###############

echo "Clean up ..."
#sudo rm -rf $ISODIR $ISODIR_WRITE $MBR_TEMPLATE

