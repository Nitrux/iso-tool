#! /bin/sh

# - - - SET SOME STUFF

r="\033[31m"
g="\033[32m"
o="\033[33m"
b="\033[34m"
m="\033[35m"
c="\033[36m"
w="\033[37m"
n="\033[0m"

iso_name="NXOS.iso"
iso_label="NXOS"

wdir="$PWD"



# - - - GRAB INFO FROM INSTALLED SYSTEM VERSIONS

linux=`uname -r | grep -Eo '[0-9]\.[0-9]*\.[0-9]*'`
#busybox=`busybox | grep -Eo '[0-9]\.[0-9]*\.[0-9]*'`
syslinux=`syslinux -v 2>&1 | grep -Eo '[0-9]\.[0-9]*'`



# - - - HELPER FUNCTIONS

out () { printf "$g \n - - - $@ - - - \n\n $n"; }
err () { printf "$r \n FATAL $@ - - - \n\n $n"; }



# - - - CREATE SOME DIRECTORIES

mkdir -p \
    sources           \
    output            \
    iso               \
    iso/boot          \
    iso/boot/isolinux \
    initramfs         \
    initramfs/rootfs



# - - - DOWNLOAD SOURCES

out "DOWNLOADING SOURCES"

cd sources

#wget --no-clobber --show-progress -q \
#    http://kernel.org/pub/linux/kernel/v4.x/linux-${linux}.tar.xz && \
#    { out "EXTRACTING KERNEL"; tar -xf linux-*.tar.xz; }

#wget --no-clobber --show-progress -q \
#    https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-x86_64 \
#    -O busybox

#wget --no-clobber --show-progress -q \
#    http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-${syslinux}.tar.xz && \
#    { out "EXTRACTING SYSLINUX"; tar -xf syslinux-*.tar.xz; }



# - - - BUILD BUSYBOX

out "BUILDING BUSYBOX"

#cd busybox-${busybox}/
#make distclean defconfig
#sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
#make busybox install



# - - - CREATE THE INITRAMFS DIRECTORY TREE

out "GENERATING THE INITRAMFS"

cd "$wdir"/initramfs/rootfs
#cd _install
#rm -f linuxrc

mkdir -p dev/    \
         proc/   \
         sys/    \
         bin/    \
         usr/

ln -s bin/ sbin/
ln -s bin/ usr/bin/
ln -s bin/ usr/sbin/

cp "$wdir"/sources/busybox bin/
chmod +x bin/busybox

/bin/busybox --install -s bin/

printf \
"#!/bin/sh

dmesg -n 0

mount -t devtmpfs none /dev
mount -t proc     none /proc
mount -t sysfs    none /sys

exec /bin/sh
" > init

chmod +x init



# - - - CREATE THE INITRAMFS

find . | cpio -R root:root -H newc -o | gzip > "$wdir"/iso/boot/initramfs.gz



# - - - BUILD THE KERNEL

out "BUILDING THE KERNEL"

cd "$wdir"/sources/linux-${linux}/
#make mrproper defconfig menuconfig bzImage
cp arch/x86/boot/bzImage "$wdir"/iso/boot/vmlinuz



# - - - INSTALL SYSLINUX

out "INSTALLING SYSLINUX"

cd "$wdir"/iso/boot

cp "$wdir"/sources/syslinux-${syslinux}/bios/mbr/isohdpfx.bin isolinux/
cp "$wdir"/sources/syslinux-${syslinux}/bios/core/isolinux.bin isolinux/
cp "$wdir"/sources/syslinux-${syslinux}/bios/com32/elflink/ldlinux/ldlinux.c32 isolinux/

printf "default /boot/vmlinuz initrd=/boot/initramfs.gz" > isolinux/isolinux.cfg



# - - - GENERATE THE ISO

out "GENERATING THE .ISO FILE"

cd "$wdir"

xorriso -as mkisofs iso/                         \
    -output output/"$iso_name"                   \
    -iso-level 3                                 \
    -no-emul-boot                                \
    -boot-load-size 4                            \
    -boot-info-table                             \
    -volid "$iso_label"                          \
    -full-iso9660-filenames                      \
    -publisher "Nitrux S.A"                      \
    -eltorito-catalog boot/isolinux/boot.cat     \
    -eltorito-boot boot/isolinux/isolinux.bin    \
    -isohybrid-mbr iso/boot/isolinux/isohdpfx.bin

# - - - DONE

out "DONE..!"
