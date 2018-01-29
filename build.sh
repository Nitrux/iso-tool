#! /bin/sh

# Download the base filesystem and the ISO.

echo "Downloading base system..."
wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz
echo "Downloading root filesystem"
wget -q http://releases.ubuntu.com/16.04.3/ubuntu-16.04.3-desktop-amd64.iso -O os.iso


# Extract the iso contents.

mkdir iso
xorriso -acl on -xattr on -indev os.iso -osirrox on -extract / iso/


# Fill the new filesystem.
# Packages for it:

PACKAGES="nxos-desktop"

mkdir base
tar xf base.tar.gz -C base/

echo deb http://repo.nxos.org nxos main >> base/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> base/etc/apt/sources.list

cp /etc/resolv.conf base/etc/

chroot base/ sh -c "apt-get install -y busybox-static"
chroot base/ sh -c "busybox wget -qO - http://repo.nxos.org/public.key | apt-key add -"
chroot base/ sh -c "busybox wget -qO - http://origin.archive.neon.kde.org/public.key | apt-key add -"
chroot base/ sh -c "apt-get -y update"
chroot base/ sh -c "apt-get -y upgrade"
chroot base/ sh -c "apt-get -y install $PACKAGES"
chroot base/ sh -c "apt-get -y autoremove"
chroot base/ sh -c "apt-get -y clean"


# Clean things a little.

rm -rf base/tmp/* base/vmlinuz* base/initrd.img* base/boot/ base/var/*
chmod +w iso/casper/filesystem.manifest
chroot base/ dpkg-query -W --showformat='${Package} ${Version}\n' > iso/casper/filesystem.manifest
cp iso/casper/filesystem.manifest iso/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' iso/casper/filesystem.manifest-desktop
sed -i '/casper/d' iso/casper/filesystem.manifest-desktop


# Compress the new filesystem.

echo "Compressing the new filesystem"
mksquashfs base/ iso/casper/filesystem.squashfs -comp xz -noappend -no-progress
printf $(du -sx --block-size=1 base | cut -f 1) > iso/casper/filesystem.size

cd iso
sed -i 's/#define DISKNAME.*/DISKNAME Nitrux 1.0.9 "NXOS" - Release amd64/' README.diskdefines
rm md5sum.txt

find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt

xorriso -as mkisofs -r -V "Nitrux_Live" \
	-J -l -b isolinux/isolinux.bin \
	-c isolinux/boot.cat -no-emul-boot \
	-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
	-eltorito-alt-boot \
	-isohybrid-gpt-basdat \
	-boot-load-size 4 -boot-info-table \
	-o ../nitruxos.iso ./
