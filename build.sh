#! /bin/sh

echo "Downloading base system..."
wget -q http://releases.ubuntu.com/16.04.3/ubuntu-16.04.3-desktop-amd64.iso -O os.iso

mkdir mnt out extract-cd lower upper work edit packages
mount os.iso mnt

rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

mount mnt/casper/filesystem.squashfs lower
mount -t overlay -o lowerdir=lower,upperdir=upper,workdir=work none edit

echo "Downloading Nomad packages..."

echo deb http://repo.nxos.org nxos main >> edit/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> edit/etc/apt/sources.list
echo deb http://archive.neon.kde.org/dev/stable xenial main >> edit/etc/apt/sources.list
echo deb http://archive.neon.kde.org/user xenial main >> edit/etc/apt/sources.list

cp /etc/resolv.conf edit/etc/

chroot edit/ sh -c 'wget -qO - http://repo.nxos.org/public.key | apt-key add -'
chroot edit/ sh -c 'wget -qO - https://origin.archive.neon.kde.org/public.key | sudo apt-key add -'
chroot edit/ sh -c 'apt-get -y update'
chroot edit/ sh -c 'apt-get -y install nxos-desktop'
chroot edit/ sh -c 'apt-get -y autoremove'
chroot edit/ sh -c 'apt-get -y clean'

rm -rf edit/tmp/* edit/vmlinuz edit/initrd.img edit/boot/
chmod +w extract-cd/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz -noappend -no-progress
printf $(du -sx --block-size=1 edit | cut -f 1) > extract-cd/casper/filesystem.size

cd extract-cd
sed -i 's/#define DISKNAME.*/DISKNAME Nitrux 1.0.8 "NXOS" - Release amd64/' README.diskdefines
rm md5sum.txt

find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt

xorriso -as mkisofs -r -V "Nitrux Live" \
        -cache-inodes \
        -J -l -b isolinux/isolinux.bin \
        -c isolinux/boot.cat -no-emul-boot \
        -isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
        -eltorito-alt-boot \
        -isohybrid-gpt-basdat \
        -boot-load-size 4 -boot-info-table \
        -o ../out/os.iso ./
