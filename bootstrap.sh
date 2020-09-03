#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }

update () { apt -qq update; }
install () { apt -yy install --no-install-recommends $@; }

# remove () { apt -yy purge --remove; }
# autoremove () { apt -yy autoremove; }
# hold () { apt-mark hold; }

puts "STARTING BOOTSTRAP."


#	Install basic packages.
#	PREBUILD_PACKAGES are packages that for one reason or the other do not get pulled when
#	the metapackages are installed, or, that require systemd to be present and can't be installed
#	from Devuan repositories, i.e., bluez, rng-tools so they have to be installed *before* installing
#	the rest of the packages.

puts "INSTALLING BASIC PACKAGES."

BASIC_PACKAGES='
	apt-transport-https
	apt-utils
	ca-certificates
	dhcpcd5
	gnupg2
'

PREBUILD_PACKAGES='
	avahi-daemon
	bluez
	btrfs-progs
	cgroupfs-mount
	dictionaries-common
	efibootmgr
	grub-common
	grub-efi-amd64
	grub-efi-amd64-bin
	grub-efi-amd64-signed
	grub-pc-bin
	grub2-common
	language-pack-en
	language-pack-en-base
	libarchive13
	libpam-runtime
	linux-base
	localechooser-data
	locales
	locales-all
	rng-tools
	shim-signed
	squashfs-tools
	sudo
	systemd
	systemd-sysv
	ufw
	user-setup
	wget
	xz-utils
'

update
install $BASIC_PACKAGES $PREBUILD_PACKAGES


#	Add key for Neon repository.
#	Add key for Nitrux repository.
#	Add key for Devuan repositories #1.
#	Add key for Devuan repositories #2.
#	Add key for the Proprietary Graphics Drivers PPA.
#	Add key for Ubuntu repositories #1.
#	Add key for Ubuntu repositories #2.
#	Add key for Kubuntu Backports PPA.

puts "ADDING REPOSITORY KEYS."

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
	55751E5D \
	1B69B2DA \
	541922FB \
	BB23C00C61FC752C \
	1118213C \
	3B4FE6ACC0B21F32 \
	871920D1991BC93C \
	2836CB0A8AC93F7A > /dev/null


#	Copy sources.list files.

puts "ADDING SOURCES FILES."

cp /configs/files/sources.list.nitrux /etc/apt/sources.list
cp /configs/files/sources.list.devuan.beowulf /etc/apt/sources.list.d/devuan-beowulf-repo.list
cp /configs/files/sources.list.devuan.ceres /etc/apt/sources.list.d/devuan-ceres-repo.list
# cp /configs/files/sources.list.devuan.chimaera /etc/apt/sources.list.d/devuan-chimaera-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list
cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp /configs/files/sources.list.xenial /etc/apt/sources.list.d/ubuntu-xenial-repo.list
# cp /configs/files/sources.list.backports /etc/apt/sources.list.d/backports-ppa-repo.list

apt -qq update


#	Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


#	Add casper packages.

puts "INSTALLING CASPER PACKAGES."

CASPER_PACKAGES='
	casper
	lupin-casper
'

INITRAMFS_PACKAGES='
	initramfs-tools
	initramfs-tools-core
	initramfs-tools-bin
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install -t bionic $CASPER_PACKAGES --no-install-recommends
apt-mark hold $INITRAMFS_PACKAGES


#	Use elogind packages from Devuan.

puts "ADDING ELOGIND."

ELOGIND_PKGS='
	elogind
	libelogind0
	libprocps7
'

UPDT_APT_PKGS='
	apt-transport-https
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

ADD_SYSTEMCTL_PKG='
	systemctl
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $ELOGIND_PKGS $UPDT_APT_PKGS --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy purge --remove $REMOVE_SYSTEMD_PKGS
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt -qq -o=Dpkg::Use-Pty=0 -yy install -t focal $ADD_SYSTEMCTL_PKG --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install

