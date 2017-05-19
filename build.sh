#!/bin/bash

set -e -u

iso_name=nxos
iso_label="nxos"
iso_version=1
install_dir=nxos
arch=$(uname -m)
work_dir=work
out_dir=out

script_path=$(readlink -f ${0%/*})

# Base installation (nxos)
make_basefs() {
	mkarchiso -v -w "${work_dir}" -D "${install_dir}" init
}

# Copy mkinitcpio archiso hooks and build initramfs (nxos)
make_setup_mkinitcpio() {
	mkdir -p ${work_dir}/etc/initcpio/hooks
	mkdir -p ${work_dir}/etc/initcpio/install
	cp /usr/lib/initcpio/hooks/archiso ${work_dir}/etc/initcpio/hooks
	cp /usr/lib/initcpio/install/archiso ${work_dir}/etc/initcpio/install
	cp ${script_path}/mkinitcpio.conf ${work_dir}/etc/mkinitcpio-archiso.conf
	mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/nxos.img' run
}

# Prepare ${install_dir}/boot/
make_boot() {
	mkdir -p ${work_dir}/iso/${install_dir}/boot
	cp ${work_dir}/boot/nxos.img ${work_dir}/iso/${install_dir}/boot/nxos.img
	cp ${work_dir}/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/vmlinuz
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
	mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
	sed "s|%ARCHISO_LABEL%|${iso_label}|g;
		 s|%INSTALL_DIR%|${install_dir}|g;
		 s|%ARCH%|${arch}|g" ${script_path}/syslinux/syslinux.cfg > ${work_dir}/iso/boot/syslinux/syslinux.cfg
	cp ${work_dir}/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/boot/syslinux/
	cp ${work_dir}/usr/lib/syslinux/bios/menu.c32 ${work_dir}/iso/boot/syslinux/
	cp ${work_dir}/usr/lib/syslinux/bios/libutil.c32 ${work_dir}/iso/boot/syslinux/
}

# Prepare /isolinux
make_isolinux() {
	mkdir -p ${work_dir}/iso/isolinux
	sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
	cp ${work_dir}/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
	cp ${work_dir}/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
	cp ${work_dir}/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/
}

# Build nxos filesystem image
make_prepare() {
	mkarchiso -v -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
	mkarchiso -v -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}.iso"
}

make_basefs
#make_setup_mkinitcpio
#make_boot
#make_syslinux
#make_isolinux
#make_prepare
#make_iso
