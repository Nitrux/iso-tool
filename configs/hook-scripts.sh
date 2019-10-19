#!/bin/sh
PREREQ=""
prereqs()
{
        echo "$PREREQ"
}

 case $1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

 . /usr/share/initramfs-tools/hook-functions
# Begin real processing below this line

 copy_exec /bin/dummy.sh /bin/vfio-pci-override-vga.sh
 copy_exec /bin/lsblk /bin/lsblk
