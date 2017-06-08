#! /bin/bash

set -e -u

export LANG=C
export LC_ALL=C

app_name=${0##*/}
pacman_conf="/etc/pacman.conf"
export iso_label="NXOS"
img_name="nxos.iso"
publisher="Luis Lavaire <https://www.github.com/luis-lavaire>"
application="nxos live"
comp="xz"
gpg_key=

# - - - MESSAGES

_fail() { echo -e "\n - - \033[38;5;1m $@ \n"; }

_echo() { echo -e "\n - - \033[38;5;5m $@ \n"; }

# - - - FILESYSTEM CLEANUP

_cleanup() {
	_echo " - - - Cleanup..."

	if [[ -d "rootfs/boot" ]]; then
		find "rootfs/boot" -type f -name '*.img' -delete
	fi
	if [[ -d "rootfs/boot" ]]; then
		find "rootfs/boot" -type f -name 'vmlinuz*' -delete
	fi
	if [[ -d "rootfs/var/lib/pacman" ]]; then
		find "rootfs/var/lib/pacman" -maxdepth 1 -type f -delete
	fi
	if [[ -d "rootfs/var/lib/pacman/sync" ]]; then
		find "rootfs/var/lib/pacman/sync" -delete
	fi
	if [[ -d "rootfs/var/cache/pacman/pkg" ]]; then
		find "rootfs/var/cache/pacman/pkg" -type f -delete
	fi
	if [[ -d "rootfs/var/log" ]]; then
		find "rootfs/var/log" -type f -delete
	fi
	if [[ -d "rootfs/var/tmp" ]]; then
		find "rootfs/var/tmp" -mindepth 1 -delete
	fi
	find "rootfs/" \( -name "*.pacnew" -o -name "*.pacsave" -o -name "*.pacorig" \) -delete
	_echo "Done!"
}

# - - - CREATE AN ISO IMAGE

_mkiso() {
	_echo "Creating ISO image..."
	xorriso -as mkisofs \
		-iso-level 3 \
		-full-iso9660-filenames \
		-volid "${iso_label}" \
		-appid "${application}" \
		-publisher "${publisher}" \
		-preparer "" \
		-eltorito-boot isolinux/isolinux.bin \
		-eltorito-catalog isolinux/boot.cat \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		-isohybrid-mbr ${work_dir}/iso/isolinux/isohdpfx.bin \
		-output "${img_name}" \
		"rootfs/"
	_echo "Done! | $(ls -sh ${img_name})"
}

# - - - CREATE AN SQUASHFS IMAGE

_mksfs() {
	_echo " - - - Creating SquashFS..."
	[[ mksquashfs "./rootfs" "iso/rootfs.sfs" -noappend -comp "$comp" ]] && {
		_echo "Done!"
		_mkiso
	} || {
		_fail "Failed!"
	}
}

# - - - MAIN

for cmd in "$@"; do
	case "$cmd" in 
		clean)	_cleanup;;
		pack)	_mksfs;;
	esac
done
