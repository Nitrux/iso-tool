#! /bin/bash

set -x

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }


#	let us start.

puts "STARTING BOOTSTRAP."


#	Install basic packages.

puts "INSTALLING BASIC PACKAGES."

cp /configs/files/sources.list.eoan /etc/apt/sources.list

BASIC_PACKAGES='
	apt-transport-https
	apt-utils
	avahi-daemon
	bluez
	ca-certificates
	casper
	cgroupfs-mount
	dhcpcd5
	gnupg2
	language-pack-en
	language-pack-en-base
	libarchive13
	libelf1
	localechooser-data
	locales
	lupin-casper
	open-vm-tools
	rng-tools
	systemd
	user-setup
	wget
	xz-utils
	ufw
	libxvmc1
	btrfs-progs
	dictionaries-common
	locales-all
	squashfs-tools
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $BASIC_PACKAGES --no-install-recommends


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
cp /configs/files/sources.list.eoan /etc/apt/sources.list.d/ubuntu-eoan-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp /configs/files/sources.list.xenial /etc/apt/sources.list.d/ubuntu-xenial-repo.list
# cp /configs/files/sources.list.backports /etc/apt/sources.list.d/backports-ppa-repo.list

apt -qq update


#	Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


#	Use Glibc package from Devuan.

GLIBC_2_30_PKG='
	libc6=2.30-8
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $GLIBC_2_30_PKG --no-install-recommends --allow-downgrades


#	Use elogind packages from Devuan.

puts "ADDING ELOGIND."

ELOGIND_PKGS='
	libelogind0
	elogind
	uuid-runtime=2.35.2-2+devuan1
	util-linux=2.35.2-2+devuan1
	libprocps6=2:3.3.12-3+devuan2.1
	bsdutils=1:2.35.2-2+devuan1
'

UPDT_APT_PKGS='
	apt=2.1.2+devuan1
	apt-transport-https=2.1.2+devuan1
	apt-utils=2.1.2+devuan1
'

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

apt -qq -o=Dpkg::Use-Pty=0 -yy purge --remove $REMOVE_SYSTEMD_PKGS
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt -qq -o=Dpkg::Use-Pty=0 -yy install $ELOGIND_PKGS $UPDT_APT_PKGS --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


#	Use PolicyKit packages from Devuan.

puts "ADDING POLICYKIT."

DEVUAN_POLKIT_PKGS='
	libpolkit-agent-1-0=0.105-25+devuan8
	libpolkit-backend-1-0=0.105-25+devuan8
	libpolkit-backend-elogind-1-0=0.105-25+devuan8
	libpolkit-gobject-1-0=0.105-25+devuan8
	libpolkit-gobject-elogind-1-0=0.105-25+devuan8
	libpolkit-qt5-1-1=0.112.0-6
	policykit-1=0.105-25+devuan8
	polkit-kde-agent-1=4:5.17.5-2
'

DEVUAN_NM_UD2='
	libnm0=1.14.6-2+deb10u1
	libudisks2-0=2.8.4-2+devuan1
	network-manager=1.14.6-2+deb10u1
	udisks2=2.8.4-2+devuan1
	init-system-helpers=1.57+devuan1
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $DEVUAN_NM_UD2 $DEVUAN_POLKIT_PKGS --no-install-recommends --allow-downgrades


#	Add SysV as init.

puts "ADDING SYSV AS INIT."

DEVUAN_INIT_PKGS='
	init=1.57+devuan1
	sysv-rc
	sysvinit-core
	sysvinit-utils
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $DEVUAN_INIT_PKGS --no-install-recommends --allow-downgrades


#	Check that init system is not systemd.

puts "CHECKING INIT LINK."

init --version
stat /sbin/init


# 	Install minimal metapackage.

cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list

NITRUX_MIN_PACKAGE='
	nitrux-minimal-legacy
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $NITRUX_MIN_PACKAGE --no-install-recommends

rm  /etc/apt/sources.list.d/ubuntu-focal-repo.list


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."


GRUB_PACKAGES='
	grub-efi-amd64-signed=1+2.04+7
	grub-efi-amd64-bin=2.04-7
	grub-common=2.04-7
	grub2-common=2.04-7
'

