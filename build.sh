#! /bin/sh

# Download the base filesystem and the ISO.

echo "Downloading base system."
wget -q http://cdimage.ubuntu.com/ubuntu-base/releases/16.04.3/release/ubuntu-base-16.04.3-base-amd64.tar.gz -O base.tar.gz
echo "Downloading root filesystem."
wget -q http://releases.ubuntu.com/16.04.3/ubuntu-16.04.3-desktop-amd64.iso -O os.iso


# Extract the iso contents.

mkdir iso
xorriso -acl on -xattr on -indev os.iso -osirrox on -extract / iso/


# Fill the new filesystem.

mkdir base
tar xf base.tar.gz -C base/

echo deb http://repo.nxos.org nxos main >> base/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> base/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> base/etc/apt/sources.list

mkdir -p base/var
cp /etc/resolv.conf base/etc/

# Packages for the new filesystem.
PACKAGES="nxos-desktop"

chroot base/ sh -c "
export HOME=/root
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
apt-get install -y busybox-static
busybox wget -qO - http://repo.nxos.org/public.key | apt-key add -
busybox wget -qO - http://origin.archive.neon.kde.org/public.key | apt-key add -
apt-get -y update
apt-get -y install $PACKAGES
apt-get -y autoremove
apt-get -y clean
useradd -m -G sudo,cdrom,adm,dip,plugdev,lpadmin,sambashare -p '' nitrux
" 2>&1 | grep -v 'locale:'


# Clean things a little.

chmod +w iso/casper/filesystem.manifest
chroot base/ dpkg-query -W --showformat='${Package} ${Version}\n' | sort -nr > iso/casper/filesystem.manifest
cp iso/casper/filesystem.manifest iso/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' iso/casper/filesystem.manifest-desktop
sed -i '/casper/d' iso/casper/filesystem.manifest-desktop
# When producing images for use with ostree, delete `base/var/*`.
rm -rf base/tmp/* base/vmlinuz* base/initrd.img* base/boot/ base/var/lib/dbus/machine-id


# Compress the new filesystem.

echo "Compressing the new filesystem"
(sleep 300; echo -e '\u2022') &
mksquashfs base/ iso/casper/filesystem.squashfs -comp xz -noappend -no-progress
printf $(du -sx --block-size=1 base/ | cut -f 1) > iso/casper/filesystem.size

cd iso
sed -i 's/#define DISKNAME.*/DISKNAME Nitrux 1.0.9 "NXOS" - Release amd64/' README.diskdefines
rm md5sum.txt && echo "REMOVED OLD md5sum.txt"

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
	-isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
	-o ../nitruxos.iso ./

md5sum ../nitruxos.iso
