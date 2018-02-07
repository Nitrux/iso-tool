#! /bin/sh

# Download the base filesystem and the ISO.

echo "Downloading base system."
wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz


# Fill the new filesystem.

mkdir base
tar xf base.tar.gz -C base/

sed -i 's/#.*$//;/^$/d' base/etc/apt/sources.list
echo deb http://repo.nxos.org nxos main >> base/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> base/etc/apt/sources.list

rm -rf base/dev/*

# Enable networking.
cp /etc/resolv.conf base/etc/

# Packages for the new filesystem.
PACKAGES="nxos-desktop grub2-common wireless-tools wpasupplicant linux-image-generic initramfs-tools"

chroot base/ sh -c "
export LANG=C
export LC_ALL=C
apt-get install -y busybox-static
busybox wget -qO - http://repo.nxos.org/public.key | apt-key add -
busybox wget -qO - http://origin.archive.neon.kde.org/public.key | apt-key add -
apt-get -y update
echo Installing packages to the system...
apt-get -y -qq install $PACKAGES 2> /dev/null | grep linux-image-generic
apt-get -y clean
useradd -m -G sudo,cdrom,adm,dip,plugdev,lpadmin -p '' nitrux
sed 's/^GRUB_THEME=.*$//g' /usr/share/grub/default/grub > /etc/default/grub
echo GRUB_THEME=\"/usr/share/grub/themes/nomad/theme.txt\" >> /etc/default/grub
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/nomad-logo/nomad-logo.plymouth 100
update-alternatives --install /usr/share/plymouth/themes/text.plymouth text.plymouth /usr/share/plymouth/themes/nomad-text/nomad-text.plymouth 100
update-initramfs -v -d -k all
update-initramfs -v -c -k $(ls --color=never base/lib/modules/)
"


# Use the initramfs generated during package installation.

ls base/lib/modules/
ls base/boot/
exit 1
cp $(ls base/boot/initrd* | head -n 1) iso/casper/initrd.lz


# Clean things a little.

chmod +w iso/casper/filesystem.manifest
chroot base/ dpkg-query -W --showformat='${Package} ${Version}\n' | sort -n > iso/casper/filesystem.manifest
cp iso/casper/filesystem.manifest iso/casper/filesystem.manifest-desktop

rm -rf base/tmp/* \
	base/boot/* \
	base/vmlinuz* \
	base/initrd.img* \
	base/var/lib/dbus/machine-id


# Compress the new filesystem.

(sleep 300; echo ' • • • ') &
echo "Compressing the new filesystem"
mksquashfs base/ iso/casper/filesystem.squashfs -comp xz -no-progress -b 1M
printf $(du -sx --block-size=1 base/ | cut -f 1) > iso/casper/filesystem.size

cd iso
sed -i 's/#define DISKNAME.*/DISKNAME Nitrux 1.0.9 "NXOS" - Release amd64/' README.diskdefines

find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt

xorriso -as mkisofs -V "Nitrux_live" \
	-J -l -D -r \
	-no-emul-boot \
	-cache-inodes \
	-boot-info-table \
	-boot-load-size 4 \
	-eltorito-alt-boot \
	-c isolinux/boot.cat \
	-isohybrid-gpt-basdat \
	-b isolinux/isolinux.bin \
	-isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \
	-o ../nitruxos.iso ./