apt-mark hold $ADD_SYSTEMCTL_PKG


#	Use PolicyKit packages from Devuan.

puts "ADDING POLICYKIT."

DEVUAN_NM_UD2='
	init-system-helpers
	libnm0
	libudisks2-0
	network-manager
	udisks2
'


DEVUAN_POLKIT_PKGS='
	libpolkit-agent-1-0=0.105-25+devuan8
	libpolkit-backend-1-0=0.105-25+devuan8
	libpolkit-backend-elogind-1-0=0.105-25+devuan8
	libpolkit-gobject-1-0=0.105-25+devuan8
	libpolkit-gobject-elogind-1-0=0.105-25+devuan8
	libpolkit-qt5-1-1=0.113.0-1
	policykit-1=0.105-25+devuan8
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $DEVUAN_NM_UD2 $DEVUAN_POLKIT_PKGS --no-install-recommends --allow-downgrades


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

apt -qq -o=Dpkg::Use-Pty=0 -yy install $DEVUAN_INIT_PKGS --no-install-recommends --allow-downgrades


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."

NITRUX_BASE_PACKAGES='
	nitrux-hardware-drivers
	nitrux-minimal
	nitrux-standard
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NITRUX_BASE_PACKAGES $NITRUX_BF_PKG --no-install-recommends


#	Add NX Desktop metapackage.

puts "INSTALLING DESKTOP PACKAGES."

LIBPNG12_PKG='
	libpng12-0
'

XENIAL_PACKAGES='
	plymouth=0.9.2-3ubuntu13.5
	plymouth-label=0.9.2-3ubuntu13.5
	plymouth-themes=0.9.2-3ubuntu13.5
	libplymouth4=0.9.2-3ubuntu13.5
	ttf-ubuntu-font-family
'

DEVUAN_PULSE_PKGS='
	libpulse-mainloop-glib0=13.0-5
	libpulse0=13.0-5
	libpulsedsp=13.0-5
	pulseaudio-module-bluetooth=13.0-5
	pulseaudio-utils=13.0-5
	pulseaudio=13.0-5
'

MISC_KDE_PKGS='
	plasma-pa=4:5.17.5-2
'

mkdir -p /etc/X11/cursors/

NX_DESKTOP_PKG='
	sddm
	blackbox
	xterm=353-1ubuntu1
	nx-desktop-settings
	git
	axel
	npm
	nx-plasma-look-and-feel
'

NX_MISC_PKGS='
'

ADD_MISC_PKGS='
	os-prober
'

HOLD_MISC_PKGS='
	cgroupfs-mount
	ssl-cert
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install -t nitrux $LIBPNG12_PKG --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install $XENIAL_PACKAGES $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG $NX_MISC_PKGS $ADD_MISC_PKGS --no-install-recommends --allow-downgrades

apt-mark hold $HOLD_MISC_PKGS


#	Upgrade KF5 libs for Latte Dock.

puts "UPGRADING KDE PACKAGES."

cp /configs/files/sources.list.neon.unstable /etc/apt/sources.list.d/neon-unstable-repo.list

HOLD_KDE_PKGS='
	kwin-addons
	kwin-common
	kwin-data
	kwin-x11
	libkwin4-effect-builtins1
	libkwineffects12
	libkwinglutils12
	libkwinxrenderutils12
	qml-module-org-kde-kwindowsystem
'

UPDT_KDE_PKGS='
	latte-dock
'

