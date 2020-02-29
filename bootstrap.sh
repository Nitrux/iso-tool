#! /bin/bash

set -x

printf "\n"
printf "STARTING BOOTSTRAP."
printf "\n"


# -- Install basic packages.

printf "\n"
printf "INSTALLING BASIC PACKAGES."
printf "\n"

BASIC_PACKAGES='
apt-transport-https
apt-utils
btrfs-progs
btrfs-tools
ca-certificates
casper
dhcpcd5
fuse
gnupg2
grub-pc-bin
language-pack-en
language-pack-en-base
libarchive13
libelf1
localechooser-data
locales
lupin-casper
network-manager
shim
shim-signed
squashfs-tools
user-setup
wget
xz-utils
'

apt update &> /dev/null
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends


# -- Add key for our repository.
# -- Add key for the Proprietary Graphics Drivers PPA.

printf "\n"
printf "ADD REPOSITORY KEYS."
printf "\n"

wget -q https://archive.neon.kde.org/public.key -O neon.key
	printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
	apt-key add neon.key > /dev/null
	rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null


# -- Use sources.list.focal to install kvantum.
#FIXME We need to provide these packages from a repository of ours.

cp /configs/files/sources.list.focal /etc/apt/sources.list

printf "\n"
printf "INSTALLING KVANTUM AND GLIB."
printf "\n"

UPDATE_LIBC_KVANTUM='
fuse3
gcc-10-base
libc-bin
libc-dev-bin
libc6
libc6-dev
libfuse3-3
libgcc-s1
libgcc1
linux-libc-dev
locales
qt5-style-kvantum
qt5-style-kvantum-themes
'

