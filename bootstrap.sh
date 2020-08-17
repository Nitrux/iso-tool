#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }


#	let us start.

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
	language-pack-en
	language-pack-en-base
	libarchive13
	localechooser-data
	locales
	systemd
	user-setup
	wget
	xz-utils
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
	grub2-common
	libelf1
	libpam-runtime
	libxvmc1
	linux-base
	locales-all
	rng-tools
	shim-signed
	systemd-sysv
	squashfs-tools
	sudo
	ufw
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $BASIC_PACKAGES $PREBUILD_PACKAGES --no-install-recommends


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
cp /configs/files/sources.list.devuan /etc/apt/sources.list.d/devuan-repo.list
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
	bsdutils
	elogind
	libelogind0
	libprocps7
	util-linux
	uuid-runtime
'

UPDT_APT_PKGS='
	apt
	apt-transport-https
	apt-utils
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

ADD_SYSTEMCTL_PKG='
	systemctl
'

apt -qq -o=Dpkg::Use-Pty=0 -yy purge --remove $REMOVE_SYSTEMD_PKGS
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt -qq -o=Dpkg::Use-Pty=0 -yy install $ELOGIND_PKGS $UPDT_APT_PKGS --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install -t focal $ADD_SYSTEMCTL_PKG --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install

apt-mark hold $ADD_SYSTEMCTL_PKG


#	Use PolicyKit packages from Devuan.

puts "ADDING POLICYKIT."

DEVUAN_POLKIT_PKGS='
	libpolkit-agent-1-0=0.105-25+devuan8
	libpolkit-backend-1-0=0.105-25+devuan8
	libpolkit-backend-elogind-1-0=0.105-25+devuan8
	libpolkit-gobject-1-0=0.105-25+devuan8
	libpolkit-gobject-elogind-1-0=0.105-25+devuan8
	libpolkit-qt5-1-1
	policykit-1=0.105-25+devuan8
	polkit-kde-agent-1=4:5.17.5-2
'

DEVUAN_NM_UD2='
	init-system-helpers
	libnm0
	libudisks2-0
	network-manager
	udisks2
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
	nitrux-hardware-drivers-legacy
	nitrux-minimal-legacy
	nitrux-standard-legacy
'

NITRUX_BF_PKG='
	base-files=11.1.5+nitrux-legacy
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
	bluedevil
	libkf5itemmodels5
	libkf5xmlgui-data
	libkf5xmlgui5
	libqt5webkit5
	plasma-pa=4:5.17.5-2
	xdg-desktop-portal-kde
'

NX_DESKTOP_PKG='
	nx-desktop-legacy
	nx-desktop-apps-legacy
'

NX_MISC_PKGS='
	latte-dock
	nx-audio-applet
	nx-clock-applet
    nx-networkmanagement-applet
    nx-notifications-applet
    nx-systemtray-applet
	nx-simplemenu-applet
'

CALAMARES_PKGS='
	calamares-qml
	calamares-qml-settings-nitrux
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install -t nitrux $LIBPNG12_PKG --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install $XENIAL_PACKAGES $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG $NX_MISC_PKGS $CALAMARES_PKGS --no-install-recommends --allow-downgrades


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
	ark
	bluedevil
	kcalc
	kde-spectacle
	latte-dock
'

