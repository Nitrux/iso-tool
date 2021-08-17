#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }

add_nitrux_key () { curl -L https://packagecloud.io/nitrux/repo/gpgkey | apt-key add -; }
add_repo_keys () { apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $@; }
autoremove () { apt -yy autoremove $@; }
clean_all () { apt clean && apt autoclean; }
dpkg_force_remove () { /usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path $@; }
fix_install () { apt -yy --fix-broken install $@; }
hold () { apt-mark hold $@; }
install () { apt -yy install --no-install-recommends $@; }
install_downgrades () { apt -yy install --no-install-recommends --allow-downgrades $@; }
install_downgrades_hold () { apt -yy install --no-install-recommends --allow-downgrades --allow-change-held-packages $@; }
install_hold () { apt -yy install --no-install-recommends $@ && apt-mark hold $@; }
only_upgrade () { apt -yy install --no-install-recommends --only-upgrade $@; }
purge () { apt -yy purge --remove $@; }
remove_dpkg () { /usr/bin/rm-dpkg; }
unhold () { apt-mark unhold $@; }
update () { apt update; }
update_quiet () { apt -qq update; }
upgrade_downgrades () { apt -yy upgrade --allow-downgrades $@; }


puts "STARTING BOOTSTRAP."


#	Install basic packages.
#	
#	Install extra packages.
#
#	SYSTEMD_RDEP_PKGS are packages that for one reason or the other do not get pulled when
#	the metapackages are installed, or, that require systemd to be present and can't be installed
#	from Devuan repositories, i.e., bluez, rng-tools so they have to be installed *before* installing
#	the rest of the packages.

puts "INSTALLING BASIC PACKAGES."

BASIC_PKGS='
	apt-transport-https
	apt-utils
	ca-certificates
	dhcpcd5
	gnupg2
'

EXTRA_PKGS='
	avahi-daemon
	cups-daemon
	curl
	dictionaries-common
	efibootmgr
	language-pack-en
	language-pack-es
	language-pack-de
	language-pack-pt
	language-pack-fr
	os-prober
	squashfs-tools
	sudo
	xz-utils
'

SYSTEMD_RDEP_PKGS='
	bluez
	btrfs-progs
	rng-tools
	systemd
	systemd-sysv
	ufw
	user-setup
'

update
install $BASIC_PKGS $EXTRA_PKGS $SYSTEMD_RDEP_PKGS


#	Hold misc. packages.

puts "HOLD MISC. PACKAGES."

HOLD_MISC_PKGS='
	cgroupfs-mount
	ssl-cert
'

hold $HOLD_MISC_PKGS


#	Add key for Nitrux repository.
#	Add key for Neon repository.
#	Add key for Devuan repositories #1.
#	Add key for Devuan repositories #2.
#	Add key for Ubuntu repositories #1.
#	Add key for Ubuntu repositories #2.

puts "INSTALLING REPOSITORY KEYS."

add_nitrux_key

add_repo_keys \
	55751E5D \
	541922FB \
	BB23C00C61FC752C \
	3B4FE6ACC0B21F32 \
	871920D1991BC93C > /dev/null


#	Copy sources.list files.

puts "ADDING SOURCES FILES."

cp /configs/files/sources.list.nitrux /etc/apt/sources.list
cp /configs/files/sources.list.devuan.beowulf /etc/apt/sources.list.d/devuan-beowulf-repo.list
cp /configs/files/sources.list.devuan.ceres /etc/apt/sources.list.d/devuan-ceres-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list
cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp /configs/files/sources.list.xenial /etc/apt/sources.list.d/ubuntu-xenial-repo.list

update


#	Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


#	Add script to remove dpkg.

cp /configs/scripts/rm-dpkg.sh /usr/bin/rm-dpkg


#	Add casper packages from bionic.

puts "INSTALLING CASPER PACKAGES."

CASPER_PKGS='
	casper/bionic-updates
	lupin-casper/bionic
'

install $CASPER_PKGS


#	Hold initramfs packages.

INITRAMFS_PKGS='
	initramfs-tools
	initramfs-tools-core
	initramfs-tools-bin
'

hold $INITRAMFS_PKGS


#	Add elogind packages from Devuan.

puts "INSTALLING ELOGIND."

DEVUAN_ELOGIND_PKGS='
	elogind
	libelogind0
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
	libargon2-1
	libcryptsetup12
'

SYSTEMCTL_PKG='
	systemctl/focal
'

install $DEVUAN_ELOGIND_PKGS
purge $REMOVE_SYSTEMD_PKGS
install_hold $SYSTEMCTL_PKG


#	Use PolicyKit packages from Devuan.
#	Add NetworkManager and udisks2 from Devuan.
#	Add OpenRC as init.

puts "INSTALLING POLICYKIT."

DEVUAN_SYS_PKGS='
	init-system-helpers
	initscripts
	libnm0
	libpolkit-agent-1-0/beowulf
	libpolkit-backend-1-0/beowulf
	libpolkit-backend-elogind-1-0/beowulf
	libpolkit-gobject-1-0/beowulf
	libpolkit-gobject-elogind-1-0/beowulf
	libudisks2-0
	network-manager
	openrc
	policycoreutils
	policykit-1/beowulf
	startpar
	sysvinit-utils
	udisks2
'

install $DEVUAN_SYS_PKGS


#	Install base system metapackages.

puts "INSTALLING BASE FILES AND KERNEL."

NITRUX_BASE_KERNEL_DRV_PKGS='
	base-files=12.1.4+nitrux
	nitrux-hardware-drivers-minimal
	linux-image-mainline-vfio
'

install $NITRUX_BASE_KERNEL_DRV_PKGS 


#	Install NX Desktop metapackage.
#	NOTE: The plymouth packages have to be downgraded to the version in xenial-updates
#	because otherwise the splash is not shown.
#	
#	Disallow dpkg to exclude translations affecting Plasma (see issues https://github.com/Nitrux/iso-tool/issues/48 and 
#	https://github.com/Nitrux/nitrux-bug-tracker/issues/4).

puts "INSTALLING DESKTOP PACKAGES."

sed -i 's+path-exclude=/usr/share/locale/+#path-exclude=/usr/share/locale/+g' /etc/dpkg/dpkg.cfg.d/excludes

NX_DESKTOP_PKG='
	nx-desktop-minimal
'

MISC_KDE_PKGS='
	sddm
'

MISC_DESKTOP_PKGS='
	dmz-cursor-theme
	i3
	i3status
	xterm/ceres
'

install $NX_DESKTOP_PKG $MISC_KDE_PKGS $MISC_DESKTOP_PKGS


#	Install Nvidia driver.

NVIDIA_DRV_PKGS='
	libxnvctrl0
	nvidia-x11-config
	screen-resolution-extra
'

install $NVIDIA_DRV_PKGS


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.impish /etc/apt/sources.list.d/ubuntu-impish-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPGRADE_MISC_PKGS='
	linux-firmware
	bluez/ceres
	sudo/ceres
'

UPDATE_GLIBC_PKGS='
	libc6
	libc-bin
	locales
'

INSTALL_MISC_PKGS='
	patchelf
'

update
only_upgrade $UPGRADE_MISC_PKGS $UPDATE_GLIBC_PKGS
install $INSTALL_MISC_PKGS


#	Add OpenRC configuration.

puts "INSTALLING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

install $OPENRC_CONFIG


#	Add live user.

puts "INSTALLING LIVE USER."

NX_LIVE_USER_PKG='
	nitrux-live-user
'

install $NX_LIVE_USER_PKG
autoremove
clean_all


#	WARNING:
#	No apt usage past this point.


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

cat /configs/files/casper.conf > /etc/casper.conf

ln -sv /usr/share/xsessions/i3.desktop /usr/share/xsessions/plasma.desktop 

rm \
	/{vmlinuz,initrd.img,vmlinuz.old,initrd.img.old} || true


#	Implement a new FHS.
#	FIXME: Replace with kernel patch and userland tool.

puts "CREATING NEW FHS."

mkdir -p \
	/Devices \
	/System/Binaries \
	/System/Binaries/Optional \
	/System/Configuration \
	/System/Libraries \
	/System/Mount/Filesystems \
	/System/Resources/Shared \
	/System/Server/Services \
	/System/Variable \
	/Users/

cp /configs/files/hidden /.hidden


#	Add persistence script.
#	Add fstab mount binds.

puts "UPDATING THE INITRAMFS."

cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/scripts/mounts >> /usr/share/initramfs-tools/scripts/casper-bottom/12fstab

update-initramfs -u


#	Remove Dash.
#	Remove APT.

puts "REMOVING DASH, CASPER AND APT."

REMOVE_DASH_CASPER_APT_PKGS='
	apt
	apt-transport-https
	apt-utils
	casper
	dash
	lupin-casper
'

dpkg_force_remove $REMOVE_DASH_CASPER_APT_PKGS || true

ln -svf /bin/mksh /bin/sh

dpkg_force_remove $REMOVE_DASH_CASPER_APT_PKGS


#	WARNING:
#	No dpkg usage past this point.


#	Use script to remove dpkg.

puts "REMOVING DPKG."

remove_dpkg

rm -r /usr/bin/rm-dpkg


#	Check contents of /boot.
#	Check contents of OpenRC runlevels.
#	Check links to kernel and initramdisk.
#	Check contents of init.d and sddm.conf.d.
#	Check the setuid and groups of /usr/lib/dbus-1.0/dbus-daemon-launch-helper.
#	Check contents of /Applications.
#	Check that init system is not systemd.
#	Check that /bin/sh is in fact not Dash.
#	Check existence and contents of casper.conf and sddm.conf.
#	Check that the VFIO driver is included in the intiramfs.


puts "PERFORM MANUAL CHECKS."

ls -lh \
	/boot \
	/etc/runlevels/{default,nonetwork,off,recovery,sysinit} \
	/{vmlinuz,initrd.img} \
	/etc/{init.d,sddm.conf.d} \
	/usr/lib/dbus-1.0/dbus-daemon-launch-helper \
	/Applications || true

stat \
	/sbin/init \
	/bin/sh

cat \
	/etc/{casper.conf,sddm.conf}

lsinitramfs -l /boot/initrd.img* | grep vfio


puts "EXITING BOOTSTRAP."
