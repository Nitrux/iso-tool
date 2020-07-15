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
	btrfs-progs
	ca-certificates
	casper
	cgroupfs-mount
	dhcpcd5
	dictionaries-common
	efibootmgr
	gnupg2
	grub-common
	grub-efi-amd64
	grub-efi-amd64-bin
	grub-efi-amd64-signed
	grub2-common
	language-pack-en
	language-pack-en-base
	libarchive13
	libelf1
	libpam-runtime
	libxvmc1
	localechooser-data
	locales
	locales-all
	lupin-casper
	open-vm-tools
	rng-tools
	shim-signed
	squashfs-tools
	systemd
	ufw
	user-setup
	wget
	xz-utils
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


#	Add SysV as init.

puts "ADDING SYSV AS INIT."

DEVUAN_INIT_PKGS='
	init
	sysv-rc
	sysvinit-core
	sysvinit-utils
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $DEVUAN_INIT_PKGS --no-install-recommends --allow-downgrades


# 	Install minimal metapackage.

cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list

NITRUX_MIN_PACKAGE='
	nitrux-minimal-legacy
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $NITRUX_MIN_PACKAGE --no-install-recommends
rm  /etc/apt/sources.list.d/ubuntu-focal-repo.list
apt -qq update


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."

NITRUX_BASE_PACKAGES='
	nitrux-hardware-drivers-legacy
	nitrux-standard-legacy
'

NITRUX_BF_PKG='
	base-files=11.1.4+nitrux-legacy
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NITRUX_BASE_PACKAGES $NITRUX_BF_PKG --no-install-recommends


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
	libqt5webkit5=5.212.0~alpha3-5+18.04+bionic+build43
	liquidshell
	plasma-pa=4:5.17.5-2
	xdg-desktop-portal-kde
'

NX_DESKTOP_PKG='
	nx-desktop-legacy
	nx-desktop-apps-legacy
'

CALAMARES_PKGS='
	calamares=3.2.20-0xneon+18.04+bionic+build30
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
	docker.io
	flatpak
	fakeroot
'

UPDT_MISC_PKGS='
	cgroupfs-mount
	linux-firmware
	sudo=1.9.1-1ubuntu1
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_GLBIC_PKGS $UPDT_MISC_PKGS --only-upgrade
apt -qq -o=Dpkg::Use-Pty=0 -yy install $OTHER_MISC_PKGS --no-install-recommends

#	Remove unnecessary sources.list files.

puts "REMOVE SOURCES FILES."

rm /etc/apt/sources.list.d/ubuntu-eoan-repo.list \
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

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc

/bin/cp /configs/files/kwinrc /etc/xdg/kwinrc

cp /configs/files/grub /etc/default/grub

sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/' /etc/calamares/modules/partition.conf
sed -i 's/systemd: true/systemd: false/g' /etc/calamares/modules/machineid.conf
sed -i 's/restartNowCommand: "systemctl -i reboot"/restartNowCommand: "reboot"/g' /etc/calamares/modules/finished.conf
sed -i 's/    - command: apt install -y --no-upgrade -o Acquire::gpgv::Options::=--ignore-time-conflict grub-efi-amd64-signed/#    - command: apt install -y --no-upgrade -o Acquire::gpgv::Options::=--ignore-time-conflict grub-efi-amd64-signed/g' /etc/calamares/modules/before_bootloader_context.conf
sed -i 's/    - command: apt install -y --no-upgrade -o Acquire::gpgv::Options::=--ignore-time-conflict shim-signed/#    - command: apt install -y --no-upgrade -o Acquire::gpgv::Options::=--ignore-time-conflict shim-signed/g' /etc/calamares/modules/before_bootloader_context.conf

sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitruxDark/KvNitruxDark.kvconfig
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitrux/KvNitrux.kvconfig
sed -i 's/Backend=OpenGL/Backend=XRender/' /etc/xdg/kwinrc

ls -l /boot

ln -svf /boot/initrd.img-5* /initrd.img
ln -svf /boot/vmlinuz-5* /vmlinuz


#	Check that init system is not systemd.

stat /sbin/init


puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/

update-initramfs -u


#	WARNING:
#	No dpkg usage past this point.

puts "EXITING BOOTSTRAP."
