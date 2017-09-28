# - - - DEFINE SOME DEFAULTS...

prefix     = $(pwd)
sources    = $(prefix)/sources
build      = $(prefix)/build

iso_name   = "NXOS.iso"
iso_label  = "NXOS-BETA"

linux      = "$(uname -r | grep -Eo '[0-9]\.[0-9]*\.[0-9]*')"
busybox    = "$(busybox | grep -Eo '[0-9]\.[0-9]*\.[0-9]*')"
syslinux   = "$(syslinux -v 2>&1 | grep -Eo '[0-9]\.[0-9]*')"

wget_flags = "--quiet --show-progress --no-clobber"


# - - - CREATE THE DIRECTORIES LAYOUT.

dir_layout:
	mkdir -p \
		sources                   \
		output                    \
		iso                       \
		iso/boot                  \
		iso/boot/isolinux         \
		iso/system                \
		initramfs                 \
		initramfs/rootfs          \
		initramfs/rootfs/dev      \
		initramfs/rootfs/sys      \
		initramfs/rootfs/bin      \
		initramfs/rootfs/sbin     \
		initramfs/rootfs/proc     \
		initramfs/rootfs/usr      \
		initramfs/rootfs/usr/bin  \
		initramfs/rootfs/usr/sbin \

	ln -s iso/system rootfs/



# - - - DOWNLOAD THE NECESSARY SOURCE FILES.

get_sources:
	cd $(prefix)/sources

	wget $(wget_flags) http://kernel.org/pub/linux/kernel/v4.x/linux-$(linux).tar.xz
	tar -xf linux-*.tar.xz

	wget $(wget_flags) http://busybox.net/downloads/busybox-$(busybox).tar.bz2
	tar -xf busybox-*.tar.bz2

	wget $(wget_flags) http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-$(syslinux).tar.xz
	tar -xf syslinux-*.tar.xz



# - - - BUILD THE KERNEL

build_kernel:
	cd $(sources)/linux-$(linux)
	make mrproper defconfig menuconfig bzImage
	cp arch/x86/boot/bzImage "$working_dir"/iso/boot/vmlinuz



# - - - BUILD BUSYBOX

build_busybox:
	cd $(sources)/busybox-$(busybox)
    make distclean defconfig
    sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
    make busybox install
    cd _install
    rm -f linuxrc



# - - - PHONIES. =P

.PHONY: build_iso
.PHONY: build_initramfs
.PHONY: build_busybox
.PHONY: build_kernel
.PHONY: build_layout
.PHONY: syslinux
.PHONY: get_sources
.PHONY: clean

.DEFAULT_GOAL := iso
