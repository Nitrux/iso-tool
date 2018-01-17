#! /bin/sh

wget -q http://archive.ubuntu.com/ubuntu/dists/zesty/main/installer-amd64/current/images/netboot/mini.iso
wget -q http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages nomad-packages

grep 'Filename: ' nomad-packages > urls.txt

mkdir packages
for package in $(cat urls.txt); do
	wget -q http://repo.nxos.org/$package 
	dpkg -x ${package##*/} packages/
done

wget -q https://github.com/NXOS/busybox/releases/download/continuous/busybox packages/usr/bin/busybox
chmod +x busybox

mkdir mnt
mount mini.iso mnt

mkdir upper work iso

mount -t overlay -o lowerdir=packages:mnt,upperdir=upper,workdir=work overlay iso

mksquashfs iso rootfs.sfs -comp xz
