#! /bin/sh

(for c in $(seq 50); do echo $c; sleep 60; done) &

echo "Downloading base system..."
wget -q http://cdimage.ubuntu.com/kubuntu/releases/17.10.1/release/kubuntu-17.10.1-desktop-i386.iso -O os.iso

mkdir mnt out extract-cd lower upper work edit packages
mount os.iso mnt

rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

mount mnt/casper/filesystem.squashfs lower
mount -t overlay -o lowerdir=lower,upperdir=upper,workdir=work none edit

echo "Downloading Nomad packages..."

echo deb http://repo.nxos.org nxos main >> edit/etc/apt/sources.list
echo deb http://repo.nxos.org xenial main >> edit/etc/apt/sources.list

wget -q http://repo.nxos.org/public.key -O edit/key
apt-key add edit/key
chroot edit/ apt-key add key

apt-get -o Dir=edit/ -qq -y update
apt-get -o Dir=edit/ -qq -y install rfkill systemd-sysv librsvg2-dev nxos-desktop

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