UPDT_KF5_LIBS='
	libkf5activities5
	libkf5archive5
	libkf5config-data
	libkf5configcore5
	libkf5configgui5
	libkf5coreaddons-data
	libkf5coreaddons5
	libkf5crash5
	libkf5dbusaddons-data
	libkf5dbusaddons5
	libkf5declarative-data
	libkf5declarative5
	libkf5globalaccel-bin
	libkf5globalaccel-data
	libkf5globalaccel5
	libkf5guiaddons5
	libkf5i18n-data
	libkf5i18n5
	libkf5iconthemes-data
	libkf5iconthemes5
	libkf5newstuff-data
	libkf5newstuff5
	libkf5newstuffcore5
	libkf5notifications-data
	libkf5notifications5
	libkf5package-data
	libkf5package5
	libkf5plasmaquick5
	libkf5plasma5
	libkf5quickaddons5
	libkf5service-bin
	libkf5service-data
	libkf5service5
	libkf5waylandclient5
	libkf5windowsystem5
	libkf5xmlgui-bin
	libkf5xmlgui-data
	libkf5xmlgui5
'

UPDT_MISC_LIBS='
	libpolkit-qt5-1-1
'

apt-mark hold $HOLD_KDE_PKGS

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_KDE_PKGS $UPDT_KF5_LIBS $UPDT_MISC_LIBS --only-upgrade --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPDATE_MISC_PKGS='
	linux-firmware
'

DOWNGRADE_MISC_PKGS='
	bluez=5.50-1.2~deb10u1
	initramfs-tools-bin=0.137ubuntu12
	initramfs-tools-core=0.137ubuntu12
	initramfs-tools=0.137ubuntu12
	libc-bin=2.31-0ubuntu9
	libc6-dev=2.31-0ubuntu9
	libc-dev-bin=2.31-0ubuntu9
	libc6=2.31-0ubuntu9
	locales=2.31-0ubuntu9
	sudo=1.9.1-1ubuntu1
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDATE_MISC_PKGS --only-upgrade
apt -qq -o=Dpkg::Use-Pty=0 -yy install $DOWNGRADE_MISC_PKGS --allow-downgrades --allow-change-held-packages


#	Add OpenRC configuration.

puts "ADDING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $OPENRC_CONFIG --no-install-recommends


#	Remove unnecessary sources.list files.

puts "REMOVE SOURCES FILES."

rm /etc/apt/sources.list.d/ubuntu-focal-repo.list \
	/etc/apt/sources.list.d/ubuntu-xenial-repo.list \
	/etc/apt/sources.list.d/ubuntu-groovy-repo.list \
	/etc/apt/sources.list.d/ubuntu-bionic-repo.list \
	/etc/apt/sources.list.d/neon-unstable-repo.list \
	/etc/apt/sources.list.d/neon-user-repo.list \
	/etc/apt/sources.list.d/devuan-beowulf-repo.list \
	/etc/apt/sources.list.d/devuan-ceres-repo.list \
	/etc/apt/sources.list.d/gpu-ppa-repo.list \
	/etc/apt/preferences

apt -qq update


#	Add repositories configuration.

puts "ADDING REPOSITORIES SETTINGS."

NX_REPO_PKG='
	nitrux-repository-settings
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NX_REPO_PKG --no-install-recommends


#	Add live user.

puts "ADDING LIVE USER."

NX_LIVE_USER='
	nitrux-live-user
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NX_LIVE_USER --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt -qq -o=Dpkg::Use-Pty=0 -yy upgrade --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


#	WARNING:
#	No apt usage past this point.


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

/bin/cp /configs/files/casper.conf /etc/


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


#	Use XZ compression when creating the initramfs.
#	Add persistence script.
#	Add fstab mount binds.

puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/scripts/mounts >> /usr/share/initramfs-tools/scripts/casper-bottom/12fstab

update-initramfs -u


#	WARNING:
#	No dpkg usage past this point.


#	Check contents of /boot.
#	Check contents of OpenRC runlevels.
#	Check that init system is not systemd.

ls -l /boot
ls -l /etc/init.d/ /etc/runlevels/default/ /etc/runlevels/nonetwork/ /etc/runlevels/off /etc/runlevels/recovery/ /etc/runlevels/sysinit/
stat /sbin/init


puts "EXITING BOOTSTRAP."
