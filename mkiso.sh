#! /bin/sh

# - - - MESSAGE FORMATTING FUNCTIONS.

say () { printf "\n\n\e[32m  # # # $@ \e[0m\n\n"; }
err () { printf "\n\n\e[31m  # # # $@ \e[0m\n\n"; }


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
	say "DOWNLOADING ${1##*/}..."
	wget --no-clobber -c -q --show-progress "$1" -O "build/sources/${1##*/}" && {
		say "EXTRACTING ${1##*/}"
		tar -C build/sources -xf "build/sources/${1##*/}"
	}
}

# - - - LETS DO SOME MAGIC.

source config || { say "CAN'T CONTINUE. NO CONFIG FILE FOUND"; exit; }


# - - - CREATE THE DIRECTORY LAYOUT.

[[ "$(tr [:upper:] [:lower:] <<< $1)" == "clean" ]] && clean

mkdir -p \
	rootfs             \
	build/sources      \
	build/configs      \
	iso/boot/efi/boot  \
	iso/boot/isolinux  \
	initramfs/dev      \
	initramfs/sys      \
	initramfs/bin      \
	initramfs/sbin     \
	initramfs/proc     \
	initramfs/usr/bin  \
	initramfs/usr/sbin


# - - - BUILD THE KERNEL IF IT'S NEEDED.

linux=${kernel_url##*/}

if [[ ! -f build/sources/${linux//.tar*}/arch/x86/boot/bzImage ]]; then
	get_source $kernel_url

	if [[ -f build/configs/kernel.config && "$use_old_kernel_config" == "yes" ]]; then
		cp build/configs/kernel.config build/sources/${linux//.tar*}/.config
		yes "" | make -C build/sources/${linux//.tar*}/ oldconfig bzImage
	else
		make -C build/sources/${linux//.tar*} defconfig menuconfig bzImage
		cp build/sources/${linux//.tar*}/.config build/configs/kernel.config
	fi
fi

cp build/sources/${linux//.tar*}/arch/x86/boot/bzImage iso/boot/vmlinuz


# - - - INSTALL SYSLINUX.

syslinux=${syslinux_url##*/}

if [[ ! -d build/sources/${syslinux//.tar*} ]];then
	get_source $syslinux_url
fi

cp build/sources/${syslinux//.tar*}/bios/mbr/isohdpfx.bin \
		build/sources/${syslinux//.tar*}/bios/core/isolinux.bin \
		build/sources/${syslinux//.tar*}/bios/com32/elflink/ldlinux/ldlinux.c32 \
		iso/boot/isolinux/

printf "default /boot/vmlinuz initrd=/boot/initramfs.gz" > iso/boot/isolinux/isolinux.cfg

mkdir iso/boot/isolinux/efi/boot

cat << EOF > iso/boot/isolinux/efi/boot/startup.nsh
echo -off
echo NXOS is starting...
\\vmlinuz initrd=\\initramfs.gz
EOF

# - - - CREATE THE INITRAMFS FILE.

chmod +x initramfs/init
cd initramfs
find . | cpio -R root:root -H newc -o | gzip > iso/boot/initramfs.gz
cd ..

# - - - CREATE A SQUASH FILESYSTEM WITH THE CONTENT OF `rootfs/`.

if [[ ! -f iso/rootfs.sfs ]]; then
	sudo mksquashfs rootfs/ iso/rootfs.sfs -noappend -no-progress -comp xz
fi


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

say 'WE ARE DONE, DUDE. YOUR LINUX WAS SAVED AS `os.iso`'
