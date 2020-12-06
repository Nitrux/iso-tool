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

PRE_BUILD_PKGS='
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
	libpam-runtime
	linux-base
	locales-all
	rng-tools
	systemd-sysv
	squashfs-tools
	sudo
	ufw
	libpaper1
	libgs9
	libgs9-common
	ghostscript
	ghostscript-x
	cups-daemon
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

install_downgrades $DEVUAN_ELOGIND_PKGS $UPDT_APT_PKGS
purge $REMOVE_SYSTEMD_PKGS
autoremove
install -t focal $ADD_SYSTEMCTL_PKG
fix_install
hold $ADD_SYSTEMCTL_PKG


#	Use PolicyKit packages from Devuan.

puts "ADDING POLICYKIT."

DEVUAN_POLKIT_PKGS='
	libpolkit-agent-1-0=0.105-25+devuan8
	libpolkit-backend-1-0=0.105-25+devuan8
	libpolkit-backend-elogind-1-0=0.105-25+devuan8
	libpolkit-gobject-1-0=0.105-25+devuan8
	libpolkit-gobject-elogind-1-0=0.105-25+devuan8
	libpolkit-qt5-1-1=0.113.0-1
	policykit-1=0.105-25+devuan8
'

DEVUAN_NM_UD2='
	init-system-helpers
	libnm0
	libudisks2-0
	network-manager
	udisks2
'
install_downgrades $DEVUAN_NM_UD2 $DEVUAN_POLKIT_PKGS


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
	base-files
	nitrux-hardware-drivers
	nitrux-minimal
	nitrux-standard
'

NVIDIA_DRV_PKGS='
	libxnvctrl0
	nvidia-driver-450
	nvidia-prime
'

install $NITRUX_BASE_PKGS $NVIDIA_DRV_PKGS


#	Install NX Desktop metapackage.
#	NOTE: The plymouth packages have to be downgraded to the version in xenial-updates
#	because otherwise the splash is not shown.

puts "INSTALLING DESKTOP PACKAGES."

LIBPNG12_PKG='
	libpng12-0
'

XENIAL_PKGS='
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
	plasma-pa=4:5.19.5-3
'

NX_DESKTOP_PKG='
	nx-desktop
'

HOLD_MISC_PKGS='
	cgroupfs-mount
	ssl-cert
	base-passwd
'

install_downgrades -t nitrux $LIBPNG12_PKG
install_downgrades $XENIAL_PKGS $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG
hold $HOLD_MISC_PKGS


#	Upgrade, downgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/DOWNGRADING/INSTALLING MISC. PACKAGES."

UPGRADE_MISC_PKGS='
	linux-firmware
'

DOWNGRADE_MISC_PKGS='
	bluez=5.50-1.2~deb10u1
	initramfs-tools-bin=0.137ubuntu12
	initramfs-tools-core=0.137ubuntu12
	initramfs-tools=0.137ubuntu12
'

INSTALL_MISC_PKGS='
	xterm=353-1ubuntu1
'

update
only_upgrade $UPGRADE_MISC_PKGS
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

# Unhold misc. packages.

UNHOLD_MISC_PKGS='
	systemctl
	base-passwd
'

install $NX_LIVE_USER_PKG
autoremove
unhold $UNHOLD_MISC_PKGS
clean_all


#	WARNING:
#	No apt usage past this point.


# puts "ADDING MAUI APPS (STABLE)."

# wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
# chmod +x /tmp/mc
# /tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
# mkdir maui_pkgs

# (
# 	cd maui_pkgs

# 	_apps=$(/tmp/mc ls nx/maui/stable/ | grep -Eo "\w*/")

# 	for i in $_apps; do
# 		_branch=$(/tmp/mc cat nx/maui/stable/${i}LATEST)
# 		/tmp/mc cp -r nx/maui/stable/${i}${_branch} ./
# 	done

#  	mv ${_branch}/index-*amd64*.AppImage /Applications/index
#  	mv ${_branch}/buho-*amd64*.AppImage /Applications/buho
#  	mv ${_branch}/nota-*amd64*.AppImage /Applications/nota
#  	mv ${_branch}/vvave-*amd64*.AppImage /Applications/vvave
#  	mv ${_branch}/station-*amd64*.AppImage /Applications/station
#  	mv ${_branch}/pix-*amd64*.AppImage /Applications/pix

#  	chmod +x /Applications/*

#  	ls -l /Applications
#  )

#  /tmp/mc config host rm nx

#  rm -r \
#  	maui_pkgs \
#  	/tmp/mc

puts "ADDING MAUI APPS (NIGHTLY)."

wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
chmod +x /tmp/mc
/tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
_latest=$(/tmp/mc cat nx/maui/nightly/LATEST)
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

cat /configs/files/casper.conf > /etc/casper.conf

rm -r \
	/home/travis


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

ls -l /boot
ls -l /vmlinuz /initrd.img
ls -l /etc/init.d/ /etc/runlevels/default/ /etc/runlevels/nonetwork/ /etc/runlevels/off /etc/runlevels/recovery/ /etc/runlevels/sysinit/
stat /sbin/init
cat /etc/casper.conf
lsinitramfs -l /boot/initrd.img* | grep vfio
ls -l /usr/lib/dbus-1.0/dbus-daemon-launch-helper 


puts "EXITING BOOTSTRAP."
