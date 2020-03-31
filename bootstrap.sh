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
fuse3
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
usrmerge
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


# -- Install bup.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING BUP."
echo -e "\n"

cp /configs/files/sources.list.focal /etc/apt/sources.list

bup_deb_pkg='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/bup_0.29-3_amd64.modfied.deb
'

mkdir /bup_debs

for x in $bup_deb_pkg; do
	wget -P /bup_debs $x
done

apt update &> /dev/null 
dpkg -iR /bup_debs
apt -yy --fix-broken install
dpkg --configure -a
rm -r /bup_debs


# -- Use sources.list.base to build ISO.
# -- Block installation of libsensors4.

cp /configs/files/sources.list.base /etc/apt/sources.list
cp /configs/files/preferences /etc/apt/preferences

echo -e "\n"
echo -e "INSTALLING BASE SYSTEM."
echo -e "\n"

NITRUX_BASE_PACKAGES='
nitrux-hardware-drivers-legacy
nitrux-minimal-legacy
nitrux-standard-legacy
'

BASE_FILES_PKG='
base-files=11.1.0+nitrux-legacy
'

apt update &> /dev/null
apt -yy upgrade &> /dev/null
apt -yy install ${NITRUX_BASE_PACKAGES//\\n/ } --no-install-recommends &> /dev/null
apt -yy install ${BASE_FILES_PKG//\\n/ } --allow-downgrades &> /dev/null
apt-mark hold ${BASE_FILES_PKG//\\n/ }
apt -yy autoremove
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.desktop /etc/apt/sources.list

CALAMARES_PACKAGES='
calamares
calamares-settings-nitrux
cryptsetup
'

MISC_PACKAGES_KDE='
kdenlive
libqt5webkit5=5.212.0~alpha3-5+18.04+bionic+build42
partitionmanager
plasma-discover
plasma-discover-backend-flatpak
plasma-discover-backend-snap
plasma-pa=4:5.18.3-0ubuntu1
xdg-desktop-portal-kde=5.18.2-0xneon+18.04+bionic+build63
ksysguard=4:5.18.3-0ubuntu1
ksysguard-data=4:5.18.3-0ubuntu1
ksysguardd=4:5.18.3-0ubuntu1
'

NX_DESKTOP_PKG='
nx-desktop-legacy
'

apt update &> /dev/null
apt -yy --fix-broken install
apt -yy install ${CALAMARES_PACKAGES//\\n/ } ${MISC_PACKAGES_KDE//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt -yy install ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends
apt -yy purge --remove vlc &> /dev/null
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
libphonon4qt5-4
qml-module-org-kde-kwindowsystem
'

UPD_KDE_PKGS='
ark
kcalc
kde-spectacle
kdeconnect
kmenuedit
kscreen
latte-dock=0.9.9+p18.04+git20200328.0224-0
libkf5activities5
libkf5activitiesstats1
libkf5archive5
libkf5attica5
libkf5auth-data
libkf5auth5
libkf5authcore5
libkf5baloo5
libkf5balooengine5
libkf5bluezqt-data
libkf5bluezqt6
libkf5bookmarks-data
libkf5bookmarks5
libkf5calendarevents5
libkf5codecs-data
libkf5codecs5
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
libkf5kcmutils-data
libkf5kcmutils5
libkf5kdelibs4support-data
libkf5kdelibs4support5
libkf5kiocore5
libkf5kiofilewidgets5
libkf5kiogui5
libkf5kiontlm5
libkf5kiowidgets5
libkf5kipi-data
libkf5kipi32.0.0
libkf5kirigami2-5
libkf5modemmanagerqt6
libkf5networkmanagerqt6
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
libkf5people-data
libkf5people5
libkf5peoplebackend5
libkf5peoplewidgets5
libkf5plasma5
libkf5plasmaquick5
libkf5prison5
libkf5pty-data
libkf5pty5
libkf5pulseaudioqt2
libkf5purpose-bin
libkf5purpose5
libkf5quickaddons5
libkf5runner5
libkf5service-bin
libkf5service-data
libkf5service5
libkf5solid5
libkf5solid5-data
libkf5sonnet5-data
libkf5sonnetcore5
libkf5sonnetui5
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
libkf5wallet-data
libkf5wallet5
libkf5waylandclient5
libkf5waylandserver5
libkf5widgetsaddons-data
libkf5widgetsaddons5
libkf5windowsystem-data
libkf5windowsystem5
libkf5xmlgui-bin
libkf5xmlgui-data
libkf5xmlgui5
polkit-kde-agent-1
powerdevil
powerdevil-data
qml-module-org-kde-draganddrop
qml-module-org-kde-kcm
qml-module-org-kde-kconfig
qml-module-org-kde-kcoreaddons
qml-module-org-kde-kholidays
qml-module-org-kde-kio
qml-module-org-kde-kirigami2
qml-module-org-kde-kquickcontrols
qml-module-org-kde-kquickcontrolsaddons
qml-module-org-kde-newstuff
qml-module-org-kde-people
qml-module-org-kde-qqc2desktopstyle
qml-module-org-kde-quickcharts
qml-module-org-kde-solid
qml-module-org-kde-userfeedback
'

apt update &> /dev/null
apt-mark hold ${HOLD_KDE_PKGS//\\n/ } &> /dev/null
apt -yy install ${UPD_KDE_PKGS//\\n/ } --only-upgrade --no-install-recommends
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
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5.13/linux-headers-5.5.13-050513_5.5.13-050513.202003251631_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5.13/linux-headers-5.5.13-050513-generic_5.5.13-050513.202003251631_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5.13/linux-image-unsigned-5.5.13-050513-generic_5.5.13-050513.202003251631_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.5.13/linux-modules-5.5.13-050513-generic_5.5.13-050513.202003251631_amd64.deb
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
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/libs/mauikit-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/buho-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/contacts-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/index-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/nota-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/pix-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/station-1.0.0-Linux.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/vvave-1.0.0-Linux.deb
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
/bin/cp /configs/files/sources.list.focal /etc/apt/sources.list.d/ubuntu-repos.list
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
