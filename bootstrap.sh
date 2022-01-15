#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }

#	Wrap APT commands in functions.

add_nitrux_key_repo () { curl -L https://packagecloud.io/nitrux/repo/gpgkey | apt-key add -; }
add_nitrux_key_compat () { curl -L https://packagecloud.io/nitrux/compat/gpgkey | apt-key add -; }
add_nitrux_key_testing () { curl -L https://packagecloud.io/nitrux/testing/gpgkey | apt-key add -; }
add_repo_keys () { apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $@; }
appstream_refresh_force () { appstreamcli refresh --force; }
autoremove () { apt -yy autoremove $@; }
clean_all () { apt clean && apt autoclean; }
dist_upgrade () { apt -yy dist-upgrade $@; }
download () { apt download $@; }
dpkg_force_install () { dpkg --force-all -i $@; }
dpkg_force_remove () { /usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path $@; }
dpkg_install () { dpkg -i $@; }
fix_install () { apt -yy --fix-broken install $@; }
fix_install_no_recommends () { apt -yy --fix-broken install --no-install-recommends $@; }
hold () { apt-mark hold $@; }
install () { apt -yy install --no-install-recommends $@; }
install_downgrades () { apt -yy install --no-install-recommends --allow-downgrades $@; }
install_downgrades_hold () { apt -yy install --no-install-recommends --allow-downgrades --allow-change-held-packages $@; }
list_upgrade () { apt list --upgradable; }
only_upgrade () { apt -yy install --no-install-recommends --only-upgrade $@; }
pkg_policy () { apt-cache policy $@; }
purge () { apt -yy purge --remove $@; }
remove_keys () { apt-key del $@; }
unhold () { apt-mark unhold $@; }
update () { apt update; }
update_quiet () { apt -qq update; }
upgrade () { apt -yy upgrade $@; }
upgrade_downgrades () { apt -yy upgrade --allow-downgrades $@; }


puts "STARTING BOOTSTRAP."


#	Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


#	Install basic packages.

puts "ADDING BASIC PACKAGES."

CHROOT_BASIC_PKGS='
	apt-transport-https
	apt-utils
	appstream
	ca-certificates
	curl
	dhcpcd5
	gnupg2
	initramfs-tools
	libzstd-dev
	lz4
	zstd
'

update
upgrade
install $CHROOT_BASIC_PKGS


#	Add key for Nitrux repository.

puts "ADDING REPOSITORY KEYS."

add_nitrux_key_repo
add_nitrux_key_compat
add_nitrux_key_testing


#	Copy repository sources.

puts "ADDING SOURCES FILES."

cp /configs/files/sources.list.nitrux /etc/apt/sources.list
cp /configs/files/sources.list.nitrux.testing /etc/apt/sources.list.d/nitrux-testing-repo.list
cp /configs/files/sources.list.debian.experimental /etc/apt/sources.list.d/debian-experimental-repo.list
cp /configs/files/sources.list.debian.unstable /etc/apt/sources.list.d/debian-unstable-repo.list

update


#	Upgrade dpkg for zstd support.

UPGRADE_DPKG='
	dpkg/trixie
	libc-bin=2.33-0ubuntu5
	libc6=2.33-0ubuntu5
	locales=2.33-0ubuntu5
'

install_downgrades $UPGRADE_DPKG


#	Do dist-upgrade.

dist_upgrade


#	Add bootloader.
#
#	The GRUB2 packages from Debian do not work correctly with EFI.

puts "ADDING BOOTLOADER."

GRUB2_PKGS='
	grub-common/trixie
	grub-efi-amd64/trixie
	grub-efi-amd64-bin/trixie
	grub-efi-amd64-signed/trixie
	grub-pc-bin/trixie
	grub2-common/trixie
	libfreetype6/unstable
'

install $GRUB2_PKGS


#	Add packages for secure boot compatibility.

puts "ADDING SECURE BOOT COMPAT."

SB_SHIM_PKGS='
	sbsigntool/trixie
	shim-signed/trixie
	mokutil/trixie
'

install $SB_SHIM_PKGS


#	Add eudev, elogind, and systemctl to replace systemd and utilize other inits.
#
#	To remove systemd, we have to replace libsystemd0, udev, elogind and provide systemctl. However, neither of them
#	are available to install from other sources than Devuan except for systemctl.

add_repo_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

cp /configs/files/sources.list.devuan.beowulf /etc/apt/sources.list.d/devuan-beowulf-repo.list

update

puts "ADDING EUDEV AND ELOGIND."

DEVUAN_EUDEV_ELOGIND_PKGS='
	eudev
	elogind
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

SYSTEMCTL_STANDALONE_PKG='
	systemctl
'

install $DEVUAN_EUDEV_ELOGIND_PKGS
purge $REMOVE_SYSTEMD_PKGS
autoremove
install $SYSTEMCTL_STANDALONE_PKG

rm \
	/etc/apt/sources.list.d/devuan-beowulf-repo.list

remove_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

update


#	Add OpenRC as init.

puts "ADDING OPENRC AS INIT."

OPENRC_INIT_PKGS='
	initscripts
	init-system-helpers
	openrc
	policycoreutils
	startpar
	sysvinit-utils
'

install $OPENRC_INIT_PKGS


#	Add kernel.

puts "ADDING KERNEL."

MAINLINE_KERNEL_PKG='
	linux-image-liquorix
	libcrypt-dev/trixie
	libcrypt1/trixie
'

install_downgrades $MAINLINE_KERNEL_PKG


#	Add Plymouth.
#
#	The version of Plymouth that is available from Debian requires systemd and udev.
#	To avoid this requirement, we will use the package from Devuan (daedalus) that only requires udev (eudev).

puts "ADDING PLYMOUTH."

add_repo_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

cp /configs/files/sources.list.devuan.daedalus /etc/apt/sources.list.d/devuan-daedalus-repo.list

update

DEVUAN_PLYMOUTH_PKGS='
	plymouth/daedalus
	plymouth-label/daedalus
	plymouth-x11/daedalus
'

install $DEVUAN_PLYMOUTH_PKGS

rm \
	/etc/apt/sources.list.d/devuan-daedalus-repo.list

remove_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

update


#	Add casper.
#
#	It's worth noting that casper isn't available anywhere but Ubuntu.
#	Debian doesn't use it; it uses live-boot, live-config, et. al.

puts "ADDING CASPER."

CASPER_PKGS='
	casper
	lupin-casper
'

install $CASPER_PKGS

update


#	Adding PolicyKit packages from Devuan.
#
#	Since we're using elogind to replace logind, we need to add the matching PolicyKit packages.
#
#	Strangely, the complete stack is only available in beowulf but not in chimaera or daedalus.

puts "ADDING POLICYKIT ELOGIND COMPAT."

add_repo_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

cp /configs/files/sources.list.devuan.beowulf /etc/apt/sources.list.d/devuan-beowulf-repo.list

update

DEVUAN_POLKIT_PKGS='
	libpam-elogind/beowulf
	libpolkit-agent-1-0/beowulf
	libpolkit-backend-elogind-1-0/beowulf
	libpolkit-gobject-1-0/beowulf
	libpolkit-gobject-elogind-1-0/beowulf
	policykit-1/beowulf
'

install_downgrades $DEVUAN_POLKIT_PKGS

rm \
	/etc/apt/sources.list.d/devuan-beowulf-repo.list

remove_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

update


#	Add misc. Devuan packages.
#
#	The network-manager package that is available in Debian does not have an init script compatible with OpenRC.
#	so we use the package from Devuan instead.
#
#	Prioritize installing packages from daedalus over chimaera, unless the package only exists in ceres.

puts "ADDING DEVUAN MISC. PACKAGES."

add_repo_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

cp /configs/files/sources.list.devuan.daedalus /etc/apt/sources.list.d/devuan-daedalus-repo.list

update

MISC_DEVUAN_DAEDALUS_PKGS='
	network-manager/daedalus
'

install $MISC_DEVUAN_DAEDALUS_PKGS

rm \
	/etc/apt/sources.list.d/devuan-daedalus-repo.list

remove_keys \
	541922FB \
	BB23C00C61FC752C > /dev/null

update


#	Add Nitrux meta-packages.

puts "ADDING NITRUX BASE."

NITRUX_BASE_PKGS='
	base-files=13.1.6+nitrux-legacy
	nitrux-hardware-drivers-legacy
	nitrux-minimal-legacy
	nitrux-standard-legacy
'

install $NITRUX_BASE_PKGS


#	Add Nvidia drivers or Nouveau.
#
#	The package nouveau-firmware isn't available in Debian but only in Ubuntu.
#
#	The Nvidia proprietary driver can't be installed alongside Nouveau.
#
#	To install it replace the Nouveau packages with the Nvidia counterparts.

puts "ADDING NVIDIA DRIVERS/NOUVEAU FIRMWARE."

NVIDIA_DRV_PKGS='
	xserver-xorg-video-nouveau
	nouveau-firmware
'

install $NVIDIA_DRV_PKGS


#	Add NX Desktop meta-package.
#
#	Use MISC_DESKTOP_PKGS to add packages to test. If tests are positive, add to the appropriate meta-package.
#
#	Use the KDE Neon repository to provide the latest stable release of Plasma and KF5.
#
#	Manually add index to the package list otherwise it's not installed because #APT being #APT.

add_repo_keys \
	55751E5D > /dev/null

cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list

update

puts "ADDING NX DESKTOP."

NX_DESKTOP_PKG='
	nx-desktop-legacy
	nx-desktop-wayland-legacy
'

MAUI_APPS_PKG='
	buho-git
	clip-git
	communicator-git
	index-git
	maui-apps-git
	maui-shell-git
	nota-git
	pix-git
	shelf-git
	station-git
	vvave-git
	nx-software-center-git
'

MISC_DESKTOP_PKGS='
	kde-config-updates
	libkf5dbusaddons-bin
	cpufrequtils
	linux-cpupower
	tuned
	tuned-utils
'

install_downgrades $NX_DESKTOP_PKG $MAUI_APPS_PKG $MISC_DESKTOP_PKGS

rm \
	/etc/apt/sources.list.d/neon-user-repo.list

remove_keys \
	55751E5D > /dev/null

update


#	Add Calamares.
#
#	The package from KDE Neon is compiled against libkpmcore11 (21.04) and libboost-python1.71.0 from 
#	Ubuntu which provides the virtual package libboost-python1.71.0-py38. The package from Debian doesn't 
#	offer this virtual dependency.

puts "ADDING CALAMARES INSTALLER."

add_repo_keys \
	55751E5D > /dev/null

cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list

update


CALAMARES_PKGS='
	calamares
	calamares-qml-settings-nitrux
	libboost-python1.71.0/trixie
	squashfs-tools
'

install $CALAMARES_PKGS

rm \
	/etc/apt/sources.list.d/neon-user-repo.list

remove_keys \
	55751E5D > /dev/null

update


#	Update Appstream cache.

clean_all
update
appstream_refresh_force


#	Remove sources used to build the root.

puts "REMOVE BUILD SOURCES."

rm \
	/etc/apt/preferences \
	/etc/apt/sources.list.d/*

update


#	Add repository configuration.

puts "ADDING REPOSITORY SETTINGS."

NX_REPO_PKG='
	nitrux-repositories-config
'

install $NX_REPO_PKG


#	Add OpenRC configuration.
#
#	Due to how the upstream openrc package "works," we need to put this package at the end of the build process.
#	Otherwise, we end up with an unbootable system.
#
#	See https://github.com/Nitrux/openrc-config/issues/1

puts "ADDING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

install $OPENRC_CONFIG


#	Upgrade MESA packages.

puts "UPDATING MESA."

MESA_GIT_PKGS='
	mesa-git
'

install $MESA_GIT_PKGS
upgrade


#	WARNING:
#	No apt usage past this point.


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

rm \
	/etc/default/grub \
	/etc/casper.conf

cat /configs/files/grub > /etc/default/grub
cat /configs/files/casper.conf > /etc/casper.conf

rm \
	/boot/{vmlinuz,initrd.img,vmlinuz.old,initrd.img.old} || true

dpkg_force_remove bash || true

ln -svf /bin/dash /bin/bash

dpkg_force_remove bash

chmod +x /usr/bin/startcask-x11


#	Use LZ4 compression when creating the initramfs.

puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/

update-initramfs -u


#	List installed packages.

dpkg-query -l | less > installed_pkgs.txt
dpkg-query -f '${binary:Package}\n' -W | wc -l


#	WARNING:
#	No dpkg usage past this point.


#	Check contents of /boot.
#	Check contents of OpenRC runlevels.
#	Check links to kernel and initramdisk.
#	Check contents of init.d and sddm.conf.d.
#	Check the setuid and groups of /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#	Check contents of /Applications
#	Check that init system is not systemd.
#	Check that /bin/sh is in fact not Dash.
#	Check existence and contents of casper.conf and sddm.conf
#	Check the contents of /etc/default/grub

puts "PERFORM MANUAL CHECKS."

ls -lh \
	/boot \
	/etc/runlevels/{default,nonetwork,off,recovery,sysinit} \
	/{vmlinuz,initrd.img} \
	/etc/{init.d,sddm.conf.d} \
	/usr/lib/dbus-1.0/dbus-daemon-launch-helper \
	/Applications || true

stat /sbin/init \
	/bin/sh \
	/bin/dash

cat \
	/etc/{casper.conf,sddm.conf} \
	/etc/default/grub


puts "EXITING BOOTSTRAP."

