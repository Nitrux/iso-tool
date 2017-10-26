#! /bin/sh

# - - - MESSAGE FORMATTING FUNCTIONS.

say () { printf "\n\n\n\e[32m  # # # $@ \e[0m\n\n"; }
err () { printf "\n\n\n\e[31m  # # # $@ \e[0m\n\n"; }


# - - - CLEAN THE WORKSPACE AND START FROM SCRATCH

clean () {
	rm -rf \
		iso/*       \
		rootfs/*    \
		build/*     \
		initramfs/*
}


# - - - DOWNLOAD THE NECESSARY SOURCE FILES.

get_source () {

	# $1: Download URL.

	wget --no-clobber --show-progress -c -q "$1" 2> /dev/null && \
		{ say "EXTRACTING ${1//\/}"; tar -xf -C build/sources "$(basename $1)"; } || \
		{ err "ERROR DOWNLOADING $1"; }
}

# - - - LETS DO SOME MAGIC

source config


# - - - CREATE THE DIRECTORY LAYOUT.

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


# - - - BUILD THE KERNEL

if [[ ! -f build/kernel/arch/x86/boot/bzImage ]]; then
	get_source $kernel_url
fi

if [[ -f build/configs/kernel.config -a "$use_old_kernel_config" == "yes" ]]; then
	cp build/configs/kernel.config build/sources/kernel/.config
	yes "" | make -C build/kernel/ oldconfig bzImage
else
	make -C build/kernel defconfig menuconfig bzImage
fi

cp build/kernel/arch/x86/boot/bzImage iso/boot/vmlinuz


# - - - INSTALL SYSLINUX

if [[ ! -d build/sources/syslinux* ]];then
	get_source $syslinux_url
fi

cp build/sources/syslinux-*/bios/mbr/isohdpfx.bin \
		build/sources/syslinux-*/bios/core/isolinux.bin \
		build/sources/syslinux-*/bios/com32/elflink/ldlinux/ldlinux.c32 \
		iso/bootisolinux/

printf "default /boot/vmlinuz initrd=/boot/initramfs.gz" > iso/boot/isolinux/isolinux.cfg


# - - - CREATE THE INITRAMFS FILE.

chmod +x initramfs/init
find initramfs | cpio -R root:root -H newc -o | gzip > iso/boot/initramfs.gz


# - - - CREATE A SQUASH FILESYSTEM WITH THE CONTENT OF `rootfs/`

mksquashfs rootfs/ iso/rootfs.sfs -noappend -no-progress -comp xz


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