NITRUX_BASE_PACKAGES='
	nitrux-hardware-drivers-legacy
	nitrux-standard-legacy
'

NITRUX_BF_PKG='
	base-files=11.1.3+nitrux-legacy
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $GRUB_PACKAGES $NITRUX_BASE_PACKAGES $NITRUX_BF_PKG --no-install-recommends


#	Add NX Desktop metapackage.

puts "INSTALLING DESKTOP PACKAGES."

XENIAL_PACKAGES='
	plymouth=0.9.2-3ubuntu13.5
	plymouth-label=0.9.2-3ubuntu13.5
	plymouth-themes=0.9.2-3ubuntu13.5
	libplymouth4=0.9.2-3ubuntu13.5
	ttf-ubuntu-font-family
'

DEVUAN_PULSE_PKGS='
	libpulse0=13.0-5
	pulseaudio=13.0-5
	libpulse-mainloop-glib0=13.0-5
	pulseaudio-utils=13.0-5
	libpulsedsp=13.0-5
	pulseaudio-module-bluetooth=13.0-5
'

MISC_KDE_PKGS='
	plasma-pa=4:5.17.5-2
	bluedevil
	libkf5xmlgui5=5.70.0-0xneon+18.04+bionic+build43
	libkf5xmlgui-data=5.70.0-0xneon+18.04+bionic+build43
	xdg-desktop-portal-kde=5.18.5-0xneon+18.04+bionic+build66
	libqt5webkit5=5.212.0~alpha3-5+18.04+bionic+build43
	liquidshell
'

NX_DESKTOP_PKG='
	nx-desktop-legacy-sysv
	nx-desktop-apps-legacy-sysv
'

CALAMARES_PKGS='
	calamares
	calamares-settings-nitrux
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $XENIAL_PACKAGES $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG $CALAMARES_PKGS --no-install-recommends --allow-downgrades


#	Upgrade KF5 packages and libs.

puts "UPGRADING KDE PACKAGES."

cp /configs/files/sources.list.neon.unstable /etc/apt/sources.list.d/neon-unstable-repo.list


UPDT_KDE_PKGS='
	kdenlive
'

UPDT_MISC_LIBS='
	libpolkit-qt5-1-1
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_KDE_PKGS $UPDT_KF5_LIBS $UPDT_MISC_LIBS --only-upgrade --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


#	Upgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/INSTALLING MISC. PACKAGES."

UPDT_GLBIC_PKGS='
	libc-bin
	libc6
	locales
'

OTHER_MISC_PKGS='
	gamemode
	tmate
	virtualbox-guest-dkms
	virtualbox-guest-x11
'

UPDT_MISC_PKGS='
	linux-firmware
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_GLBIC_PKGS $UPDT_MISC_PKGS --only-upgrade
apt -qq -o=Dpkg::Use-Pty=0 -yy install $OTHER_MISC_PKGS --no-install-recommends
apt clean &> /dev/null
apt autoclean &> /dev/null


#	Remove unnecessary sources.list files.

puts "REMOVE SOURCES FILES."

rm /etc/apt/sources.list.d/ubuntu-eoan-repo.list /etc/apt/sources.list.d/ubuntu-xenial-repo.list /etc/apt/sources.list.d/ubuntu-groovy-repo.list /etc/apt/sources.list.d/neon-unstable-repo.list


#	Make sure to refresh appstream cache.

appstreamcli refresh --force
apt -qq update


#	WARNING:
#	No apt usage past this point.


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc

/bin/cp /configs/files/kwinrc /etc/xdg/kwinrc

cp /configs/files/grub /etc/default/grub

sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/' /etc/calamares/modules/partition.conf
sed -i 's/systemd: true/systemd: false/g' /etc/calamares/modules/machineid.conf
sed -i 's/restartNowCommand: "systemctl -i reboot"/restartNowCommand: "reboot"/g' /etc/calamares/modules/finished.conf

sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitruxDark/KvNitruxDark.kvconfig
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitrux/KvNitrux.kvconfig
sed -i 's/Backend=OpenGL/Backend=XRender/' /etc/xdg/kwinrc


puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/

update-initramfs -u


#	WARNING:
#	No dpkg usage past this point.

puts "EXITING BOOTSTRAP."
