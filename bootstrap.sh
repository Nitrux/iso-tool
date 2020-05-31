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
	uuid-runtime=2.34-0.1+devuan1
	util-linux=2.34-0.1+devuan1
	libprocps6=2:3.3.12-3+devuan2.1
	bsdutils=1:2.34-0.1+devuan1
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


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."


GRUB_PACKAGES='
	grub-efi-amd64-signed=1+2.04+7
	grub-efi-amd64-bin=2.04-7
	grub-common=2.04-7
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
'

NX_DESKTOP_PKG='
	nx-desktop
	nx-desktop-apps
'

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

puts "UPGRADING/INSTALLING MISC. PACKAGES."

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

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
'

UPDT_MISC_PKGS='
	cgroupfs-mount
	linux-firmware
'

apt -qq update
apt -qq -o=Dpkg::Use-Pty=0 -yy install $UPDT_GLBIC_PKGS $UPDT_MISC_PKGS --only-upgrade
apt -qq -o=Dpkg::Use-Pty=0 -yy install $OTHER_MISC_PKGS --no-install-recommends


#	Install the kernel.

puts "INSTALL KERNEL."

INSTALL_KERNEL='
	linux-image-unsigned-5.4.21-050421-generic
	linux-modules-5.4.21-050421-generic
	linux-headers-5.4.21-050421
	linux-headers-5.4.21-050421-generic
'

apt -qq -o=Dpkg::Use-Pty=0 -yy install $INSTALL_KERNEL --no-install-recommends
apt -qq -o=Dpkg::Use-Pty=0 -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


#	WARNING:
#	No apt usage past this point.


# #	Add MAUI Appimages.
# 
# puts "ADDING MAUI APPS (STABLE)."
# 
# wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
# chmod +x /tmp/mc
# /tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
# mkdir maui_pkgs
# 
# (
# 	cd maui_pkgs
# 
# 	_apps=$(/tmp/mc ls nx/maui/stable/ | grep -Eo "\w*/")
# 
# 	for i in $_apps; do
#         _branch=$(/tmp/mc cat nx/maui/stable/${i}LATEST)
#         /tmp/mc cp -r nx/maui/stable/${i}${_branch} ./
# 	done
# 
# 	mv index-*amd64*.AppImage /Applications/index
# 	mv buho-*amd64*.AppImage /Applications/buho
# 	mv nota-*amd64*.AppImage /Applications/nota
# 	mv vvave-*amd64*.AppImage /Applications/vvave
# 	mv station-*amd64*.AppImage /Applications/station
# 	mv pix-*amd64*.AppImage /Applications/pix
# 
# 	chmod +x /Applications/*
# 
# 	ls -l /Applications
# )
# 
# /tmp/mc config host rm nx
# 
# rm -r \
# 	maui_pkgs \
# 	/tmp/mc


#	Add MAUI Appimages.

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

cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc

echo "XDG_CONFIG_DIRS=/etc/xdg" >> /etc/environment
echo "XDG_DATA_DIRS=/usr/local/share:/usr/share" >> /etc/environment

cp /configs/other/compendium_offline.pdf /etc/skel/Desktop/Nitrux\ —\ Compendium.pdf
cp /configs/other/faq_offline.pdf /etc/skel/Desktop/Nitrux\ —\ FAQ.pdf

cp /usr/share/icons/nitrux_snow_cursors/index.theme /etc/X11/cursors/nitrux_cursors.theme
ln -svf /etc/X11/cursors/nitrux_cursors.theme /etc/alternatives/x-cursor-theme
sed -i '$ a Inherits=nitrux_snow_cursors' /etc/X11/cursors/nitrux_cursors.theme

rm -r /home/travis


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
	/System/DevicesFS \
	/System/Libraries \
	/System/Mount/Filesystems \
	/System/Processes \
	/System/Runtime \
	/System/Resources/Shared \
	/System/Server/Services \
	/System/Variable \
	/Users/

cp /configs/files/hidden /.hidden


#	Add vfio modules and files.
#	FIXME: This configuration should be included a in a package
#	replacing the default package like base-files.

puts "ADDING VFIO ENABLEMENT AND CONFIGURATION."

>> /etc/initramfs-tools/modules printf "%s\n" \
	"install vfio-pci /usr/bin/vfio-pci-override-vga.sh" \
	"install vfio_pci /usr/bin/vfio-pci-override-vga.sh" \
	"softdep nvidia pre: vfio vfio_pci" \
	"softdep nouveau pre: vfio vfio_pci" \
	"softdep amdgpu pre: vfio vfio_pci" \
	"softdep radeon pre: vfio vfio_pci" \
	"softdep i915 pre: vfio vfio_pci" \
	"vfio" \
	"vfio_iommu_type1" \
	"vfio_virqfd" \
	"options vfio_pci ids=" \
	"vfio_pci ids=" \
	"vfio_pci" \
	"nvidia" \
	"nouveau" \
	"amdgpu" \
	"radeon" \
	"i915"

>> /etc/modules printf "%s\n" \
	"vfio" \
	"vfio_iommu_type1" \
	"vfio_pci" \
	"vfio_pci ids="

cp /configs/files/asound.conf /etc/
cp /configs/files/asound.conf /etc/skel/.asoundrc
cp /configs/files/iommu_unsafe_interrupts.conf /etc/modprobe.d/
cp /configs/files/{amdgpu.conf,i915.conf,kvm.conf,nvidia.conf,nouveau.conf,qemu-system-x86.conf,radeon.conf,vfio_pci.conf,vfio-pci.conf} /etc/modprobe.d/

cp /configs/scripts/vfio-pci-override-vga.sh /usr/bin/
chmod a+x /usr/bin/vfio-pci-override-vga.sh


#	Use LZ4 compression when creating the initramfs.
#	Add initramfs hook script.
#	Add the persistence and update the initramfs.
#	Add znx_dev_uuid parameter. FIXME
#	Add fstab mount binds.

puts "UPDATING THE INITRAMFS."

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan
cat /configs/scripts/mounts >> /usr/share/initramfs-tools/scripts/casper-bottom/12fstab

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
