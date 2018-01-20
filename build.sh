#! /bin/sh

mkdir out

wget -q http://cdimage.ubuntu.com/kubuntu/releases/17.10.1/release/kubuntu-17.10.1-desktop-i386.iso -O os.iso
wget -q http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages

mkdir mnt
sudo mount os.iso mnt

mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

mkdir lower upper work edit
sudo mount mnt/casper/filesystem.squashfs lower
sudo mount -t overlay -o lowerdir=lower,upperdir=upper,workdir=work none edit

mkdir packages
for p in $(grep -e 'Filename:.*' Packages | sed 's/Filename: //'); do
	wget http://repo.nxos.org/$p -O packages/${p##*/}
	sudo dpkg -x packages/${p##*/} edit
done

as_root () {
	rm -rf edit/tmp/* edit/vmlinuz edit/initrd.img edit/boot
	chmod +w extract-cd/casper/filesystem.manifest
	chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
	cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
	sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
	sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop
	rm extract-cd/casper/filesystem.squashfs
	mksquashfs edit extract-cd/casper/filesystem.squashfs -comp xz
	printf $(sudo du -sx --block-size=1 edit | cut -f 1) > extract-cd/casper/filesystem.size
	cd extract-cd
	sed -i 's/DISKNAME.*/DISKNAME Nitrux 1.0.8 \"SolarStorm\" - Release amd64/g' README.diskdefines
	rm md5sum.txt
	find -type f -print 0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt
	mkisofs -D -r -V "Nitrux Live" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../out/Nitrux-1.0.8-SolarStorm.iso .
}

sudo as_root
