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

cp /configs/files/sources.list.bionic /etc/apt/sources.list

BASIC_PACKAGES='
apt-transport-https
apt-utils
btrfs-progs
ca-certificates
casper
dhcpcd5
fuse
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
wget
xz-utils
usrmerge
'

apt update
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

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null


# -- Use sources.list.base to build ISO.
# -- Block installation of libsensors4.

cp /configs/files/sources.list.base /etc/apt/sources.list

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

apt update
apt -yy install ${NITRUX_BASE_PACKAGES//\\n/ } --no-install-recommends
apt -yy install ${BASE_FILES_PKG//\\n/ } --allow-downgrades
apt-mark hold ${BASE_FILES_PKG//\\n/ }


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.desktop /etc/apt/sources.list

CALAMARES_PACKAGES='
calamares
calamares-settings-nitrux
cryptsetup
cryptmount
lvm2
'

MISC_PACKAGES_KDE='
kdenlive
partitionmanager
plasma-discover
plasma-discover-backend-flatpak
plasma-discover-backend-snap
'

OTHER_MISC_PKGS='
firefox
inkscape
lmms
gimp
libreoffice
'

NX_DESKTOP_PKG='
nx-desktop-legacy
'

apt update
apt -yy --fix-broken install
apt -yy install ${CALAMARES_PACKAGES//\\n/ } ${MISC_PACKAGES_KDE//\\n/ } ${OTHER_MISC_PKGS//\\n/ } ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends
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
mkdir -p /usr/share/liquidshell/style/
cp /configs/files/{stylesheet-light.qss,stylesheet-dark.qss} /usr/share/liquidshell/style/
cp /configs/files/liquidshellrc /etc/skel/.config/
cp /configs/other/org.kde.liquidshell.desktop /etc/skel/.config/autostart


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


# -- Add AppImage providers for appimage-cli-tool

echo -e "\n"
echo -e "ADD APPIMAGE PROVIDERS."
echo -e "\n"

cp /configs/files/appimage-providers.yaml /etc/


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Overwrite Qt settings file. This file was IN a package but caused installation conflicts with kio-extras.
# -- Overwrite Plasma 5 notification positioning. This file was IN a package but caused installation conflicts with plasma-workspace.
# -- For a strange reason, the Breeze cursors override some of our cursor assets. Delete them from the system to avoid this.
# -- Delete Calamares default desktop launcher.
# -- Replace appimage-installer.desktop file.
# -- Delete KDE Connect unnecessary menu entries.
# -- Remove Kinfocenter desktop launcher. The SAME package installs both, the KCM AND the standalone app (why?).
# -- Remove htop and nsnake desktop launcher.
# -- Remove ibus-setup desktop launcher and the flipping emojier launcher.
# -- Enable GRUB parameter for disk encryption with Calamares.
# -- Hide ecnryption checkbox from Calamares UI.
# -- Add Maui app launchers.
#FIXME These fixes should be included in a package.

echo -e "\n"
echo -e "ADD MISC. FIXES."
echo -e "\n"

cp /configs/files/sddm.conf /etc
cp /configs/files/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
/bin/cp /configs/files/Trolltech.conf /etc/xdg/Trolltech.conf
/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
rm -R /usr/share/icons/breeze_cursors /usr/share/icons/Breeze_Snow
rm /usr/share/applications/calamares.desktop
/bin/cp /configs/other/org.appimage.user-tool.desktop /usr/share/applications/org.appimage.user-tool.desktop
rm /usr/share/applications/org.kde.kdeconnect.sms.desktop /usr/share/applications/org.kde.kdeconnect_open.desktop /usr/share/applications/org.kde.kdeconnect.app.desktop
/bin/cp /configs/other/org.kde.kinfocenter.desktop /usr/share/applications/org.kde.kinfocenter.desktop
rm /usr/share/applications/htop.desktop /usr/share/applications/mc.desktop /usr/share/applications/mcedit.desktop /usr/share/applications/nsnake.desktop
ln -sv /usr/games/nsnake /bin/nsnake
rm /usr/share/applications/ibus-setup* /usr/share/applications/org.freedesktop.IBus* /usr/share/applications/org.kde.plasma.emojier.desktop /usr/share/applications/info.desktop
cp /configs/files/grub /etc/default/grub
sed -i 's/enableLuksAutomatedPartitioning: true/enableLuksAutomatedPartitioning: false/+g' /etc/calamares/modules/partition.conf
/bin/cp /configs/other/{org.kde.buho.desktop,org.kde.index.desktop,org.kde.nota.desktop,org.kde.pix.desktop,org.kde.station.desktop,org.kde.vvave.desktop,org.kde.contacts.desktop} /usr/share/applications


# -- Add itch.io store launcher.
#FIXME This should be in a package.

echo -e "\n"
echo -e "ADD ITCH.IO LAUNCHER."
echo -e "\n"


mkdir -p /etc/skel/.local/share/applications
cp /configs/other/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/scripts/install-itch-io.sh /etc/skel/.config


# -- Add oh my zsh.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "ADD OH MY ZSH."
echo -e "\n"

git clone https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh


# -- Remove dash and use mksh as /bin/sh.
# -- Use zsh as default shell for all users.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "REMOVE DASH AND USE MKSH + ZSH."
echo -e "\n"

rm /bin/sh.distrib
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null
ln -sv /bin/mksh /bin/sh
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null

sed -i 's+SHELL=/bin/sh+SHELL=/bin/zsh+g' /etc/default/useradd
sed -i 's+DSHELL=/bin/bash+DSHELL=/bin/zsh+g' /etc/adduser.conf


# -- Decrease timeout for systemd start and stop services.
# -- Decrease the time to "raise a network interface". Default is FIVE MINUTES!?.
#FIXME This should be put in a package.

sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf

mkdir -p /etc/systemd/system/networking.service.d/
bash -c 'echo -e "[Service]\nTimeoutStartSec=20sec" > /etc/systemd/system/networking.service.d/timeout.conf'


# -- Disable systemd services not deemed necessary.
# -- use 'mask' to fully disable them.

systemctl mask avahi-daemon.service
systemctl disable cupsd.service cupsd-browsed.service NetworkManager-wait-online.service keyboard-setup.service


# -- Fix for broken udev rules (yes, it is broken by default).
#FIXME This should be put in a package.

sed -i 's/ACTION!="add", GOTO="libmtp_rules_end"/ACTION!="bind", ACTION!="add", GOTO="libmtp_rules_end"/g' /lib/udev/rules.d/69-libmtp.rules


# -- Use sources.list.nitrux, sources.list.neon and sources.list.ubuntu for release.

/bin/cp /configs/files/sources.list.nitrux /etc/apt/sources.list
/bin/cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-repos.list
/bin/cp /configs/files/sources.list.neon /etc/apt/sources.list.d/neon-repos.list

apt update &> /dev/null


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
