#! /bin/bash

set -x

export LANG=C
export LC_ALL=C

echo -e "\n"
echo -e "STARTING BOOTSTRAP."
echo -e "\n"


# -- Use sources.list.focal and update bionic base to focal.
# -- WARNING

echo -e "\n"
echo -e "UPDATING OS BASE."
echo -e "\n"

cp /configs/files/sources.list.focal /etc/apt/sources.list

apt update &> /dev/null
apt -yy --fix-broken install &> /dev/null
apt -yy dist-upgrade --only-upgrade --no-install-recommends &> /dev/null
apt -yy --fix-broken install &> /dev/null
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Install basic packages.

echo -e "\n"
echo -e "INSTALLING BASIC PACKAGES."
echo -e "\n"

BASIC_PACKAGES='
apt-transport-https
apt-utils
ca-certificates
casper
dhcpcd5
gnupg2
language-pack-en
language-pack-en-base
libarchive13
libelf1
localechooser-data
locales
lupin-casper
systemd-sysv
user-setup
wget
xz-utils
'

apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends &> /dev/null


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


# -- Use sources.list.build to build ISO.
# -- Block installation of libsensors4.

cp /configs/files/sources.list.base /etc/apt/sources.list
cp /configs/files/preferences /etc/apt/preferences

echo -e "\n"
echo -e "INSTALLING BASE SYSTEM."
echo -e "\n"

NITRUX_BASE_PACKAGES='
nitrux-minimal
nitrux-standard
nitrux-hardware-drivers
'

