#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }

add_keys () { apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $@; }
autoremove () { apt -yy autoremove $@; }
clean_all () { apt clean && apt autoclean; }
dpkg_force_remove () { /usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path $@; }
fix_install () { apt -yy --fix-broken install $@; }
hold () { apt-mark hold $@; }
install () { apt -yy install --no-install-recommends $@; }
install_downgrades () { apt -yy install --no-install-recommends --allow-downgrades $@; }
install_downgrades_hold () { apt -yy install --no-install-recommends --allow-downgrades --allow-change-held-packages $@; }
only_upgrade () { apt -yy install --no-install-recommends --only-upgrade $@; }
purge () { apt -yy purge --remove $@; }
unhold () { apt-mark unhold $@; }
update () { apt -qq update; }
upgrade_downgrades () { apt -yy upgrade --allow-downgrades $@; }


puts "STARTING BOOTSTRAP."


#	Install basic packages.
#	PRE_BUILD_PKGS are packages that for one reason or the other do not get pulled when
#	the metapackages are installed, or, that require systemd to be present and can't be installed
#	from Devuan repositories, i.e., bluez, rng-tools so they have to be installed *before* installing
#	the rest of the packages, or, that we want to test by adding them but are not part of the metapackages.

puts "INSTALLING BASIC PACKAGES."

BASIC_PKGS='
	apt-transport-https
	apt-utils
	ca-certificates
	debconf
	dhcpcd5
	gnupg2
'

PRE_BUILD_PKGS='
	avahi-daemon
	bluez
	btrfs-progs
	cgroupfs-mount
	cups-daemon
	dictionaries-common
	efibootmgr
	language-pack-en
	language-pack-es
	libpam-runtime
	os-prober
	rng-tools
	squashfs-tools
	sudo
	systemd
	systemd-sysv
	ufw
	user-setup
'

update
install $BASIC_PKGS $PRE_BUILD_PKGS


#	Add key for Neon repository.
#	Add key for Nitrux repository.
#	Add key for Devuan repositories #1.
#	Add key for Devuan repositories #2.
#	Add key for Ubuntu repositories #1.
#	Add key for Ubuntu repositories #2.

puts "ADDING REPOSITORY KEYS."

 add_keys \
	55751E5D \
	1B69B2DA \
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


#	Add casper packages from bionic.

puts "INSTALLING CASPER PACKAGES."

CASPER_PKGS='
	casper
	lupin-casper
'

INITRAMFS_PKGS='
	initramfs-tools
	initramfs-tools-core
	initramfs-tools-bin
'

install -t bionic-updates $CASPER_PKGS
hold $INITRAMFS_PKGS


#	Use elogind packages from Devuan.

puts "ADDING ELOGIND."

DEVUAN_ELOGIND_PKGS='
	elogind
	libelogind0
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

ADD_SYSTEMCTL_PKG='
	systemctl
'

install_downgrades $DEVUAN_ELOGIND_PKGS
purge $REMOVE_SYSTEMD_PKGS
autoremove
install -t focal $ADD_SYSTEMCTL_PKG
fix_install
hold $ADD_SYSTEMCTL_PKG


#	Use PolicyKit packages from Devuan.

puts "ADDING POLICYKIT."

DEVUAN_POLKIT_PKGS='
	libpolkit-agent-1-0
	libpolkit-backend-1-0
	libpolkit-backend-elogind-1-0
	libpolkit-gobject-1-0
	libpolkit-gobject-elogind-1-0
'

install -t beowulf $DEVUAN_POLKIT_PKGS


#	Add NetworkManager and udisks2 from Devuan.

DEVUAN_NETWORKMANAGER_PKGS='
	init-system-helpers
	libnm0
	network-manager
'

DEVUAN_UDISKS2_PKGS='
	libudisks2-0
	udisks2
'

install $DEVUAN_NETWORKMANAGER_PKGS $DEVUAN_UDISKS2_PKGS


#	Add OpenRC as init.

puts "ADDING OPENRC AS INIT."

DEVUAN_INIT_PKGS='
	fgetty
	initscripts
	openrc
	policycoreutils
	startpar
	sysvinit-utils
'

install_downgrades $DEVUAN_INIT_PKGS


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."

NITRUX_BASE_PKGS='
	base-files=12.1.1+nitrux
	nitrux-hardware-drivers-minimal
	nitrux-minimal
	nitrux-standard
	linux-image-mainline-vfio
