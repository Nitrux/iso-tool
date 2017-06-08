#! /bin/bash

set -e -u

export LANG=C
export LC_ALL=C

app_name=${0##*/}
pacman_conf="/etc/pacman.conf"
export iso_label="NXOS"
img_name="nxos.iso"
publisher="Luis Lavaire <https://www.github.com/luis-lavaire>"
application="nxos installer"
comp="xz"
gpg_key=

# - - - MESSAGES

_mf() {
	echo -e "\033[38;5;1m $@ \n"
}

_ms() {
	echo -e "\033[38;5;5m $@ \n"
}

_mn() {
	echo -e "\033[38;5;1m $0"
}

# - - - FILESYSTEM CLEANUP

_cleanup() {
	_mn " - - - Cleanup..."

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
	_msg_info "Done!"
}

# - - - CREATE AN ISO IMAGE

_mkiso() {
	_mn "Creating ISO image..."
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
	_ms "Done! | $(ls -sh ${img_name})"
}

# - - - CREATE AN SQUASHFS IMAGE

_mksfs() {
	_mn " - - - Creating SquashFS..."
	[[ mksquashfs "./rootfs" "iso/rootfs.sfs" -noappend -comp "$comp" -no-progress ]] && {
		_ms "Done!"
		_mkiso
	} || {
		_mf "Failed!"
	}
}

# - - - MAIN

for cmd in "$@"; do
	case "$cmd" in 
		clean)	_cleanup;;
		pack)	_mksfs;;
	esac
done
