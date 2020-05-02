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

wget -q https://archive.neon.kde.org/public.key -O neon.key
echo -e "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
apt-key add neon.key > /dev/null
rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA 1118213C > /dev/null


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


# -- Install liquidshell.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING LIQUIDSHELL."
echo -e "\n"


liquidshell_deb='
https://github.com/UriHerrera/storage/raw/master/Debs/apps/liquidshell_1.5-nxos-1_amd64.deb
'

mkdir /liquidshell_files

for x in $liquidshell_deb; do
echo -e "$x"
    wget -q -P /liquidshell_files $x
done

dpkg -iR /liquidshell_files &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /liquidshell_files


echo -e "\n"
echo -e "ADD LIQUIDSHELL CONFIG."
echo -e "\n"

cp /configs/scripts/startliquidshell.sh /bin/startliquidshell


# -- Add missing firmware modules.
#FIXME These files should be included in a package.

echo -e "\n"
echo -e "ADDING MISSING FIRMWARE."
echo -e "\n"

fw='
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/vega20_ta.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/bxt_huc_ver01_8_2893.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/tgl_dmc_ver2_04.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/raven_kicker_rlc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_asd.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_ce.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_gpu_info.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_me.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_mec.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_mec2.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_pfp.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_rlc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_sdma.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_sdma1.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_smc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_sos.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi10_vcn.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_asd.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_ce.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_ce_wks.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_gpu_info.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_me.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_me_wks.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_mec.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_mec_wks.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_mec2.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_mec2_wks.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_pfp.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_pfp_wks.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_rlc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_sdma.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_sdma1.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_smc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_sos.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/navi14_vcn.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_asd.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_ce.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_gpu_info.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_me.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_mec.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_mec2.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_pfp.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_rlc.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_sdma.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/renoir_vcn.bin
'

mkdir /fw_files

for x in $fw; do
    wget -q -P /fw_files $x
done

cp /fw_files/{vega20_ta.bin,raven_kicker_rlc.bin,navi10_*.bin,navi14*_.bin,renoir_*.bin} /lib/firmware/amdgpu/
cp /fw_files/{bxt_huc_ver01_8_2893.bin,tgl_dmc_ver2_04.bin} /lib/firmware/i915/

rm -r /fw_files


# -- Add appimage-installer.

echo -e "\n"
echo -e "ADDING APPIMAGE-INSTALLER."
echo -e "\n"


app_deb='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/appimage-installer_1.0.2-ubuntu-bionic-git20191214.b4fc9bf_amd64.deb
'

mkdir /appimage_installer

for x in $app_deb; do
echo -e "$x"
    wget -q -P /appimage_installer $x
done

dpkg -iR /appimage_installer &> /dev/null
dpkg --configure -a &> /dev/null
apt -yy --fix-broken install
rm -r /appimage_installer


# -- Add /Applications to $PATH.

echo -e "\n"
echo -e "ADD /APPLICATIONS TO PATH."
echo -e "\n"

echo -e "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add system AppImages.
# -- Create /Applications directory for users.
# -- Rename AppImages for easy access from the terminal.

echo -e "\n"
echo -e "ADD APPIMAGES."
echo -e "\n"

APPS_SYS='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
'

APPS_USR='
'

mkdir -p /Applications
mkdir -p /etc/skel/Applications
mkdir -p /etc/skel/.local/bin

for x in $APPS_SYS; do
    wget -q -P /Applications $x
done

for x in $APPS_USR; do
    wget -q -P /Applications $x
done

chmod +x /Applications/*

mv /Applications/appimaged-x86_64.AppImage /etc/skel/.local/bin/appimaged

ls -l /etc/skel/.local/bin/


# -- Changes specific to this image. If they cna be put in a package do so.
#FIXME These fixes should be included in a package.

echo -e "\n"
echo -e "ADD MISC. FIXES."
echo -e "\n"

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
/bin/cp /configs/other/org.appimage.user-tool.desktop /usr/share/applications/org.appimage.user-tool.desktop 
/bin/cp /configs/other/org.kde.kinfocenter.desktop /usr/share/applications/org.kde.kinfocenter.desktop
/bin/cp /configs/files/kwinrc /etc/xdg/kwinrc
cp /configs/files/grub /etc/default/grub
sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/' /etc/calamares/modules/partition.conf
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitruxDark/KvNitruxDark.kvconfig
sed -i 's/translucent_windows=true/translucent_windows=false/' /usr/share/Kvantum/KvNitrux/KvNitrux.kvconfig


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