'

NVIDIA_DRV_PKGS='
	nvidia-x11-config
	screen-resolution-extra
'

install $NITRUX_BASE_PKGS $NVIDIA_DRV_PKGS


#	Install NX Desktop metapackage.
#	NOTE: The plymouth packages have to be downgraded to the version in xenial-updates
#	because otherwise the splash is not shown.

puts "INSTALLING DESKTOP PACKAGES."

LIBPNG12_PKG='
	
'

PLYMOUTH_XENIAL_PKGS='
	
'

DEVUAN_PULSE_PKGS='
	libpulse-mainloop-glib0=14.2-2
	libpulse0=14.2-2
	libpulsedsp=14.2-2
	pulseaudio-module-bluetooth=14.2-2
	pulseaudio-utils=14.2-2
	pulseaudio=14.2-2
'

MISC_KDE_PKGS='
	sddm
'

NX_DESKTOP_PKG='
	nx-desktop-minimal
'

MISC_DESKTOP_PKGS='
	i3
	i3status
	xterm/ceres
	dmz-cursor-theme
'

HOLD_MISC_PKGS='
	cgroupfs-mount
	ssl-cert
'


#	Disallow dpkg to exclude translations affecting Plasma (see issues https://github.com/Nitrux/iso-tool/issues/48 and 
#	https://github.com/Nitrux/nitrux-bug-tracker/issues/4)

sed -i 's+path-exclude=/usr/share/locale/+#path-exclude=/usr/share/locale/+g' /etc/dpkg/dpkg.cfg.d/excludes


install_downgrades $LIBPNG12_PKG $PLYMOUTH_XENIAL_PKGS $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG $MISC_DESKTOP_PKGS
hold $HOLD_MISC_PKGS


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.hirsute /etc/apt/sources.list.d/ubuntu-hirsute-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPGRADE_MISC_PKGS='
	linux-firmware
'

UPDATE_GLIBC_PKGS='
	libc6
	libc-bin
	locales
'

DOWNGRADE_MISC_PKGS='
	bluez/ceres
'

INSTALL_MISC_PKGS='
	patchelf
'

update
only_upgrade $UPGRADE_MISC_PKGS $UPDATE_GLIBC_PKGS
install_downgrades_hold $DOWNGRADE_MISC_PKGS
install $INSTALL_MISC_PKGS


#	Add OpenRC configuration.

puts "ADDING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

install $OPENRC_CONFIG


#	Add live user.

puts "ADDING LIVE USER."

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

rm -r /home/travis || true


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


#	Use LZ4 compression when creating the initramfs.
#	Add persistence script.
#	Add fstab mount binds.

puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/scripts/mounts >> /usr/share/initramfs-tools/scripts/casper-bottom/12fstab

update-initramfs -u


#	Remove APT.

puts "REMOVING APT."

REMOVE_APT_PKGS='
	apt
	apt-utils
	apt-transport-https
'

dpkg_force_remove $REMOVE_APT_PKGS


#	Clean the filesystem.

puts "REMOVING CASPER."

dpkg_force_remove $CASPER_PKGS


#	WARNING:
#	No dpkg usage past this point.


#	Use script to remove dpkg.

puts "REMOVING DPKG."

/configs/scripts/rm-dpkg.sh


#	Check contents of /boot.
#	Check contents of OpenRC runlevels.
#	Check that init system is not systemd.
#	Check if VFIO module is included in the initramfs.
#	Check existence and contents of casper.conf
#	Check the setuid and groups of /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#	Check contents of /Applications
#	Check contents of sddm.conf
#	Check existence of sddm.conf.d

ls -l /boot
ls -l /vmlinuz /initrd.img
ls -l /etc/init.d/ \
	/etc/runlevels/default/ \
	/etc/runlevels/nonetwork/ \
	/etc/runlevels/off \
	/etc/runlevels/recovery/ \
	/etc/runlevels/sysinit/stat /sbin/init
cat /etc/casper.conf
lsinitramfs -l /boot/initrd.img* | grep vfio
ls -l /usr/lib/dbus-1.0/dbus-daemon-launch-helper
ls -l /Applications
cat /etc/sddm.conf
file -d /etc/sddm.conf.d

puts "EXITING BOOTSTRAP."
