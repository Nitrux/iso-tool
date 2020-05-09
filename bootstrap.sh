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

cp /configs/files/sources.list.eoan /etc/apt/sources.list

BASIC_PACKAGES='
apt-transport-https
apt-utils
avahi-daemon
bluez
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
open-vm-tools
rng-tools
systemd
user-setup
wget
xz-utils
ufw
'

apt update &> /dev/null
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends


# -- Add key for Neon repository.
# -- Add key for Nitrux repository.
# -- Add key for Devuan repositories #1.
# -- Add key for Devuan repositories #2.
# -- Add key for the Proprietary Graphics Drivers PPA.
# -- Add key for Ubuntu repositories #1.
# -- Add key for Ubuntu repositories #2.
# -- Add key for Kubuntu Backports PPA.

echo -e "\n"
echo -e "ADD REPOSITORY KEYS."
echo -e "\n"

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 55751E5D 1B69B2DA 541922FB BB23C00C61FC752C 1118213C 3B4FE6ACC0B21F32 871920D1991BC93C 2836CB0A8AC93F7A > /dev/null


# -- Copy sources.list files.

echo -e "\n"
echo -e "ADD SOURCES FILES."
echo -e "\n"

cp /configs/files/sources.list.nitrux /etc/apt/sources.list
cp /configs/files/sources.list.devuan /etc/apt/sources.list.d/devuan-repo.list
cp /configs/files/sources.list.eoan /etc/apt/sources.list.d/ubuntu-eoan-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list
cp /configs/files/sources.list.bionic /etc/apt/sources.list.d/ubuntu-bionic-repo.list
cp /configs/files/sources.list.xenial /etc/apt/sources.list.d/ubuntu-xenial-repo.list
# cp /configs/files/sources.list.backports /etc/apt/sources.list.d/backports-ppa-repo.list

apt update &> /dev/null


# -- Use Glibc package from Devuan.

GLIBC_2_30_PKG='
libc6=2.30-7
'

