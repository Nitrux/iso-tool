#! /bin/sh -e

FS_DIR=filesystem
ISO_DIR=iso_image
CONFIG_DIR=config
IMAGE_NAME=nitrux

# Prepare the root filesystem.

mkdir -p filesystem

wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04-base-amd64.tar.gz
tar xf *.tar.gz -C filesystem


# Run a command in a chroot safely.
rm -rf $FS_DIR/dev/*
cp /etc/resolv.conf filesystem/etc

mount -t proc none $FS_DIR/proc || exit 1
mount -t devtmpfs none $FS_DIR/dev || exit 1
mkdir -p /dev/pts
mount -t devpts none $FS_DIR/dev/pts || exit 1

cp $CONFIG_DIR/config.sh $FS_DIR
chroot $FS_DIR/ sh -c /config.sh
rm -r $FS_DIR/config.sh

umount -f $FS_DIR/dev/pts $FS_DIR/dev $FS_DIR/proc

cp $FS_DIR/vmlinuz $ISO_DIR/boot/kernel
cp $FS_DIR/initrd.img $ISO_DIR/boot/initramfs


# Clean the filesystem.

rm -rf $FS_DIR/tmp/* \
	$FS_DIR/boot \
	$FS_DIR/vmlinuz* \
	$FS_DIR/initrd.img* \
	$FS_DIR/var/log/* \
	$FS_DIR/var/lib/dbus/machine-id


# Compress the root filesystem.

(sleep 300; echo +) &
echo "Compressing the root filesystem"
mkdir -p $ISO_DIR/casper
mksquashfs $FS_DIR $ISO_DIR/casper/filesystem.squashfs -comp xz -no-progress
kill $!


# Create the ISO image.

cd $ISO_DIR
echo -n $(du -sx --block-size=1 . | tail -n 1 | awk '{ print $1 }') > casper/filesystem.size

xorriso -as mkisofs -r -J -l \
	-V '#NITRUX' \
	-isohybrid-mbr boot/isolinux/isohdpfx.bin \
	-c boot/isolinux/boot.cat \
	-b boot/isolinux/isolinux.bin \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
	-no-emul-boot \
	-isohybrid-gpt-basdat \
	-o ../$IMAGE_NAME.iso .

zsyncmake $IMAGE_NAME.iso
echo "zsync|http://server.domain/path/your.iso.zsync" | dd of=$IMAGE_NAME.iso bs=1 seek=33651 count=512 conv=notrunc

curl -i -F filedata=@checksum -F filedata=@$IMAGE_NAME.iso https://transfer.sh | sed 's/http/\nhttp/g' | grep http > urls
sha256sum $IMAGE_NAME.iso > checksum
