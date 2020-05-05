#! /bin/bash

set -x

export LANG=C
export LC_ALL=C

echo -e "\n"
echo -e "STARTING BOOTSTRAP."
echo -e "\n"


# -- Install basic packages.

echo -e "\n"
echo -e "INSTALLING BASIC PACKAGES."
echo -e "\n"

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
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends


# -- Add key for Neon repository.
# -- Add key for Nitrux repository.
# -- Add key for the Proprietary Graphics Drivers PPA.

echo -e "\n"
echo -e "ADD REPOSITORY KEYS."
echo -e "\n"

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA 1118213C 55751E5D > /dev/null


# -- Use sources.list.nitrux, sources.list.neon and sources.list.ubuntu for release.

cp -av /configs/files/sources.list.nitrux /etc/apt/sources.list
cp -av /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp -av /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-focal-repo.list
cp -av /configs/files/sources.list.neon /etc/apt/sources.list.d/neon-user-repo.list

apt -qq update


# -- Block installation of some packages.

cp /configs/files/preferences /etc/apt/preferences


# -- Install base meta-packages.

echo -e "\n"
echo -e "INSTALLING BASE SYSTEM."
echo -e "\n"

NITRUX_BASE_PACKAGES='
nitrux-hardware-drivers-legacy
nitrux-minimal-legacy
nitrux-standard-legacy
'

BASE_FILES_PKG='
base-files=11.1.2+nitrux-legacy
'

apt -yy install ${NITRUX_BASE_PACKAGES//\\n/ } --no-install-recommends
apt -yy install ${BASE_FILES_PKG//\\n/ } --allow-downgrades
apt-mark hold ${BASE_FILES_PKG//\\n/ }


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

CALAMARES_PACKAGES='
calamares
calamares-settings-nitrux
'

MISC_PACKAGES_KDE='
xdg-desktop-portal-kde=5.18.4.1-0xneon+18.04+bionic+build65
ksysguard=4:5.18.4.1-0ubuntu1
ksysguard-data=4:5.18.4.1-0ubuntu1
ksysguardd=4:5.18.4.1-0ubuntu1
libqt5webkit5=5.212.0~alpha3-5+18.04+bionic+build43
liquidshell
'


NX_DESKTOP_PKG='
nx-desktop-legacy
nx-desktop-apps-legacy
'

apt -yy install ${CALAMARES_PACKAGES//\\n/ } ${MISC_PACKAGES_KDE//\\n/ } ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- No apt usage past this point. -- #
#WARNING


# -- Install the kernel.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING KERNEL."
echo -e "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.28/linux-headers-5.4.28-050428_5.4.28-050428.202003250833_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.28/linux-headers-5.4.28-050428-generic_5.4.28-050428.202003250833_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.28/linux-image-unsigned-5.4.28-050428-generic_5.4.28-050428.202003250833_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.28/linux-modules-5.4.28-050428-generic_5.4.28-050428.202003250833_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
echo -e "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- Add MAUI Appimages

wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
chmod +x /tmp/mc
/tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
_latest=$(/tmp/mc ls nx/maui/nightly | grep -Po "\d{4}-\d{2}-\d{2}/" | sort -r | head -n 1)
mkdir maui_pkgs

(
	cd maui_pkgs
	/tmp/mc cp -r "nx/maui/nightly/$_latest" ./

	dpkg -i index-*amd64*.deb buho-*amd64*.deb nota-*amd64*.deb vvave-*amd64*.deb station-*amd64*.deb pix-*amd64*.deb mauikit-*amd64*.deb
	dpkg --configure -a
)

rm -r ./maui_pkgs
rm -r /tmp/mc


# -- Changes specific to this image. If they can be put in a package do so.
#FIXME These fixes should be included in a package.

echo -e "\n"
echo -e "ADD MISC. FIXES."
echo -e "\n"

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
/bin/cp /configs/other/org.kde.kinfocenter.desktop /usr/share/applications/org.kde.kinfocenter.desktop
/bin/cp /configs/files/kwinrc /etc/xdg/kwinrc
cp /configs/files/grub /etc/default/grub
sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/' /etc/calamares/modules/partition.conf
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitruxDark/KvNitruxDark.kvconfig
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitrux/KvNitrux.kvconfig
sed -i 's/Icon=accessories-text-editor/Icon=maui-nota/' /usr/applications/org.kde.nota.desktop


# -- Update initramfs.

echo -e "\n"
echo -e "UPDATE INITRAMFS."
echo -e "\n"

update-initramfs -u


# -- No dpkg usage past this point. -- #
#WARNING

echo -e "\n"
echo -e "EXITING BOOTSTRAP."
echo -e "\n"
