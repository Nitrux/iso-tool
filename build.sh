#! /bin/sh

echo "Downloading base system..."
wget -q http://cdimage.ubuntu.com/kubuntu/releases/17.10.1/release/kubuntu-17.10.1-desktop-i386.iso -O os.iso
wget -q http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages

mkdir mnt out extract-cd lower upper work edit packages
mount os.iso mnt

rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

mount mnt/casper/filesystem.squashfs lower
mount -t overlay -o lowerdir=lower,upperdir=upper,workdir=work none edit

echo "Downloading Nomad packages..."
for p in $(grep -e 'Filename:.*' Packages | sed 's/Filename: //'); do
	wget -q http://repo.nxos.org/$p -O packages/${p##*/}
	dpkg -x packages/${p##*/} edit
done

rm -rf edit/tmp/* edit/vmlinuz edit/initrd.img edit/boot
chmod +w extract-cd/casper/filesystem.manifest
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop
rm extract-cd/casper/filesystem.squashfs
(for c in $(seq 0 59); do echo $c; done) &
mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz -noappend -noprogress
printf $(du -sx --block-size=1 edit | cut -f 1) > extract-cd/casper/filesystem.size
cd extract-cd
sed -i 's/DISKNAME.*/DISKNAME Nitrux 1.0.8 \"SolarStorm\" - Release amd64/g' README.diskdefines
rm md5sum.txt
find -type f -print 0 | xargs -0 md5sum | grep -v isolinux/boot.cat | tee md5sum.txt
mkisofs -D -r -V "Nitrux Live" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../out/os.iso .
