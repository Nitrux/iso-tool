#! /bin/sh

# Download the base filesystem.

echo "Downloading base root filesystem."
wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz
wget -q http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz -O syslinux.tar.xz


# Prepare the ISO layout.

mkdir -p \
	iso/casper \
	iso/boot/isolinux


# Fill the new filesystem.

mkdir filesystem/
tar xf base.tar.gz -C filesystem/

sed -i 's/#.*$//;/^$/d' filesystem/etc/apt/sources.list
echo deb http://repo.nxos.org nxos main >> filesystem/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> filesystem/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> filesystem/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> filesystem/etc/apt/sources.list

rm -rf filesystem/dev/*

# Enable networking.
cp /etc/resolv.conf filesystem/etc/

# Packages for the new filesystem.
PACKAGES="nxos-desktop ubuntu-minimal casper lupin-casper base-files"

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
systemctl set-default graphical.target
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/nomad-logo/nomad-logo.plymouth 100
update-alternatives --install /usr/share/plymouth/themes/text.plymouth text.plymouth /usr/share/plymouth/themes/nomad-text/nomad-text.plymouth 100

apt-get download linux-generic linux-headers-generic
dpkg -i *.deb
rm -rf *.deb

KERNEL_VERSION=$(ls -1 /boot/vmlinuz-* | tail -n 1 | sed 's/vmlinuz-//')
depmod -a $KERNEL_VERSION
update-initramfs -u -k $KERNEL_VERSION
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
rm /etc/resolv.conf
"


# Use an updated initramfs.

KERNEL_VERSION=$(ls -1 filesystem/boot/vmlinuz-* | tail -n 1 | sed 's/vmlinuz-//')
cp -vp filesystem/boot/vmlinuz-$KERNEL_VERSION iso/casper/vmlinuz
cp -vp filesystem/boot/initrd.img-$KERNEL_VERSION iso/casper/initrd.img


# Clean things a little.

rm -rf filesystem/tmp/* \
	filesystem/boot/* \
	filesystem/vmlinuz* \
	filesystem/initrd.img* \
	filesystem/var/log/* \
	filesystem/var/lib/dbus/machine-id


# Compress the new filesystem.

(sleep 300; echo ' • • • ') &
echo "Compressing the new filesystem"
mksquashfs filesystem/ iso/casper/filesystem.squashfs -comp xz -no-progress -b 1M
printf $(du -sx --block-size=1 filesystem/ | cut -f 1) > iso/casper/filesystem.size


# Create the ISO file.

tar xf syslinux.tar.xz

cd iso
cp ../syslinux-6.03/bios/core/isolinux.bin \
	../syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 ./boot/isolinux

echo "default /casper/vmlinuz initrd=/casper/initrd.img boot=casper quiet splash" > boot/isolinux/isolinux.cfg

find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt

# TODO: support UEFI by default.
xorriso -as mkisofs -V "Nitrux_live" \
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
