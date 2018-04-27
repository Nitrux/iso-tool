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

mount -t proc none $FS_DIR/proc || exit 1
mount -t devtmpfs none $FS_DIR/dev || exit 1

mkdir -p /dev/pts
mount -t devpts none $FS_DIR/dev/pts || exit 1

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

echo -n $(du -sx --block-size=1 . | tail -n 1 | awk '{ print $1 }') > casper/filesystem.size


# Create the ISO image.

GRUB_MODULES="
boot
linux
linux16
normal
configfile
part_gpt
part_msdos
fat
iso9660
ext2
btrfs
udf
test
keystatus
loopback
regexp
probe
search
searc_fs_uuid
searc_fs_label
efi_gop
efi_uga
all_video
gfxterm
font
png
jpeg
echo
read
help
ls
cat
halt
reboot
"

GRUB_MODULES=$(echo $GRUB_MODULES | tr '\n' ' ')

mkdir -p efi/boot/
grub-mkimage -o efi/boot/bootx64.efi -O x86_64-efi -p /boot/grub $GRUB_MODULES

git clone https://github.com/nomad-desktop/nomad-grub-theme --depth=1

cp nomad-grub-theme/nomad/* boot/grub/
rm -r nomad-grub-theme

xorriso -as mkisofs \
	-r -V "NITRUX_OS" -cache-inodes -J -l
	-isohybrid-mbr boot/isolinux/isohdpfx.bin \
	-c isolinux/boot.cat
	-b isolinux/isolinux.bin
	-no-emul-boot
	-boot-load-size 4
	-boot-info-table
	-eltorito-alt-boot
	-e boot/efi/bootx64.efi
	-no-emul-boot
	-isohybrid-gpt-basdat
	-o ../nxos.iso

echo "zsync|http://server.domain/path/your.iso.zsync" | dd of=../nxos.iso bs=1 seek=33651 count=512 conv=notrunc
