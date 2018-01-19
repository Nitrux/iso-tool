#! /bin/sh

wget http://cdimage.ubuntu.com/kubuntu/releases/17.10.1/release/kubuntu-17.10.1-desktop-i386.iso os.iso
wget http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages

cat <<< $(grep 'Filename: ' Packages) > Packages

mkdir mnt
sudo mount os.iso mnt

mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt extract-cd
sudo unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit

mkdir packages
for p in $(cat Packages); do
	wget http://repo.nxos.org/$p packages/${p##*/}
	sudo dpkg -x ${p##*/} edit
done

sudo rm -rf edit/tmp/*

mksquashfs iso rootfs.sfs -comp xz
