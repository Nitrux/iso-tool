#! /bin/bash

set -xe

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }

update () { apt -qq update; }
install () { apt -yy install --no-install-recommends $@; }
install_downgrades () { apt -yy install --no-install-recommends --allow-downgrades $@; }
install_downgrades_hold () { apt -yy install --no-install-recommends --allow-downgrades --allow-change-held-packages $@; }
only_upgrade () { apt -yy install --no-install-recommends --only-upgrade $@; }
purge () { apt -yy purge --remove $@; }
autoremove () { apt -yy autoremove $@; }
hold () { apt-mark hold $@; }
clean_all () { apt clean && apt autoclean; }
fix_install () { apt -yy --fix-broken install $@; }
add_keys () { apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $@; }


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
	dhcpcd5
	gnupg2
	debconf
'

PRE_BUILD_PKGS='
	avahi-daemon
	bluez
	btrfs-progs
	cgroupfs-mount
	cups-daemon
	dictionaries-common
	efibootmgr
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
#	Add key for the Proprietary Graphics Drivers PPA.
#	Add key for Ubuntu repositories #1.
#	Add key for Ubuntu repositories #2.
#	Add key for Kubuntu Backports PPA.

puts "ADDING REPOSITORY KEYS."

 add_keys \
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

install -t bionic $CASPER_PKGS
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

DEVUAN_NETWORKMANAGER_PKGS='
	init-system-helpers
	libnm0
	network-manager
'

DEVUAN_UDISKS2_PKGS='
	libudisks2-0
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

install $DEVUAN_NETWORKMANAGER_PKGS $DEVUAN_UDISKS2_PKGS
install_downgrades $DEVUAN_POLKIT_PKGS


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
	nitrux-hardware-drivers
	nitrux-minimal
	nitrux-standard
'

install $NITRUX_BASE_PKGS $NITRUX_BF_PKG


#	Install NX Desktop metapackage.

puts "INSTALLING DESKTOP PACKAGES."

LIBPNG12_PKG='
	libpng12-0
'

PLYMOUTH_XENIAL_PKGS='
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

NX_DESKTOP_PKGS='
	sddm
	blackbox
	xterm=353-1ubuntu1
	latte-dock
	fonts-nx-desktop
	grub2-theme-nitrux
	kvantum-theme-kvnitrux
	luv-icon-theme
	nitrux-wallpapers-free
	nx-audio-applet
	nx-clock-applet
	nx-desktop-apps
	nx-desktop-settings
	nx-firewall
	nx-gtk-themes
	nx-networkmanagement-applet
	nx-notifications-applet
	nx-plasma-look-and-feel
	nx-simplemenu-applet
	nx-systemtray-applet
	plymouth-theme-nitrux
	acpi-support
	acpid
	alsa-base
	amd64-microcode
	avahi-daemon
	binutils-multiarch
	coreutils
	cups-daemon
	desktop-file-utils
	dnsmasq
	firejail
	firejail-profiles
	fonts-arphic-ukai
	fonts-arphic-uming
	fonts-freefont-ttf
	fonts-ipafont-gothic
	fonts-ipafont-mincho
	fonts-liberation
	fonts-opensymbol
	fonts-powerline
	fonts-unfonts-core
	ghostscript-x
	gnome-keyring
	gnupg-agent
	haveged
	intel-microcode
	iucode-tool
	laptop-detect
	libavahi-glib1
	libdbus-glib-1-2
	libdbusmenu-gtk3-4
	libexiv2-27
	libstartup-notification0
	mscompress
	openresolv
	pm-utils
	policykit-desktop-privileges
	powerline
	preload
	pulseaudio-module-bluetooth
	python-cairo
	python-gi-cairo
	python-setuptools
	qml-module-qtquick-xmllistmodel
	qt5-gtk-platformtheme
	qttranslations5-l10n
	rfkill
	rng-tools
	rsyslog
	sbsigntool
	ssh-askpass
	upower
	usb-modeswitch
	wireless-tools
	xdg-user-dirs
	xdg-utils
'

HOLD_MISC_PKGS='
	cgroupfs-mount
	ssl-cert
'

mkdir -p /etc/X11/cursors/

install_downgrades -t nitrux $LIBPNG12_PKG
install_downgrades $PLYMOUTH_XENIAL_PKGS $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKGS
hold $HOLD_MISC_PKGS


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

hold $HOLD_KDE_PKGS

update
only_upgrade $UPDT_KDE_PKGS $UPDT_KF5_LIBS $UPDT_MISC_LIBS
fix_install


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPGRADE_MISC_PKGS='
	linux-firmware
'

DOWNGRADE_MISC_PKGS='
	bluez=5.50-1.2~deb10u1
'

update
only_upgrade $UPGRADE_MISC_PKGS
install_downgrades_hold $DOWNGRADE_MISC_PKGS


#	Add OpenRC configuration.

puts "ADDING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

install $OPENRC_CONFIG

#	Add live user.

puts "ADDING LIVE USER."

NX_LIVE_USER='
	nitrux-live-user
'

install $NX_LIVE_USER
autoremove
clean_all


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


#	Use lz4 compression to initramfs.
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
