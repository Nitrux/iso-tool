#!/bin/sh
set -e

# shellcheck source=/dev/null
. /usr/share/initramfs-tools/hook-functions

# Copy the script to /usr/sbin/ in the initramfs
copy_exec /usr/bin/vfio-override /usr/bin/
