#! /bin/bash

set -x

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
	libelf1
	libxvmc1
	open-vm-tools
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
cp /configs/files/sources.list.devuan /etc/apt/sources.list.d/devuan-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list
cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp /configs/files/sources.list.xenial /etc/apt/sources.list.d/ubuntu-xenial-repo.list
# cp /configs/files/sources.list.eoan /etc/apt/sources.list.d/ubuntu-eoan-repo.list
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
	grub-efi-amd64-signed=1+2.04+8
	grub-efi-amd64-bin=2.04-8
	grub-common=2.04-8
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
	bluedevil
	libkf5itemmodels5
	libkf5xmlgui5
	libkf5xmlgui-data
	plasma-pa=4:5.17.5-2
'

NX_DESKTOP_PKG='
	nx-desktop
	nx-desktop-apps
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install -t nitrux $LIBPNG12_PKG --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy install $XENIAL_PACKAGES $DEVUAN_PULSE_PKGS $MISC_KDE_PKGS $NX_DESKTOP_PKG --no-install-recommends --allow-downgrades
apt -qq -o=Dpkg::Use-Pty=0 -yy --fix-broken install


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
	libphonon4qt5-4
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
	libkf5plasma5
	libkf5plasmaquick5
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


#	Upgrade and install misc. packages.

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

puts "UPGRADING/INSTALLING MISC. PACKAGES."

# UPDT_GLBIC_PKGS='
# 	libc-bin
# 	libc6
# 	locales
# '

UPDT_MISC_PKGS='
	bluez
	cgroupfs-mount
	linux-firmware
	sudo=1.9.1-1ubuntu1
	initramfs-tools=0.137ubuntu10
	initramfs-tools-core=0.137ubuntu10
	initramfs-tools-bin=0.137ubuntu10
'

OTHER_MISC_PKGS='
	gamemode
	tmate
	virtualbox-guest-dkms
	virtualbox-guest-x11
	docker.io
	flatpak
	fakeroot
	looking-glass-client
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_MISC_PKGS --only-upgrade --allow-downgrades --allow-change-held-packages
apt -qq -o=Dpkg::Use-Pty=0 -yy install $OTHER_MISC_PKGS --no-install-recommends


#	Install the kernel.

puts "INSTALL KERNEL."

INSTALL_KERNEL='
	linux-image-unsigned-5.4.53-050453-generic
	linux-modules-5.4.53-050453-generic
	linux-headers-5.4.53-050453
	linux-headers-5.4.53-050453-generic
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $INSTALL_KERNEL --no-install-recommends


#	Add OpenRC configuration.

puts "ADDING OPENRC CONFIG."

OPENRC_CONFIG='
	openrc-config
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $OPENRC_CONFIG --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


#	WARNING:
#	No apt usage past this point.


#	Add MAUI Appimages.

puts "ADDING MAUI APPS (STABLE)."

wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
chmod +x /tmp/mc
/tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
mkdir maui_pkgs

(
	cd maui_pkgs

	_apps=$(/tmp/mc ls nx/maui/stable/ | grep -Eo "\w*/")

	for i in $_apps; do
		_branch=$(/tmp/mc cat nx/maui/stable/${i}LATEST)
		/tmp/mc cp -r nx/maui/stable/${i}${_branch} ./
	done

 	mv ${_branch}/index-*amd64*.AppImage /Applications/index
 	mv ${_branch}/buho-*amd64*.AppImage /Applications/buho
 	mv ${_branch}/nota-*amd64*.AppImage /Applications/nota
 	mv ${_branch}/vvave-*amd64*.AppImage /Applications/vvave
 	mv ${_branch}/station-*amd64*.AppImage /Applications/station
 	mv ${_branch}/pix-*amd64*.AppImage /Applications/pix

 	chmod +x /Applications/*

 	ls -l /Applications
 )

 /tmp/mc config host rm nx

 rm -r \
 	maui_pkgs \
 	/tmp/mc


# #	Add MAUI Appimages.

# puts "ADDING MAUI APPS (NIGHTLY)."

# wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
# chmod +x /tmp/mc
# /tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
# _latest=$(/tmp/mc cat nx/maui/nightly/LATEST)
# mkdir maui_pkgs

# (
# 	cd maui_pkgs

# 	_packages=$(/tmp/mc ls nx/maui/nightly/$_latest/ | grep -Po "[\w\d\-+]*amd64\.AppImage")

# 	for i in $_packages; do
# 		/tmp/mc cp nx/maui/nightly/$_latest/$i .
# 	done

# 	mv index-*amd64*.AppImage /Applications/index
# 	mv buho-*amd64*.AppImage /Applications/buho
# 	mv nota-*amd64*.AppImage /Applications/nota
# 	mv vvave-*amd64*.AppImage /Applications/vvave
# 	mv station-*amd64*.AppImage /Applications/station
# 	mv pix-*amd64*.AppImage /Applications/pix

# 	chmod +x /Applications/*

# 	ls -l /Applications
# )

# /tmp/mc config host rm nx

# rm -r \
# 	maui_pkgs \
# 	/tmp/mc


#	Changes specific to this image. If they can be put in a package, do so.
#	FIXME: These fixes should be included in a package.

puts "ADDING MISC. FIXES."

cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc

echo "XDG_CONFIG_DIRS=/etc/xdg" >> /etc/environment
echo "XDG_DATA_DIRS=/usr/local/share:/usr/share" >> /etc/environment

cp /configs/other/compendium_offline.pdf /etc/skel/Desktop/Nitrux\ —\ Compendium.pdf
cp /configs/other/faq_offline.pdf /etc/skel/Desktop/Nitrux\ —\ FAQ.pdf

cp /usr/share/icons/nitrux_snow_cursors/index.theme /etc/X11/cursors/nitrux_cursors.theme
ln -svf /etc/X11/cursors/nitrux_cursors.theme /etc/alternatives/x-cursor-theme
sed -i '$ a Inherits=nitrux_snow_cursors' /etc/X11/cursors/nitrux_cursors.theme

rm -r /home/travis


#	Check contents of OpenRC runlevels.

ls -l /etc/init.d/ /etc/runlevels/default/ /etc/runlevels/nonetwork/ /etc/runlevels/off /etc/runlevels/recovery/ /etc/runlevels/sysinit/


#	Check that init system is not systemd.

stat /sbin/init


#	Implement a new FHS.
#	FIXME: Replace with kernel patch and userland tool.

puts "CREATING NEW FHS."

mkdir -p \
	/Core/System/Deployments \
	/Devices \
	/Devices/Removable \
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
lsinitramfs -l /boot/initrd.img-5.4.21-050421-generic | grep vfio

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
