#!/bin/bash
set -e

set -u

# hat-tips:
# - http://codeghar.wordpress.com/2011/12/14/automated-customized-debian-installation-using-preseed/
# - the gist

# required packages (apt-get install)
# xorriso
# syslinux

ISOFILE=debian.iso
ISOFILE_FINAL=rogers.iso
ISODIR=debian-iso
ISODIR_WRITE=$ISODIR-rw

# download ISO:
#wget -nc -O $ISOFILE http://cdimage.debian.org/cdimage/wheezy_di_rc3/amd64/iso-cd/debian-wheezy-DI-rc3-amd64-netinst.iso || true
#wget -nc -O $ISOFILE https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current/amd64/iso-cd/firmware-8.7.1-amd64-netinst.iso || true

echo 'mounting ISO9660 filesystem...'
# source: http://wiki.debian.org/DebianInstaller/ed/EditIso
[ -d $ISODIR ] || mkdir -p $ISODIR
sudo mount -o loop $ISOFILE $ISODIR

echo 'coping to writable dir...'
rm -rf $ISODIR_WRITE || true
[ -d $ISODIR_WRITE ] || mkdir -p $ISODIR_WRITE
rsync -a -H --exclude=TRANS.TBL $ISODIR/ $ISODIR_WRITE

echo 'unmount iso dir'
sudo umount $ISODIR

echo 'correcting permissions...'
chmod 755 -R $ISODIR_WRITE

echo 'copying preseed file...'
cp preseed.final $ISODIR_WRITE/preseed.cfg

echo 'switching  isolinux.cfg...'
cp isolinux.final $ISODIR_WRITE/isolinux/isolinux.cfg

echo 'edit isolinux/txt.cfg...'
sed 's/initrd.gz/initrd.gz file=\/cdrom\/preseed.cfg/' -i $ISODIR_WRITE/isolinux/txt.cfg

sudo mkdir irmod
cd irmod
sudo gzip -d < ../$ISODIR_WRITE/install.amd/initrd.gz | \
sudo cpio --extract --make-directories --no-absolute-filenames
sudo cp ../preseed.final preseed.cfg
sudo chown root:root preseed.cfg
sudo chmod o+w ../$ISODIR_WRITE/install.amd/initrd.gz
find . | cpio -H newc --create | \
        gzip -9 > ../$ISODIR_WRITE/install.amd/initrd.gz
sudo chmod o-w ../$ISODIR_WRITE/install.amd/initrd.gz
cd ../
sudo rm -fr irmod/

echo 'fixing MD5 checksums...'
pushd $ISODIR_WRITE
  md5sum $(find -type f) > md5sum.txt
popd


MBR_TEMPLATE=isohdpfx.bin

# Extract MBR template file to disk
dd if="$ISOFILE" bs=1 count=432 of="$MBR_TEMPLATE"

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
# and if that doesn't work:
# http://askubuntu.com/questions/6684/preseeding-ubuntu-server


echo "Clean up ..."
sudo rm -rf $ISODIR $ISODIR_WRITE $MBR_TEMPLATE

