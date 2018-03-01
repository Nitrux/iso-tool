#! /bin/sh

# Prepare the root filesystem.

mkdir -p \
	filesystem \
	iso/casper \
	iso/boot/isolinux

wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz
tar xf base.tar.gz -C filesystem/
rm -rf filesystem/dev/*
cp /etc/resolv.conf filesystem/etc/

mkdir -p \
	filesystem/dev \
	filesystem/proc

mount -o bind /dev filesystem/dev || exit 1
mount -o bind /proc filesystem/proc || exit 1


# Install the nxos-desktop to `filesystem/`

PACKAGES="nxos-desktop sddm base-files casper lupin-casper linux-image-generic"
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
	apt-get -qq install $PACKAGES > /dev/null || exit 1
	apt-get clean
	useradd -m -U -G sudo,cdrom,adm,dip,plugdev -p '' me
	echo 'me:nitrux' | chpasswd
	hostnamectl set-hostname nitrux
	systemctl enable sddm
	find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
	rm /etc/resolv.conf
"

umount filesystem/proc
umount filesystem/dev

cp filesystem/vmlinuz iso/boot/linux
cp filesystem/initrd.img iso/boot/initramfs


# Clean the filesystem.

rm -rf filesystem/tmp/* \
	filesystem/boot/* \
	filesystem/vmlinuz* \
	filesystem/initrd.img* \
	filesystem/var/log/* \
	filesystem/var/lib/dbus/machine-id


# Compress the root filesystem and create the ISO.

(sleep 300; echo ' • ') &
echo "Compressing the root filesystem"
mksquashfs filesystem/ iso/casper/filesystem.squashfs -comp xz -no-progress


wget https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz -O - | tar xJf -

SL=syslinux-6.03
cp $SL/bios/core/isolinux.bin \
	$SL/bios/mbr/isohdpfx.bin \
	$SL/bios/com32/menu/menu.c32 \
	$SL/bios/com32/lib/libcom32.c32 \
	$SL/bios/com32/menu/vesamenu.c32 \
	$SL/bios/com32/libutil/libutil.c32 \
	$SL/bios/com32/elflink/ldlinux/ldlinux.c32 \
	iso/boot/isolinux/

rm -rf $SL*

cd iso/

wget -q -nc https://raw.githubusercontent.com/nomad-desktop/isolinux-nomad-theme/master/splash.png -O boot/isolinux/splash.png
wget -q -nc https://raw.githubusercontent.com/nomad-desktop/isolinux-nomad-theme/master/theme.txt -O boot/isolinux/theme.txt

echo '
default vesamenu.c32
include theme.txt

menu title Installer boot menu.
label Try Nitrux
	kernel /boot/linux
	append initrd=/boot/initramfs boot=casper elevator=noop quiet splash

label Try Nitrux (safe graphics mode)
	kernel /boot/linux
	append initrd=/boot/initramfs boot=casper nomodeset elevator=noop quiet splash

menu tabmsg Press ENTER to boot or TAB to edit a menu entry
' > boot/isolinux/syslinux.cfg

echo -n $(du -sx --block-size=1 . | tail -1 | awk '{ print $1 }') > casper/filesystem.size

# TODO: create UEFI images.

xorriso -as mkisofs \
	-o ../nxos.iso \
	-no-emul-boot \
	-boot-info-table \
	-boot-load-size 4 \
	-c boot/isolinux/boot.cat \
	-b boot/isolinux/isolinux.bin \
	-isohybrid-mbr boot/isolinux/isohdpfx.bin \
	./