apt update &> /dev/null
apt download ${UPDATE_LIBC_KVANTUM//\\n/ } --no-install-recommends
dpkg --force-all -i *.deb
rm *.deb
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Use sources.list.build to build ISO.

cp /configs/files/sources.list.build /etc/apt/sources.list


# -- Update packages list and install packages.

printf "\n"
printf "INSTALLING DESKTOP."
printf "\n"

DESKTOP_PACKAGES='
nitrux-minimal-legacy
nitrux-standard-legacy
nitrux-hardware-drivers-legacy
nx-desktop-legacy
'

CALAMARES_PACKAGES='
calamares
calamares-settings-nitrux
'

MISC_PACKAGES_BIONIC='
kdenlive
partitionmanager
'

BASE_FILES_PKG='
base-files=11.0.98.6+nitrux-legacy
'

apt update &> /dev/null
apt -yy --fix-broken install
apt -yy upgrade
apt -yy install ${DESKTOP_PACKAGES//\\n/ } ${CALAMARES_PACKAGES//\\n/ } ${MISC_PACKAGES_BIONIC//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt -yy purge --remove vlc
apt -yy dist-upgrade
apt -yy install ${BASE_FILES_PKG//\\n/ } --allow-downgrades
apt -yy autoremove
apt-mark hold ${BASE_FILES_PKG//\\n/ }
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Install liquidshell.
#FIXME This should be synced to our repository.

printf "\n"
printf "INSTALLING LIQUIDSHELL."
printf "\n"


liquidshell_deb='
https://github.com/UriHerrera/storage/raw/master/Debs/apps/liquidshell_1.5-nxos-1_amd64.deb
'

mkdir /liquidshell_files

for x in $liquidshell_deb; do
printf "$x"
    wget -q -P /liquidshell_files $x
done

dpkg -iR /liquidshell_files &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /liquidshell_files


printf "\n"
printf "ADD LIQUIDSHELL CONFIG."
printf "\n"

cp /configs/scripts/startliquidshell.sh /bin/startliquidshell
mkdir -p /usr/share/liquidshell/style/
cp /configs/files/{stylesheet-light.qss,stylesheet-dark.qss} /usr/share/liquidshell/style/
cp /configs/files/liquidshellrc /etc/skel/.config/
cp /configs/other/org.kde.liquidshell.desktop /etc/skel/.config/autostart


# -- Install modified bup deb package.
#FIXME This should be synced to our repository.

bup_deb='
https://github.com/UriHerrera/storage/raw/master/Debs/apps/bup_0.29-3_amd64.modfied.deb
'

mkdir /bup_pkg

for x in $bup_deb; do
printf "$x"
    wget -q -P /bup_pkg $x
done

dpkg -iR /bup_pkg
dpkg --configure -a &> /dev/null
rm -r /bup_pkg


# -- Use sources.list.focal to update packages

printf "\n"
printf "UPDATE BASE PACKAGES."
printf "\n"

cp /configs/files/sources.list.focal /etc/apt/sources.list

UPGRADE_OS_PACKAGES='
broadcom-sta-dkms
dkms
exfat-fuse
exfat-utils
firefox
firejail
firejail-profiles
go-mtpfs
grub-common
grub-efi-amd64-bin
grub-efi-amd64-signed
grub-pc-bin
grub2-common
i965-va-driver
initramfs-tools
initramfs-tools-bin
initramfs-tools-core
libc6
libdrm-amdgpu1
libdrm-intel1
libdrm-radeon1
libmagic1
libva-drm2
libva-glx2
libva-x11-2
libva2
linux-firmware
mesa-va-drivers
mesa-vdpau-drivers
mesa-vulkan-drivers
mpv
openresolv
openssh-client
openssl
shim
shim-signed
sudo
thunderbolt-tools
x11-session-utils
xinit
xserver-xorg
xserver-xorg-core
xserver-xorg-input-evdev
xserver-xorg-input-libinput
xserver-xorg-input-mouse
xserver-xorg-input-synaptics
xserver-xorg-input-wacom
xserver-xorg-video-amdgpu
xserver-xorg-video-intel
xserver-xorg-video-qxl
xserver-xorg-video-radeon
xserver-xorg-video-vmware
'

ADD_MISC_PACKAGES='
calamares-settings-ubuntu-common
firejail
firejail-profiles
gimp
gnome-keyring
inkscape
libc6-dev
libc6-i386
libslirp0
libreoffice
lmms
plasma-discover
plasma-discover-backend-flatpak
plasma-discover-backend-snap
'

apt update &> /dev/null
apt -yy install ${UPGRADE_OS_PACKAGES//\\n/ } --only-upgrade --no-install-recommends
apt -yy install ${ADD_MISC_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Upgrade KDE packages for latte.

cp /configs/files/sources.list.build.update /etc/apt/sources.list

HOLD_KWIN_PKGS='
kwin-addons 
kwin-common
kwin-data
kwin-x11
libkwin4-effect-builtins1
libkwineffects12
libkwinglutils12
libkwinxrenderutils12
qml-module-org-kde-kwindowsystem
'

apt update &> /dev/null
apt-mark hold  ${HOLD_KWIN_PKGS//\\n/ }
apt -yy upgrade --only-upgrade --no-install-recommends
apt -yy --fix-broken install
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- No apt usage past this point. -- #
#WARNING


# -- Install the kernel.
#FIXME This should be synced to our repository.

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.23/linux-headers-5.4.23-050423_5.4.23-050423.202002281329_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.23/linux-headers-5.4.23-050423-generic_5.4.23-050423.202002281329_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.23/linux-image-unsigned-5.4.23-050423-generic_5.4.23-050423.202002281329_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.23/linux-modules-5.4.23-050423-generic_5.4.23-050423.202002281329_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
printf "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- Install Maui apps Debs.
# -- Add custom launchers for Maui apps.
#FIXME This should be synced to our repository.

printf "\n"
printf "INSTALLING MAUI APPS."
printf "\n"

mauipkgs='
https://raw.githubusercontent.com/mauikit/release-pkgs/master/mauikit/mauikit-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/buho/buho-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/contacts/contacts-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/index/index-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/nota/nota-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/pix/pix-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/station/station-1.0.0-Linux.deb
https://raw.githubusercontent.com/mauikit/release-pkgs/master/vvave/vvave-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/libs/qml-module-qmltermwidget_0.1+git20180903-1_amd64.deb
'

mkdir /maui_debs

for x in $mauipkgs; do
	wget -q -P /maui_debs $x
done

dpkg -iR /maui_debs
dpkg --configure -a
rm -r /maui_debs

/bin/cp /configs/other/{org.kde.buho.desktop,org.kde.index.desktop,org.kde.nota.desktop,org.kde.pix.desktop,org.kde.station.desktop,org.kde.vvave.desktop,org.kde.contacts.desktop} /usr/share/applications
whereis index buho nota vvave station pix contacts


# -- Add missing firmware modules.
#FIXME These files should be included in a package.

printf "\n"
printf "ADDING MISSING FIRMWARE."
printf "\n"

fw='
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/vega20_ta.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/bxt_huc_ver01_8_2893.bin
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

cp /fw_files/{vega20_ta.bin,raven_kicker_rlc.bin,navi10_*.bin,renoir_*.bin} /lib/firmware/amdgpu/
cp /fw_files/bxt_huc_ver01_8_2893.bin /lib/firmware/i915/

rm -r /fw_files

ls -l /lib/firmware/amdgpu/


# -- Add appimage-installer.

printf "\n"
printf "ADDING APPIMAGE-INSTALLER."
printf "\n"


app_deb='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/appimage-installer_1.0.2-ubuntu-bionic-git20191214.b4fc9bf_amd64.deb
'

mkdir /appimage_installer

for x in $app_deb; do
printf "$x"
    wget -q -P /appimage_installer $x
done

dpkg -iR /appimage_installer &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /appimage_installer


# -- Add /Applications to $PATH.

printf "\n"
printf "ADD /APPLICATIONS TO PATH."
printf "\n"

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add system AppImages.
# -- Create /Applications directory for users.
# -- Rename AppImages for easy access from the terminal.

printf "\n"
printf "ADD APPIMAGES."
printf "\n"

APPS_SYS='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
'

APPS_USR='
'

mkdir /Applications
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

printf "\n"
printf "ADD APPIMAGE PROVIDERS."
printf "\n"

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
# -- Add stanza for APT to prevent the installation of dash.
#FIXME These fixes should be included in a package.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

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
rm /usr/share/applications/ibus-setup* /usr/share/applications/org.kde.plasma.emojier.desktop
cp /configs/files/preferences /etc/apt/preferences


# -- Add itch.io store launcher.
#FIXME This should be in a package.

printf "\n"
printf "ADD ITCH.IO LAUNCHER."
printf "\n"


mkdir -p /etc/skel/.local/share/applications
cp /configs/other/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/scripts/install-itch-io.sh /etc/skel/.config


# -- Add oh my zsh.
#FIXME This should be put in a package.

printf "\n"
printf "ADD OH MY ZSH."
printf "\n"

git clone https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh


# -- Remove dash and use mksh as /bin/sh.
# -- Use zsh as default shell for all users.
#FIXME This should be put in a package.

printf "\n"
printf "REMOVE DASH AND USE MKSH + ZSH."
printf "\n"

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
/bin/cp /configs/files/sources.list.ubuntu /etc/apt/sources.list.d/ubuntu-repos.list
/bin/cp /configs/files/sources.list.neon /etc/apt/sources.list.d/neon-repos.list

apt update &> /dev/null


# -- Update initramfs.


printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

update-initramfs -u


# -- No dpkg usage past this point. -- #
#WARNING

printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
