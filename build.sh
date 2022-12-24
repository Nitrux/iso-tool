#! /bin/bash

[ "$__time_traced" ] ||
	__time_traced=yes exec time "$0" "$@"

#	Exit on errors.

set -xe


#	Travis stuff.

XORRISO_PKGS='
	libburn4
	libisoburn1
	libisofs6
	libjte2
	mtools
	sshpass
	xorriso
'

GRUB_EFI_PKGS='
	grub-efi-amd64
	grub-efi-amd64-signed
	shim-signed
'

apt -qq update
apt -yy install $XORRISO_PKGS $GRUB_EFI_PKGS --no-install-recommends > /dev/null


#	base image URL.

base_img_url=https://raw.githubusercontent.com/Nitrux/storage/master/RootFS/Debian/Unstable/rootfs.tar.xz


#	Prepare the directories for the build.

build_dir=$(mktemp -d)
iso_dir=$(mktemp -d)
output_dir=$(mktemp -d)

chmod 755 $build_dir

config_dir=$PWD/configs


#	The name of the ISO image.

image=nitrux-$(git branch --show-current | sed "s/legacy/nx-desktop/")-$(git rev-parse --short=8 HEAD)-$(uname -m | sed "s/x86_64/amd64/").iso
hash_url=http://releases.nxos.org/${image%.iso}.md5sum


#	Prepare the directory where the filesystem will be created.

wget -qO base.tar.xz $base_img_url
tar xf base.tar.xz -C $build_dir


#	Populate $build_dir.

wget -qO /bin/runch https://raw.githubusercontent.com/Nitrux/tools/master/runch
chmod +x /bin/runch

< bootstrap.sh runch \
	-m configs:/configs \
	-r /configs \
	$build_dir \
	bash || :


#	Check filesystem size.

du -hs $build_dir


#	Remove CI leftovers.

rm -r $iso_dir/home/{travis,Travis} || true


#	Copy the kernel and initramfs to $iso_dir.
#	BUG: vmlinuz and initrd are not moved to $iso_dir/; they're left at $build_dir/boot

mkdir -p $iso_dir/boot

cp $(echo $build_dir/boot/vmlinuz* | tr " " "\n" | sort | tail -n 1) $iso_dir/boot/kernel
cp $(echo $build_dir/boot/initrd*  | tr " " "\n" | sort | tail -n 1) $iso_dir/boot/initramfs


#	WARNING FIXME BUG: This file isn't copied during the chroot.

mkdir -p $iso_dir/boot/grub/x86_64-efi
cp /usr/lib/grub/x86_64-efi/linuxefi.mod $iso_dir/boot/grub/x86_64-efi


#	Copy EFI folder to ISO

cp -r EFI/ $iso_dir/


#	Copy ucode to ISO

cp -r ucode/ $iso_dir/boot/


#	Compress the root filesystem.

( while :; do sleep 300; printf ".\n"; done ) &

mkdir -p $iso_dir/casper
mksquashfs $build_dir $iso_dir/casper/filesystem.squashfs -comp zstd -Xcompression-level 22 -no-progress -b 1048576


#	Generate the ISO image.

wget -qO /bin/mkiso https://raw.githubusercontent.com/Nitrux/tools/master/mkiso
chmod +x /bin/mkiso

git clone https://github.com/Nitrux/nitrux-grub-theme grub-theme

mkiso \
	-V "NITRUX" \
	-b \
	-e \
	-s "$hash_url" \
	-r "$(git rev-parse --short=8 HEAD)" \
	-g $config_dir/files/grub.cfg \
	-g $config_dir/files/loopback.cfg \
	-t grub-theme/nitrux \
	$iso_dir $output_dir/$image


#	Calculate the checksum.

md5sum $output_dir/$image > $output_dir/${image%.iso}.md5sum


#	Move files to current directory

mv $output_dir/* $PWD


#	Clean up build directories

rm -r \
	base.tar.{xz,gz} \
	/tmp/tmp.* \
	grub-theme || true
