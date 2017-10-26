#! /bin/sh

set -e

# - - - MESSAGE FORMATTING FUNCTIONS.

say () { printf "\n\n\n\e[32m  # # # $@ \e[0m\n\n"; }
err () { printf "\n\n\n\e[31m  # # # $@ \e[0m\n\n"; }


# - - - CLEAN THE WORKSPACE AND START FROM SCRATCH.

clean () {
	rm -rf \
		iso/*       \
		rootfs/*    \
		build/*     \
		initramfs/*
}


# - - - DOWNLOAD THE NECESSARY SOURCE FILES.

get_source () {
	say "DOWNLOADING $(basename $1)..."
	wget --no-clobber -c -q --show-progress -O build/sources/"$2.tar.xz" "$1" && {
		say "EXTRACTING $(basename $1)"
		tar -C build/sources -xf "$(basename $1)"
	}
}

# - - - LETS DO SOME MAGIC.

source config || { say "CAN'T CONTINUE. NO CONFIG FILE FOUND"; exit; }


# - - - CREATE THE DIRECTORY LAYOUT.

[[ "$( tr [:upper:] [:lower:] <<< $1)" == "clean" ]] && clean

mkdir -p \
	rootfs             \
	build/sources      \
	build/configs      \
	iso/boot/isolinux  \
	initramfs/dev      \
	initramfs/sys      \
	initramfs/bin      \
	initramfs/sbin     \
	initramfs/proc     \
	initramfs/usr/bin  \
	initramfs/usr/sbin


# - - - BUILD THE KERNEL IF IT'S NEEDED.

if [[ ! -f build/kernel/arch/x86/boot/bzImage ]]; then
	get_source $kernel_url kernel
fi

if [[ -f build/configs/kernel.config && "$use_old_kernel_config" == "yes" ]]; then
	cp build/configs/kernel.config build/sources/kernel/.config
	yes "" | make -C build/sources/kernel/ oldconfig bzImage
else
	make -C build/sources/kernel defconfig menuconfig bzImage
fi

cp build/sources/kernel/arch/x86/boot/bzImage iso/boot/vmlinuz


# - - - INSTALL SYSLINUX.

if [[ ! -d build/sources/bootloader ]];then
	get_source $syslinux_url bootloader
fi

cp build/sources/bootloader/bios/mbr/isohdpfx.bin \
		build/sources/bootloader/bios/core/isolinux.bin \
		build/sources/bootloader/bios/com32/elflink/ldlinux/ldlinux.c32 \
		iso/boot/isolinux/

printf "default /boot/vmlinuz initrd=/boot/initramfs.gz" > iso/boot/isolinux/isolinux.cfg


# - - - CREATE THE INITRAMFS FILE.

chmod +x initramfs/init
find initramfs | cpio -R root:root -H newc -o | gzip > iso/boot/initramfs.gz


# - - - CREATE A SQUASH FILESYSTEM WITH THE CONTENT OF `rootfs/`.

mksquashfs rootfs/ iso/rootfs.sfs -noappend -no-progress -comp xz


# - - - CREATE A WRITEABLE FILESYSTEM (PSEUDO-ROOT).

dd if=/dev/zero of=fake-disk.img bs=1024 count=0 seek=$[1024*100]
mkfs -t ext4 fake-disk.img


# - - - CREATE THE ISO FILE.

xorriso -as mkisofs iso/                           \
	-output "os.iso"                               \
	-iso-level 3                                   \
	-no-emul-boot                                  \
	-boot-load-size 4                              \
	-boot-info-table                               \
	-volid "ROOTFILESYSTEM"                        \
	-full-iso9660-filenames                        \
	-publisher "Nitrux S.A"                        \
	-eltorito-catalog boot/isolinux/boot.cat       \
	-eltorito-boot boot/isolinux/isolinux.bin      \
	-isohybrid-mbr iso/boot/isolinux/isohdpfx.bin

say "WE'RE DONE, DUDE. YOUR LINUX WAS SAVED AS `os.iso`"
