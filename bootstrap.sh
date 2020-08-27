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

puts "INSTALLING BASIC AND PREBUILD PACKAGES."

BASIC_PACKAGES='
	apt-transport-https
	apt-utils
	ca-certificates
	dhcpcd5
	gnupg2
	language-pack-en
	language-pack-en-base
	libarchive-tools
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
	rng-tools
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
cp /configs/files/sources.list.devuan.beowulf /etc/apt/sources.list.d/devuan-beowulf-repo.list
cp /configs/files/sources.list.devuan.ceres /etc/apt/sources.list.d/devuan-ceres-repo.list
cp /configs/files/sources.list.devuan.chimaera /etc/apt/sources.list.d/devuan-chimaera-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.neon.unstable /etc/apt/sources.list.d/neon-unstable-repo.list
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

REMOVE_SYSTEMD_PKGS='
	systemd
	systemd-sysv
	libsystemd0
'

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

ADD_SYSTEMCTL_PKG='
	systemctl
'

apt -qq -o=Dpkg::Use-Pty=0 -yy purge --remove $REMOVE_SYSTEMD_PKGS
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt -qq -o=Dpkg::Use-Pty=0 -yy install $ELOGIND_PKGS $UPDT_APT_PKGS --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install -t focal $ADD_SYSTEMCTL_PKG --no-install-recommends
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

GRUB_PACKAGES='
	grub-efi-amd64-signed=1+2.04+9
	grub-efi-amd64-bin=2.04-9
	grub-common=2.04-9
	'

NITRUX_BASE_PACKAGES='
	nitrux-hardware-drivers
	nitrux-minimal
	nitrux-standard
'

NITRUX_BF_PKG='
	base-files
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $GRUB_PACKAGES $NITRUX_BASE_PACKAGES $NITRUX_BF_PKG --no-install-recommends


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

NX_DESKTOP_PKGS='
	nx-desktop
	nx-desktop-apps
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install -t nitrux $LIBPNG12_PKG --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install $XENIAL_PACKAGES $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKGS --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPDATE_MISC_PKGS='
	linux-firmware
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
	sddm=0.18.1-2xneon+20.04+focal+build10
	libkf5plasma5=5.73.0-0xneon+20.04+focal+build9
'

INSTALL_MISC_PKGS='

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


#	Add live user.

puts "ADDING LIVE USER."

NX_LIVE_USER='
	nitrux-live-user
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $NX_LIVE_USER --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


#	WARNING:
#	No apt usage past this point.


#	Add MAUI Appimages.

puts "ADDING MAUI APPS (NIGHTLY/CHERRYPICK_DATE)."

wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
chmod +x /tmp/mc
/tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
_latest=$(/tmp/mc cat nx/maui/nightly/WORKING)
mkdir maui_pkgs

(
	cd maui_pkgs

	_packages=$(/tmp/mc ls nx/maui/nightly/$_latest/ | grep -Po "[\w\d\-+]*amd64\.AppImage")

	for i in $_packages; do
		/tmp/mc cp nx/maui/nightly/$_latest/$i .
	done

	mv index-*amd64*.AppImage /Applications/index
	mv buho-*amd64*.AppImage /Applications/buho
	mv nota-*amd64*.AppImage /Applications/nota
	mv vvave-*amd64*.AppImage /Applications/vvave
	mv station-*amd64*.AppImage /Applications/station
	mv pix-*amd64*.AppImage /Applications/pix

	chmod +x /Applications/*

	ls -l /Applications
)

/tmp/mc config host rm nx

rm -r \
	maui_pkgs \
	/tmp/mc


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

/bin/cp /configs/files/casper.conf /etc/

rm -r /home/travis


#	Check contents of /etc/environment.
#	Check live user.
#	Check x_cursors_theme
#	Check contents of OpenRC runlevels.
#	Check that init system is not systemd.

puts "DO SOME CHECKS."

cat /etc/environment
compgen -u 
groups nitrux
ls -l /etc/alternatives/x-cursor-theme
cat /etc/X11/cursors/nitrux_cursors.theme
ls -l /etc/init.d/ /etc/runlevels/default/ /etc/runlevels/nonetwork/ /etc/runlevels/off /etc/runlevels/recovery/ /etc/runlevels/sysinit/
stat /sbin/init


#	Implement a new FHS.
#	FIXME: Replace with kernel patch and userland tool.

puts "CREATING NEW FHS."

mkdir -p \
	/Core/System/Deployments \
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
#	Add initramfs hook script.
#	Add the persistence and update the initramfs.
#	Add fstab mount binds.
#	Add znx_dev_uuid parameter. FIXME

puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/scripts/mounts >> /usr/share/initramfs-tools/scripts/casper-bottom/12fstab
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan

update-initramfs -u
lsinitramfs -l /boot/initrd.img* | grep vfio

#	Remove APT.

puts "REMOVING APT."

REMOVE_APT='
	apt
	apt-utils
	apt-transport-https
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path $REMOVE_APT &> /dev/null


#	Clean the filesystem.

puts "REMOVING CASPER."

REMOVE_PACKAGES='
	casper
	lupin-casper
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path $REMOVE_PACKAGES &> /dev/null


#	WARNING:
#	No dpkg usage past this point.


#	Use script to remove dpkg.

puts "REMOVING DPKG."

/configs/scripts/rm-dpkg.sh
rm /configs/scripts/rm-dpkg.sh


puts "EXITING BOOTSTRAP."
