#!/bin/sh

PREREQ=""
prereqs () { echo "$PREREQ"; }

case $1 in
prereqs)
     prereqs
     exit 0
     ;;
esac

. /usr/share/initramfs-tools/hook-functions
# Begin real processing below this line

copy_file script /configs/vfio-pci-override-vga.sh