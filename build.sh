#! /bin/sh

# Prepare the workspace.

mkdir -p \
	filesystem \
	iso/casper \
	iso/boot/isolinux


# Build the base filesystem.

echo "Installing packages to root."
PACKAGES="nxos-desktop casper lupin-casper"

mkdir -p \
	filesystem/dev \
	filesystem/proc

mount -o bind /dev filesystem/dev || exit 1
mount -o bind /proc filesystem/proc || exit 1

debootstrap --components=main \
        --include=linux-image-generic \
        --exclude=nano \
        --arch amd64 xenial filesystem/ http://us.archive.ubuntu.com/ubuntu/

chroot filesystem/ sh -c "
export LANG=C
export LC_ALL=C

apt-get update
apt-get install -y apt-transport-https wget ca-certificates

sed -i 's/#.*$//;/^$/d' /etc/apt/sources.list

wget -q https://archive.neon.kde.org/public.key -O neon.key
if echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c; then
	apt-key add neon.key
	echo deb http://archive.neon.kde.org/dev/stable xenial main >> /etc/apt/sources.list
	echo deb http://archive.neon.kde.org/user xenial main >> /etc/apt/sources.list
fi
rm neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
if echo de7501e2951a9178173f67bdd29a9de45a572f19e387db5f4e29eb22100c2d0e nxos.key | sha256sum -c; then
	apt-key add nxos.key
	echo deb http://repo.nxos.org nxos main >> /etc/apt/sources.list
	echo deb http://repo.nxos.org xenial main >> /etc/apt/sources.list
fi
rm nxos.key

apt-get update
apt-get -qq install $PACKAGES
apt-get clean
useradd -m -U -G sudo,cdrom,adm,dip,plugdev me
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
rm /etc/resolv.conf
umount /dev
umount /proc
"

rm -rf filesystem/tmp/* \
	filesystem/boot/* \
	filesystem/vmlinuz* \
	filesystem/initrd.img* \
	filesystem/var/log/* \
	filesystem/var/lib/dbus/machine-id


# Add the kernel and the initramfs to the ISO.

echo "====================="
ls filesystem
echo "====================="
ls filesystem/*
echo "====================="
exit 1

cp filesystem/vmlinuz iso/boot/linux
cp filesystem/initrd.img iso/boot/initramfs

(sleep 300; echo ' • ') &
echo "Compressing the new filesystem"
mksquashfs filesystem/ iso/casper/filesystem.squashfs -comp xz -no-progress -b 1M


# Create the ISO file.

wget -q http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz -O syslinux.tar.xz
tar xf syslinux.tar.xz

cd iso
cp ../syslinux-6.03/bios/core/isolinux.bin \
	../syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 boot/isolinux/

echo "default /boot/linux initrd=/boot/initramfs BOOT=casper quiet splash" > boot/isolinux/isolinux.cfg
echo -n $(du -sx --block-size=1 . | tail -1 | awk '{ print $1 }') > casper/filesystem.size
find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt


# TODO: support UEFI by default.
xorriso -as mkisofs -V "NXOS" \
	-J -l -D -r \
	-no-emul-boot \
	-cache-inodes \
	-boot-info-table \
	-boot-load-size 4 \
	-eltorito-alt-boot \
	-c boot/isolinux/boot.cat \
	-b boot/isolinux/isolinux.bin \
	-isohybrid-mbr ../syslinux-6.03/bios/mbr/isohdpfx.bin \
	-o ../nitruxos.iso ./