apt -yy install ${GLIBC_2_30_PKG//\\n/ } --no-install-recommends --allow-downgrades


# -- Use elogind packages from Devuan.

echo -e "\n"
echo -e "ADD ELOGIND."
echo -e "\n"

ELOGIND_PKGS='
libelogind0
elogind
uuid-runtime=2.34-0.1+devuan1
util-linux=2.34-0.1+devuan1
libprocps6=2:3.3.12-3+devuan2.1
bsdutils=1:2.34-0.1+devuan1
'

APT_PKGS='
apt=2.0.2+devuan1
apt-transport-https=2.0.2+devuan1
apt-utils=2.0.2+devuan1
'

REMOVE_SYSTEMD_PKGS='
systemd
systemd-sysv
libsystemd0
'

apt -yy purge --remove ${REMOVE_SYSTEMD_PKGS//\\n/ }
apt -yy autoremove
apt -yy install ${ELOGIND_PKGS//\\n/ } ${APT_PKGS//\\n/ } --no-install-recommends --allow-downgrades
apt -yy --fix-broken install


# -- Use PolicyKit packages from Devuan.

echo -e "\n"
echo -e "ADD POLICYKIT."
echo -e "\n"

DEVUAN_POLKIT_PKGS='
libpolkit-agent-1-0=0.105-25+devuan8
libpolkit-backend-1-0=0.105-25+devuan8
libpolkit-backend-elogind-1-0=0.105-25+devuan8
libpolkit-gobject-1-0=0.105-25+devuan8
libpolkit-gobject-elogind-1-0=0.105-25+devuan8
libpolkit-qt-1-1=0.112.0-6
libpolkit-qt5-1-1=0.112.0-6
policykit-1=0.105-25+devuan8
polkit-kde-agent-1=4:5.17.5-2
'

apt -yy install ${DEVUAN_POLKIT_PKGS//\\n/ } --no-install-recommends --allow-downgrades


DEVUAN_NM_UD2='
libnm0=1.14.6-2+deb10u1
libudisks2-0=2.8.4-1+devuan4
network-manager=1.14.6-2+deb10u1
udisks2=2.8.4-1+devuan4
init-system-helpers=1.56+nmu1+devuan2
'

apt -yy install ${DEVUAN_NM_UD2//\\n/ } --no-install-recommends --allow-downgrades


# -- Add SysV as init.

echo -e "\n"
echo -e "ADD SYSV AS INIT."
echo -e "\n"

DEVUAN_INIT_PKGS='
init=1.56+nmu1+devuan2
sysv-rc
sysvinit-core
sysvinit-utils
'

apt -yy install ${DEVUAN_INIT_PKGS//\\n/ } --no-install-recommends --allow-downgrades


# -- Check that init system is not systemd.

echo -e "\n"
echo -e "CHECK INIT LINK."
echo -e "\n"

init --version
stat /sbin/init


# -- Install base system metapackages.

echo -e "\n"
echo -e "INSTALLING BASE SYSTEM."
echo -e "\n"


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

apt -yy install ${GRUB_PACKAGES//\\n/ } ${NITRUX_BASE_PACKAGES//\\n/ } ${NITRUX_BF_PKG//\\n/ } --no-install-recommends


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

XENIAL_PACKAGES='
plymouth=0.9.2-3ubuntu13
plymouth-label=0.9.2-3ubuntu13
plymouth-themes=0.9.2-3ubuntu13
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
'

NX_DESKTOP_PKG='
nx-desktop
nx-desktop-apps
'

apt -yy install ${XENIAL_PACKAGES//\\n/ } ${DEVUAN_PULSE_PKGS//\\n/ } ${MISC_KDE_PKGS//\\n/ } ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends
apt -yy --fix-broken install


# -- Upgrade KF5 libs for Latte Dock.

echo -e "\n"
echo -e "UPGRADING KDE PACKAGES."
echo -e "\n"

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

apt update &> /dev/null
apt-mark hold ${HOLD_KDE_PKGS//\\n/ }
apt -yy install ${UPDT_KDE_PKGS//\\n/ } ${UPDT_KF5_LIBS//\\n/ } --only-upgrade --no-install-recommends
apt -yy --fix-broken install


# -- Upgrade and install misc. packages.

echo -e "\n"
echo -e "UPGRADING/INSTALLING MISC. PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.groovy /etc/apt/sources.list.d/ubuntu-groovy-repo.list

GLIBC_2_31_PKG='
libc-bin
libc6
locales
libcrypt1
libgcc1
libgcc-s1
gcc-10-base
'

OTHER_MISC_PKGS='
gamemode
tmate
linux-firmware
'

apt update &> /dev/null
apt -yy install ${GLIBC_2_31_PKG//\\n/ } --no-install-recommends
apt -yy install ${OTHER_MISC_PKGS//\\n/ } --no-install-recommends
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


# -- Add MAUI Appimages
echo -e "\n"
echo -e "ADD MAUI APPS."
echo -e "\n"

wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
chmod +x /tmp/mc
/tmp/mc config host add nx $NITRUX_STORAGE_URL $NITRUX_STORAGE_ACCESS_KEY $NITRUX_STORAGE_SECRET_KEY
_latest=$(/tmp/mc ls nx/maui/nightly | grep -Po "\d{4}-\d{2}-\d{2}/" | sort -r | head -n 1)
mkdir maui_pkgs

(
	cd maui_pkgs
	/tmp/mc cp -r "nx/maui/stable/$_latest" ./

	mv index-*amd64*.AppImage /Applications/index
	mv buho-*amd64*.AppImage /Applications/buho
	mv nota-*amd64*.AppImage /Applications/nota
	mv vvave-*amd64*.AppImage /Applications/vvave
	mv station-*amd64*.AppImage /Applications/station
	mv pix-*amd64*.AppImage /Applications/pix

	chmod +x /Applications/*

	ls -l /Applications
)

rm -r ./maui_pkgs
rm -r /tmp/mc


# -- Changes specific to this image. If they can be put in a package do so.
#FIXME These fixes should be included in a package.

echo -e "\n"
echo -e "ADD MISC. FIXES."
echo -e "\n"

/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
echo "XDG_CONFIG_DIRS=/etc/xdg" >> /etc/environment
echo "XDG_DATA_DIRS=/usr/local/share:/usr/share" >> /etc/environment
cp /configs/other/compendium_offline.pdf /etc/skel/Desktop/Nitrux\ —\ Compendium.pdf
cp /configs/other/faq_offline.pdf /etc/skel/Desktop/Nitrux\ —\ FAQ.pdf
rm -r /home/travis


# -- Implement New FHS.
#FIXME Replace with kernel patch and userland tool.

echo -e "\n"
echo -e "NEW FHS."
echo -e "\n"

mkdir -p /Core/Boot
mkdir -p /Core/Boot/ESP
mkdir -p /Core/System/Deployments
mkdir -p /Devices
mkdir -p /Devices/Removable
mkdir -p /System/Binaries
mkdir -p /System/Binaries/Optional
mkdir -p /System/Configuration
mkdir -p /System/DevicesFS
mkdir -p /System/Libraries
mkdir -p /System/Mount/Filesystems
mkdir -p /System/Processes
mkdir -p /System/Runtime
mkdir -p /System/Server/Services
mkdir -p /System/TempFS
mkdir -p /System/Variable
mkdir -p /Users/

# mount --bind /boot /Core/Boot
# mount --bind /dev /Devices
# mount --bind /etc /System/Configuration
# mount --bind /home /Users
# mount --bind /mnt /System/Mount/Filesystems
# mount --bind /opt /System/Binaries/Optional
# mount --bind /proc /System/Processes
# mount --bind /run /System/Runtime
# mount --bind /srv /System/Server/Services
# mount --bind /sys /System/DevicesFS
# mount --bind /tmp /System/TempFS
# mount --bind /usr/bin /System/Binaries
# mount --bind /usr/lib /System/Libraries
# mount --bind /usr/share /System/Resources/Shared
# mount --bind /var /System/Variable

cp /configs/files/hidden /.hidden


# -- Add vfio modules and files.
#FIXME This configuration should be included a in a package; replacing the default package like base-files.

echo -e "\n"
echo -e "ADD VFIO ENABLEMENT AND CONFIGURATION."
echo -e "\n"

echo "install vfio-pci /usr/bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "install vfio_pci /usr/bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep nouveau pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
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
echo "nouveau" >> /etc/initramfs-tools/modules
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
cp /configs/files/{amdgpu.conf,i915.conf,kvm.conf,nvidia.conf,nouveau.conf,qemu-system-x86.conf,radeon.conf,vfio_pci.conf,vfio-pci.conf} /etc/modprobe.d/

cp /configs/scripts/vfio-pci-override-vga.sh /usr/bin/
chmod a+x /usr/bin/vfio-pci-override-vga.sh


# -- Use LZ4 compression when creating the initramfs.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.
# -- Add znx_dev_uuid parameter.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "UPDATE INITRAMFS."
echo -e "\n"

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan

update-initramfs -u
lsinitramfs -l /boot/initrd.img-5.4.21-050421-generic | grep vfio


# -- Remove APT.
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
