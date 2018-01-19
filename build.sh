#! /bin/sh

mkdir out

wget http://cdimage.ubuntu.com/kubuntu/releases/17.10.1/release/kubuntu-17.10.1-desktop-i386.iso -O os.iso
wget http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages

mkdir mnt
sudo mount os.iso mnt

mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt extract-cd
mkdir edit
sudo unsquashfs -d edit -n mnt/casper/filesystem.squashfs

mkdir packages
for p in $(grep -e 'Filename:.*' Packages | sed 's/Filename: //'); do
	wget http://repo.nxos.org/$p packages/${p##*/}
	sudo dpkg -x ${p##*/} edit
done

sudo rm -rf edit/tmp/*

sudo chmod +w extract-cd/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz -e edit/boot
sudo printf $(du -sx --block-size=1 edit | cut -f 1) > extract-cd/casper/filesystem.size

cd extract-cd
sudo sed -i 's/DISKNAME.*/DISKNAME Nitrux 1.0.8 \"SolarStorm\" - Release amd64/g' README.diskdefines
sudo rm md5sum.txt

sudo find -type f -print 0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt
sudo mkisofs -D -r -V "Nitrux Live" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../out/Nitrux-1.0.8-SolarStorm.iso .
