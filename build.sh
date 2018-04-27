#! /bin/sh

# Prepare the root filesystem.

mkdir -p \
	filesystem \
	iso/casper \
	iso/boot/isolinux

wget -q http://cdimage.ubuntu.com/ubuntu-base/daily/current/bionic-base-amd64.tar.gz
tar xf *.tar.gz -C filesystem/


# Run a command in a chroot safely.

FS_DIR=filesystem/

rm -rf $FS_DIR/dev/*
cp /etc/resolv.conf filesystem/etc/

mount -t proc -o nodev none $FS_DIR/proc || exit 1
mount -t devtmpfs -o nodev none $FS_DIR/dev || exit 1

mkdir -p /dev/pts
mount -t devpts -o nodev none $FS_DIR/dev/pts || exit 1

cp ./config/config.sh $FS_DIR/
chroot $FS_DIR/ sh -c "/config.sh"
rm -r $FS_DIR/config.sh

umount -f $FS_DIR/dev/pts
umount -f $FS_DIR/dev
umount -f $FS_DIR/proc

cp $FS_DIR/vmlinuz iso/boot/kernel
cp $FS_DIR/initrd.img iso/boot/initramfs


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
mksquashfs $FS_DIR/ iso/casper/filesystem.squashfs -comp xz -no-progress


# Download SYSLINUX.

wget -q -nc https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
tar xf syslinux-6.03.tar.xz

SL=syslinux-6.03
cp $SL/bios/core/isolinux.bin \
	$SL/bios/mbr/isohdpfx.bin \
	$SL/bios/com32/menu/menu.c32 \
	$SL/bios/com32/lib/libcom32.c32 \
	$SL/bios/com32/menu/vesamenu.c32 \
	$SL/bios/com32/libutil/libutil.c32 \
	$SL/bios/com32/elflink/ldlinux/ldlinux.c32 \
	iso/boot/isolinux/


# Prepare the ISO files.

cd iso/

wget -q https://raw.githubusercontent.com/nomad-desktop/isolinux-theme-nomad/master/splash.png -O boot/isolinux/splash.png
wget -q https://raw.githubusercontent.com/nomad-desktop/isolinux-theme-nomad/master/theme.txt -O boot/isolinux/theme.txt

echo '
default vesamenu.c32
include theme.txt

menu title Installer boot menu.
label Try Nitrux
	kernel /boot/kernel
	append initrd=/boot/initramfs boot=casper elevator=noop quiet splash

label Try Nitrux (safe graphics mode)
	kernel /boot/kernel
	append initrd=/boot/initramfs boot=casper nomodeset elevator=noop quiet splash

menu tabmsg Press ENTER to boot or TAB to edit a menu entry
' > boot/isolinux/syslinux.cfg

echo -n $(du -sx --block-size=1 . | tail -n 1 | awk '{ print $1 }') > casper/filesystem.size


# TODO: create UEFI images.
# Create the ISO image.

xorriso -as mkisofs \
	-o ../nxos.iso \
	-no-emul-boot \
	-boot-info-table \
	-boot-load-size 4 \
	-c boot/isolinux/boot.cat \
	-b boot/isolinux/isolinux.bin \
	-isohybrid-mbr boot/isolinux/isohdpfx.bin \
	./

echo "zsync|http://server.domain/path/your.iso.zsync" | dd of=../nxos.iso bs=1 seek=33651 count=512 conv=notrunc
