#! /bin/bash

set -x

export LANG=C
export LC_ALL=C

puts () { printf "\n\n --- %s\n" "$*"; }


#	let us start.

puts "STARTING BOOTSTRAP."


#	Install basic packages.

puts "INSTALLING BASIC PACKAGES."

BASIC_PACKAGES='
    apt-transport-https
    apt-utils
    btrfs-progs
    ca-certificates
    casper
    dhcpcd5
    fuse3
    gnupg2
    language-pack-en
    language-pack-en-base
    libarchive13
    libelf1
    localechooser-data
    locales
    lupin-casper
    squashfs-tools
    systemd-sysv
    user-setup
    usrmerge
    wget
    xz-utils
'

apt -qq update
apt -yy install $BASIC_PACKAGES --no-install-recommends


#	Add key for Neon repository.
#	Add key for Nitrux repository.
#	Add key for the Proprietary Graphics Drivers PPA.

puts "ADDING REPOSITORY KEYS."

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
	55751E5D \
	1B69B2DA \
	1118213C > /dev/null


#	Copy sources.list files.

puts "ADDING SOURCES FILES."

cp -av /configs/files/sources.list.nitrux /etc/apt/sources.list
cp -av /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp -av /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list
cp -av /configs/files/sources.list.neon /etc/apt/sources.list.d/neon-user-repo.list

apt -qq update


#   Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


#	Install base system metapackages.

puts "INSTALLING BASE SYSTEM."

NITRUX_BASE_PACKAGES='
    nitrux-hardware-drivers-legacy
    nitrux-minimal-legacy
    nitrux-standard-legacy
'

BASE_FILES_PKG='
    base-files=11.1.2+nitrux-legacy
'

apt -yy install $NITRUX_BASE_PACKAGES --no-install-recommends
apt -yy install $BASE_FILES_PKG --allow-downgrades
apt-mark hold $BASE_FILES_PKG


#	Add NX Desktop metapackage.

puts "INSTALLING DESKTOP PACKAGES."

CALAMARES_PACKAGES='
    calamares
    calamares-settings-nitrux
'

MISC_PACKAGES_KDE='
    xdg-desktop-portal-kde=5.18.5-0xneon+18.04+bionic+build66
    libqt5webkit5=5.212.0~alpha3-5+18.04+bionic+build43
    liquidshell
'

OTHER_MISC_PACKAGES='
    virtualbox-guest-dkms
    virtualbox-guest-x11
'


NX_DESKTOP_PKG='
    nx-desktop-legacy
    nx-desktop-apps-legacy
'

apt -yy install $CALAMARES_PACKAGES $MISC_PACKAGES_KDE $OTHER_MISC_PACKAGES $NX_DESKTOP_PKG --no-install-recommends
apt -yy --fix-broken install
apt -yy autoremove


#   Make sure to refresh appstream cache.

appstreamcli refresh --force
apt -qq update


#    Upgrade KDE apps.

puts "UPGRADING KDE PACKAGES."

cp -av /configs/files/sources.list.neon.unstable /etc/apt/sources.list.d/neon-unstable-repo.list

apt -qq update

UPDT_KDE_PKGS='
    kdenlive
'

apt -yy install $UPDT_KDE_PKGS --only-upgrade

rm /etc/apt/sources.list.d/neon-unstable-repo.list

apt -qq update


#	WARNING:
#	No apt usage past this point.


# -- Changes specific to this image. If they can be put in a package do so.
#FIXME These fixes should be included in a package.

puts "ADDING MISC. FIXES."

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
/bin/cp /configs/other/org.kde.kinfocenter.desktop /usr/share/applications/org.kde.kinfocenter.desktop
/bin/cp /configs/files/kwinrc /etc/xdg/kwinrc
cp /configs/files/grub /etc/default/grub
sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/' /etc/calamares/modules/partition.conf
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitruxDark/KvNitruxDark.kvconfig
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitrux/KvNitrux.kvconfig


# -- Update initramfs.

puts "UPDATING THE INITRAMFS."

update-initramfs -u


#	WARNING:
#	No dpkg usage past this point.

puts "EXITING BOOTSTRAP."
