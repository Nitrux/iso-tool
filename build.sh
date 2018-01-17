#! /bin/sh

# Build.

wget -q http://archive.ubuntu.com/ubuntu/dists/zesty/main/installer-amd64/current/images/netboot/mini.iso
wget -q http://repo.nxos.org/dists/nxos/main/binary-amd64/Packages nomad-packages

grep 'Filename: ' nomad-packages > urls.txt

mkdir newroot
for package in $(cat urls.txt); do
	wget -q http://repo.nxos.org/$package 
	dpkg -x ${package##*/} newroot/
done

mkdir mnt
mount mini.iso mnt

mkdir iso

