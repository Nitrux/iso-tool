#! /bin/sh

r="\033[31m"
g="\033[32m"
n="\033[0m"

working_dir="$PWD"

# - - - MESSAGE DISPLAYING FUNCTIONS.

out () { printf "$g \n - - - $@ - - - \n\n $n"; }
err () { printf "$r \n FATAL $@ - - - \n\n $n"; }



# - - - CREATE THE DIRECTORY LAYOUT.

make_layout () {
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
    
    ln -s iso/system filesystem/
}



# - - - DOWNLOAD THE NECESSARY SOURCE FILES.

get_sources () {
    cd sources
    
    wget --no-clobber --show-progress -q \
        http://kernel.org/pub/linux/kernel/v4.x/linux-${linux}.tar.xz && \
        { out "EXTRACTING KERNEL"; tar -xf linux-*.tar.xz; }
    
    wget --no-clobber --show-progress -q \
        https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-x86_64 \
        -O busybox
    
    wget --no-clobber --show-progress -q \
        http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-${syslinux}.tar.xz && \
        { out "EXTRACTING SYSLINUX"; tar -xf syslinux-*.tar.xz; }
}



# - - - BUILD THE KERNEL

make_kernel () {
    cd "$working_dir"/sources/linux-${linux}/
    #make mrproper defconfig menuconfig bzImage
    cp arch/x86/boot/bzImage "$working_dir"/iso/boot/vmlinuz
}



# - - - BUILD BUSYBOX.

make_busybox () {
    cd busybox-${busybox}/
    make distclean defconfig
    sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
    make busybox install
}



# - - - INSTALL SYSLINUX

make_syslinux () {
    cd "$working_dir"/iso/boot

    cp "$working_dir"/sources/syslinux-${syslinux}/bios/mbr/isohdpfx.bin isolinux/
    cp "$working_dir"/sources/syslinux-${syslinux}/bios/core/isolinux.bin isolinux/
    cp "$working_dir"/sources/syslinux-${syslinux}/bios/com32/elflink/ldlinux/ldlinux.c32 isolinux/

    printf "default /boot/vmlinuz initrd=/boot/initramfs.gz" > isolinux/isolinux.cfg
}



# - - - CREATE THE INITRAMFS FILE.

make_initramfs () {
    cd "$wdir"/initramfs/rootfs
    cp "$wdir"/sources/busybox usr/bin/busybox
    chmod +x usr/bin/busybox
    cp "$wdir"/initramfs/init .
    chmod +x init

    find . | cpio -R root:root -H newc -o | gzip > "$working_dir"/iso/boot/initramfs.gz
}



# - - - CREATE THE ISO FILE.

make_iso () {
    cd "$working_dir"
    
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
}