UPDT_KF5_LIBS='
	libkf5activities5
	libkf5activitiesstats1
	libkf5archive5
	libkf5attica5
	libkf5auth-data
	libkf5auth5
	libkf5authcore5
	libkf5bluezqt-data
	libkf5bluezqt6
	libkf5bookmarks-data
	libkf5bookmarks5
	libkf5calendarevents5
	libkf5completion-data
	libkf5completion5
	libkf5config-data
	libkf5configcore5
	libkf5configgui5
	libkf5configwidgets-data
	libkf5configwidgets5
	libkf5contacts-data
	libkf5contacts5
	libkf5coreaddons-data
	libkf5coreaddons5
	libkf5crash5
	libkf5dbusaddons-data
	libkf5dbusaddons5
	libkf5declarative-data
	libkf5declarative5
	libkf5dnssd-data
	libkf5dnssd5
	libkf5doctools5
	libkf5emoticons-data
	libkf5emoticons5
	libkf5filemetadata-data
	libkf5filemetadata3
	libkf5globalaccel-bin
	libkf5globalaccel-data
	libkf5globalaccel5
	libkf5globalaccelprivate5
	libkf5guiaddons5
	libkf5holidays-data
	libkf5holidays5
	libkf5i18n-data
	libkf5i18n5
	libkf5iconthemes-data
	libkf5iconthemes5
	libkf5idletime5
	libkf5itemmodels5
	libkf5itemviews-data
	libkf5itemviews5
	libkf5jobwidgets-data
	libkf5jobwidgets5
	libkf5kdelibs4support-data
	libkf5kdelibs4support5
	libkf5kipi-data
	libkf5kipi32.0.0
	libkf5kirigami2-5
	libkf5newstuff-data
	libkf5newstuff5
	libkf5newstuffcore5
	libkf5notifications-data
	libkf5notifications5
	libkf5notifyconfig-data
	libkf5notifyconfig5
	libkf5package-data
	libkf5package5
	libkf5parts-data
	libkf5parts5
	libkf5plasmaquick5
	libkf5plasma5
	libkf5purpose-bin
	libkf5purpose5
	libkf5quickaddons5
	libkf5runner5
	libkf5service-bin
	libkf5service-data
	libkf5service5
	libkf5style5
	libkf5su-bin
	libkf5su-data
	libkf5su5
	libkf5syntaxhighlighting-data
	libkf5syntaxhighlighting5
	libkf5texteditor-bin
	libkf5texteditor5
	libkf5textwidgets-data
	libkf5textwidgets5
	libkf5threadweaver5
	libkf5waylandclient5
	libkf5waylandserver5
	libkf5widgetsaddons-data
	libkf5widgetsaddons5
	libkf5xmlgui-bin
	libkf5xmlgui-data
	libkf5xmlgui5
'

UPDT_MISC_LIBS='
	libpolkit-qt5-1-1
'

apt -qq update
apt-mark hold $HOLD_KDE_PKGS
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_KDE_PKGS $UPDT_KF5_LIBS $UPDT_MISC_LIBS --only-upgrade --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPDT_MISC_PKGS='
	cgroupfs-mount
	linux-firmware
	inkscape
'

DOWNGRADE_MISC_PKGS='
	bluez=5.50-1.2~deb10u1
	initramfs-tools-bin=0.137ubuntu10
	initramfs-tools-core=0.137ubuntu10
	initramfs-tools=0.137ubuntu10
	libc-bin=2.31-0ubuntu9
	libc6-dev=2.31-0ubuntu9
	libc-dev-bin=2.31-0ubuntu9
	libc6=2.31-0ubuntu9
	locales=2.31-0ubuntu9
	sudo=1.9.1-1ubuntu1
'

INSTALL_MISC_PKGS='
	docker.io
	fakeroot
	flatpak
	gamemode
	tmate
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDATE_MISC_PKGS --only-upgrade
apt -qq -o=Dpkg::Use-Pty=0 -yy install $DOWNGRADE_MISC_PKGS --allow-downgrades --allow-change-held-packages
apt -qq -o=Dpkg::Use-Pty=0 -yy install $INSTALL_MISC_PKGS --no-install-recommends


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
	/etc/apt/sources.list.d/devuan-repo.list \
	/etc/apt/sources.list.d/gpu-ppa-repo.list \
	/etc/apt/preferences

apt -qq update


#	Add repositories configuration.

puts "ADDING REPOSITORIES SETTINGS."

NX_REPO_PKG='
	nitrux-repository-settings
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NX_REPO_PKG --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


#	Make sure to refresh appstream cache.

appstreamcli refresh --force
apt -qq update


#	WARNING:
#	No apt usage past this point.


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

cp /configs/files/grub /etc/default/grub

ls -l /boot

ln -svf /boot/initrd.img-5.6* /initrd.img
ln -svf /boot/vmlinuz-5.6* /vmlinuz


#	Check contents of OpenRC runlevels.

ls -l /etc/init.d/ /etc/runlevels/default/ /etc/runlevels/nonetwork/ /etc/runlevels/off /etc/runlevels/recovery/ /etc/runlevels/sysinit/


#	Check that init system is not systemd.

stat /sbin/init


puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/

update-initramfs -u


#	WARNING:
#	No dpkg usage past this point.

puts "EXITING BOOTSTRAP."