apt update &> /dev/null
apt -yy upgrade
apt -yy install ${NITRUX_BASE_PACKAGES//\\n/ } --no-install-recommends &> /dev/null
apt -yy purge --remove vlc &> /dev/null
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.desktop /etc/apt/sources.list

NX_DESKTOP_PKG='
plasma-pa=4:5.18.3-0ubuntu1
xdg-desktop-portal-kde=5.18.2-0xneon+18.04+bionic+build63
nx-desktop
'

apt update &> /dev/null
apt -yy --fix-broken install &> /dev/null
apt -yy install ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Upgrade KF5 libs for Latte Dock.

echo -e "\n"
echo -e "UPGRADING DESKTOP PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.desktop.update /etc/apt/sources.list

HOLD_KDE_PKGS='
kwin-addons
kwin-common
kwin-data
kwin-x11
libkwin4-effect-builtins1
libkwineffects12
libkwinglutils12
libkwinxrenderutils12
qml-module-org-kde-kwindowsystem
libphonon4qt5-4
'

apt update &> /dev/null
apt-mark hold ${HOLD_KDE_PKGS//\\n/ }
apt -yy upgrade --only-upgrade --no-install-recommends
apt -yy --fix-broken install
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Use sources.list.eaon to update packages and install brew and npm.
#FIXME We need to provide these packages from a repository of ours.

echo -e "\n"
echo -e "ADD BREW PACKAGE."
echo -e "\n"

cp /configs/files/sources.list.eoan /etc/apt/sources.list

ADD_BREW_PACKAGES='
linuxbrew-wrapper
'

apt update &> /dev/null
apt -yy install ${ADD_BREW_PACKAGES//\\n/ } --no-install-recommends &> /dev/null
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Use sources.list.nitrux for release.

/bin/cp /configs/files/sources.list.nitrux /etc/apt/sources.list


# -- No apt usage past this point. -- #
#WARNING


# -- Install the kernel.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING KERNEL."
echo -e "\n"

kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-headers-5.4.21-050421_5.4.21-050421.202002191431_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-headers-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-image-unsigned-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-modules-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
echo -e "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- Install Maui apps Debs.
# -- Add custom launchers for Maui apps.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING MAUI APPS."
echo -e "\n"

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

dpkg -iR /maui_debs &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /maui_debs

/bin/cp /configs/other/{org.kde.buho.desktop,org.kde.index.desktop,org.kde.nota.desktop,org.kde.pix.desktop,org.kde.station.desktop,org.kde.vvave.desktop,org.kde.contacts.desktop} /usr/share/applications
whereis index buho nota vvave station pix contacts


# -- Install bup and kup-backup.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING KUP."
echo -e "\n"

kup_bup_pkgs='
http://mirrors.kernel.org/ubuntu/pool/universe/k/kup-backup/kup-backup_0.7.1+dfsg-1build2_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/bup_0.29-3_amd64.modfied.deb
'

mkdir /bup_debs

for x in $kup_bup_pkgs; do
	wget -q -P /bup_debs $x
done

dpkg -iR /bup_debs &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /bup_debs


# -- Add missing firmware modules.
#FIXME These files should be included in a package.

echo -e "\n"
echo -e "ADDING MISSING FIRMWARE."
echo -e "\n"

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
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/znx-master-x86_64.AppImage
https://github.com/Nitrux/znx-gui/releases/download/continuous-stable/znx-gui_master-x86_64.AppImage
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/appimage-cli-tool-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/pnx-1.0.0-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/Binaries/vmetal-free-amd64
https://github.com/ferion11/Proton_Appimage/releases/download/continuous/proton-linux-x86-v4.2-PlayOnLinux-x86_64.AppImage
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
'

APPS_USR='
https://libreoffice.soluzioniopen.com/stable/fresh/LibreOffice-fresh.basic-x86_64.AppImage
https://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/waterfox-classic-latest-x86_64.AppImage
https://files.kde.org/kdenlive/release/kdenlive-19.12.3-x86_64.appimage
https://github.com/aferrero2707/gimp-appimage/releases/download/continuous/GIMP_AppImage-git-2.10.19-20200227-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/mpv-0.32.0-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/Inkscape-0.92.3+68.glibc2.15-x86_64.AppImage
https://github.com/LMMS/lmms/releases/download/v1.2.1/lmms-1.2.1-linux-x86_64.AppImage
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

mv /Applications/znx-master-x86_64.AppImage /Applications/znx
mv /Applications/znx-gui_master-x86_64.AppImage /Applications/znx-gui
mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/appimageupdate
mv /Applications/appimage-cli-tool-x86_64.AppImage /Applications/app
mv /Applications/pnx-1.0.0-x86_64.AppImage /Applications/pnx
mv /Applications/vmetal-free-amd64 /Applications/vmetal
mv /Applications/proton-linux-x86-v4.2-PlayOnLinux-x86_64.AppImage /Applications/wine

ln -sv /Applications/wine /Applications/wineserver

mv /Applications/appimaged-x86_64.AppImage /etc/skel/.local/bin/appimaged

mv /Applications/LibreOffice-fresh.basic-x86_64.AppImage /Applications/libreoffice
mv /Applications/waterfox-classic-latest-x86_64.AppImage /Applications/waterfox
mv /Applications/kdenlive-19.12.3-x86_64.appimage /Applications/kdenlive
mv /Applications/GIMP_AppImage-git-2.10.19-20200227-x86_64.AppImage /Applications/gimp
mv /Applications/mpv-0.30.0-x86_64.AppImage /Applications/mpv
mv /Applications/Inkscape-0.92.3+68.glibc2.15-x86_64.AppImage /Applications/inkscape
mv /Applications/lmms-1.2.1-linux-x86_64.AppImage /Applications/lmms

ls -l /Applications
ls -l /etc/skel/.local/bin/


# -- Add AppImage providers for appimage-cli-tool

echo -e "\n"
echo -e "ADD APPIMAGE PROVIDERS."
echo -e "\n"

cp /configs/files/appimage-providers.yaml /etc/


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add policykit file for KDialog.
# -- Add VMetal desktop launcher.
# -- Add appimaged launcher to autostart.
# -- Overwrite Qt settings file. This file was IN a package but caused installation conflicts with kio-extras.
# -- Overwrite Plasma 5 notification positioning. This file was IN a package but caused installation conflicts with plasma-workspace.
# -- For a strange reason, the Breeze cursors override some of our cursor assets. Delete them from the system to avoid this.
# -- Add Window title plasmoid.
# -- Add welcome wizard to app menu.
# -- Waterfox-current AppImage is missing an icon the menu, add it for the default user.
# -- Delete KDE Connect unnecessary menu entries.
# -- Add znx-gui desktop launcher.
# -- Remove Kinfocenter desktop launcher. The SAME package installs both, the KCM AND the standalone app (why?).
# -- Remove htop and nsnake desktop launcher.
# -- Remove ibus-setup desktop launcher and the flipping emojier launcher.
#FIXME These fixes should be in a package.

echo -e "\n"
echo -e "ADD MISC. FIXES."
echo -e "\n"

cp /configs/files/sddm.conf /etc
cp /configs/files/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/other/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
cp /configs/files/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/
cp /configs/other/vmetal.desktop /usr/share/applications
cp /configs/other/appimagekit-appimaged.desktop /etc/skel/.config/autostart/
/bin/cp /configs/files/Trolltech.conf /etc/xdg/Trolltech.conf
/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
rm -R /usr/share/icons/breeze_cursors /usr/share/icons/Breeze_Snow
cp -a /configs/other/org.kde.windowtitle /usr/share/plasma/plasmoids
cp -a /configs/other/org.kde.video /usr/share/plasma/wallpapers
cp /configs/other/nx-welcome-wizard.desktop /usr/share/applications
mkdir -p /etc/skel/.local/share/icons/hicolor/128x128/apps
rm /usr/share/applications/org.kde.kdeconnect.sms.desktop /usr/share/applications/org.kde.kdeconnect_open.desktop /usr/share/applications/org.kde.kdeconnect.app.desktop
cp /configs/other/znx-gui.desktop /usr/share/applications
/bin/cp /configs/other/org.kde.kinfocenter.desktop /usr/share/applications/org.kde.kinfocenter.desktop
rm /usr/share/applications/htop.desktop /usr/share/applications/mc.desktop /usr/share/applications/mcedit.desktop /usr/share/applications/nsnake.desktop
ln -sv /usr/games/nsnake /bin/nsnake
rm /usr/share/applications/ibus-setup* /usr/share/applications/org.freedesktop.IBus* /usr/share/applications/org.kde.plasma.emojier.desktop /usr/share/applications/info.desktop


# -- Workarounds for PNX.
#FIXME These need to be fixed in PNX.

echo -e "\n"
echo -e "ADD WORKAROUNDS FOR PNX."
echo -e "\n"

mkdir -p /var/lib/pacman/
mkdir -p /etc/pacman.d/
mkdir -p /usr/share/pacman/keyrings

cp /configs/files/pacman.conf /etc
cp /configs/files/mirrorlist /etc/pacman.d
cp -r /configs/other/pacman/* /usr/share/pacman/keyrings

ln -sv /home/.pnx/usr/lib/dri /usr/lib/dri
ln -sv /home/.pnx/usr/lib/pulseaudio /usr/lib/pulseaudio
ln -sv /home/.pnx/usr/lib/gdk-pixbuf-2.0 /usr/lib/gdk-pixbuf-2.0
ln -sv /home/.pnx/usr/lib/gs-plugins-13 /usr/lib/gs-plugins-13
ln -sv /home/.pnx/usr/lib/liblmdb.so /usr/lib/liblmdb.so
ln -sv /home/.pnx/usr/lib/systemd /usr/lib/systemd
ln -sv /home/.pnx/usr/lib/samba /usr/lib/samba
ln -sv /home/.pnx/usr/lib/girepository-1.0 /usr/lib/girepository-1.0
ln -sv /home/.pnx/usr/lib/tracker-2.0 /usr/lib/tracker-2.0
ln -sv /home/.pnx/usr/lib/WebKitNetworkProcess /usr/lib/WebKitNetworkProcess
ln -sv /home/.pnx/usr/lib/epiphany /usr/lib/epiphany
ln -sv /home/.pnx/usr/lib/opera /usr/lib/opera
ln -sv /home/.pnx/usr/lib/firefox /usr/lib/firefox
ln -sv /home/.pnx/usr/share/tracker /usr/share/tracker
ln -sv /home/.pnx/usr/share/xonotic /usr/share/xonotic

mkdir -p /usr/lib/zsh/5.8/zsh/

ln -sv /home/.pnx/usr/lib/zsh/5.8/zsh/datetime.so /usr/lib/zsh/5.8/zsh/datetime.so


# -- Add vfio modules and files.
#FIXME This configuration should be included a in a package; replacing the default package like base-files.

echo -e "\n"
echo -e "ADD VFIO ENABLEMENT AND CONFIGURATION."
echo -e "\n"

echo "install vfio-pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "install vfio_pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep amdgpu pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep radeon pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep i915 pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "vfio" >> /etc/initramfs-tools/modules
echo "vfio_iommu_type1" >> /etc/initramfs-tools/modules
echo "vfio_virqfd" >> /etc/initramfs-tools/modules
echo "options vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci" >> /etc/initramfs-tools/modules
echo "nvidia" >> /etc/initramfs-tools/modules
echo "amdgpu" >> /etc/initramfs-tools/modules
echo "radeon" >> /etc/initramfs-tools/modules
echo "i915" >> /etc/initramfs-tools/modules

echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_pci ids=" >> /etc/modules

cp /configs/files/asound.conf /etc/
cp /configs/files/asound.conf /etc/skel/.asoundrc
cp /configs/files/iommu_unsafe_interrupts.conf /etc/modprobe.d/
cp /configs/files/{amdgpu.conf,i915.conf,kvm.conf,nvidia.conf,qemu-system-x86.conf,radeon.conf,vfio_pci.conf,vfio-pci.conf} /etc/modprobe.d/
cp /configs/scripts/{vfio-pci-override-vga.sh,dummy.sh} /bin/

chmod +x /bin/dummy.sh


# -- Add itch.io store launcher.
#FIXME This should be in a package.

echo -e "\n"
echo -e "ADD ITCH.IO LAUNCHER."
echo -e "\n"


mkdir -p /etc/skel/.local/share/applications
cp /configs/other/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/scripts/install-itch-io.sh /etc/skel/.config


# -- Add configuration for npm to install packages in home and without sudo and update it.
# -- Delete 'travis' folder that holds npm cache during build.
#FIXME This should be in a package.

echo -e "\n"
echo -e "ADD NPM INSTALL WITHOUT SUDO AND UPDATE IT."
echo -e "\n"

mkdir /etc/skel/.npm-packages
cp /configs/files/npmrc /etc/skel/.npmrc
npm install npm@latest -g
rm -r /home/travis


# -- Add nativefier launcher.
#FIXME This should be in a package.

echo -e "\n"
echo -e "ADD NATIVEFIER LAUNCHER."
echo -e "\n"


cp /configs/other/install.nativefier.desktop /etc/skel/.config/autostart/
cp /configs/scripts/install-nativefier.sh /etc/skel/.config


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
#FIXME This should be put in a package.

echo -e "\n"
echo -e "DECREASE TIMEOUT FOR SYSTEMD SERVICES."
echo -e "\n"

sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf


# -- Disable systemd services not deemed necessary.
# -- use 'mask' to fully disable them.

echo -e "\n"
echo -e "DISABLE SYSTEMD SERVICES."
echo -e "\n"

systemctl mask avahi-daemon.service
systemctl disable cupsd.service cupsd-browsed.service NetworkManager-wait-online.service keyboard-setup.service


# -- Fix for broken udev rules (yes, it is broken by default).
#FIXME This should be put in a package.

sed -i 's/ACTION!="add", GOTO="libmtp_rules_end"/ACTION!="bind", ACTION!="add", GOTO="libmtp_rules_end"/g' /lib/udev/rules.d/69-libmtp.rules


# -- Strip kernel modules.
# -- Use GZIP compression when creating the initramfs.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.
# -- Add znx_dev_uuid parameter.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "UPDATE INITRAMFS."
echo -e "\n"

find /lib/modules/5.4.21-050421-generic/ -iname "*.ko" -exec strip --strip-unneeded {} \;
cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan

update-initramfs -u
lsinitramfs /boot/initrd.img-5.4.21-050421-generic | grep vfio

rm /bin/dummy.sh


# -- Remove APT.
# -- Update package index using cupt.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "REMOVE APT."
echo -e "\n"

REMOVE_APT='
apt
apt-utils
apt-transport-https
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_APT//\\n/ } &> /dev/null


# -- Clean the filesystem.

echo -e "\n"
echo -e "REMOVE CASPER."
echo -e "\n"

REMOVE_PACKAGES='
casper
lupin-casper
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_PACKAGES//\\n/ } &> /dev/null


# -- No dpkg usage past this point. -- #
#WARNING


# -- Use script to remove dpkg.

echo -e "\n"
echo -e "REMOVE DPKG."
echo -e "\n"

/configs/scripts/./rm-dpkg.sh
rm /configs/scripts/rm-dpkg.sh


echo -e "\n"
echo -e "EXITING BOOTSTRAP."
echo -e "\n"
