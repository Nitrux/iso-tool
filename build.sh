#! /bin/sh

# Prepare the workspace.

mkdir -p \
	filesystem \
	iso/casper \
	iso/boot/isolinux \
	initramfs/bin

# Download the kernel.

wget -q https://github.com/luis-lavaire/kernel/releases/download/continuous/linux -O iso/boot/linux


# Build the initramfs. :)

wget -q https://github.com/luis-lavaire/busybox/releases/download/continuous/busybox -O initramfs/bin/busybox
chmod +x initramfs/bin/busybox
ln -s /bin/busybox initramfs/bin/sh
wget -q https://raw.githubusercontent.com/nglx/proton/master/init -O initramfs/init
chmod +x initramfs/init
(
	cd initramfs/
	find . | cpio -R root:root -H newc -o | gzip > ../iso/boot/initramfs
)


# Build the base filesystem.

echo "Downloading base root filesystem."
wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz
wget -q http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz -O syslinux.tar.xz

tar xf base.tar.gz -C filesystem/

sed -i 's/#.*$//;/^$/d' filesystem/etc/apt/sources.list
echo deb http://repo.nxos.org nxos main >> filesystem/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> filesystem/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> filesystem/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> filesystem/etc/apt/sources.list

rm -rf filesystem/dev/*
cp /etc/resolv.conf filesystem/etc/

PACKAGES="nxos-desktop ubuntu-minimal base-files sddm"

chroot filesystem/ sh -c "
export LANG=C
export LC_ALL=C
apt-get install -qq -y busybox
busybox wget -qO - http://repo.nxos.org/public.key | apt-key add -
busybox wget -qO - http://origin.archive.neon.kde.org/public.key | apt-key add -
apt-get -y update
apt-get -y -qq install $PACKAGES
apt-get -y clean
useradd -m -G sudo,cdrom,adm,dip,plugdev -p '' nitrux
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
rm /etc/resolv.conf
"

rm -rf filesystem/tmp/* \
	filesystem/boot/* \
	filesystem/vmlinuz* \
	filesystem/initrd.img* \
	filesystem/var/log/* \
	filesystem/var/lib/dbus/machine-id


(sleep 300; echo ' • • • ') &
echo "Compressing the new filesystem"
mksquashfs filesystem/ iso/casper/filesystem.squashfs -comp xz -no-progress -b 1M


# Create the ISO file.

wget -q http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
tar xf syslinux.tar.xz

cd iso
cp ../syslinux-6.03/bios/core/isolinux.bin \
	../syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 boot/isolinux

echo "default /boot/linux initrd=/boot/initramfs casper quiet splash" > boot/isolinux/isolinux.cfg

# TODO: support UEFI by default.
xorriso -as mkisofs -V "NXOS" \
	-J -l -D -r \
	-no-emul-boot \
	-cache-inodes \
	-boot-info-table \
	-boot-load-size 4 \
	-eltorito-alt-boot \
	-c boot/isolinux/boot.cat \
	-isohybrid-gpt-basdat \
	-b boot/isolinux/isolinux.bin \
	-isohybrid-mbr ../syslinux-6.03/bios/mbr/isohdpfx.bin \
	-o ../nitruxos.iso ./
