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

 copy_exec /usr/bin/vfio-override /usr/bin
 copy_exec /bin/cat /bin
 copy_exec /usr/bin/dirname /usr/bin
 copy_exec /bin/echo /bin
 copy_exec /usr/bin/find /usr/bin
 copy_exec /usr/bin/lspci /usr/bin
 copy_exec /sbin/modprobe /sbin
 copy_exec /usr/bin/head /usr/bin