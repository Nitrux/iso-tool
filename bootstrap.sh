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
user-setup
wget
xz-utils
'

apt update &> /dev/null
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends


# -- Add key for Neon repository.
# -- Add key for our repository.
# -- Add key for the Proprietary Graphics Drivers PPA.
# -- Add key for XORG PPA.

printf "\n"
printf "ADD REPOSITORY KEYS."
printf "\n"

wget -q https://archive.neon.kde.org/public.key -O neon.key
printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
apt-key add neon.key > /dev/null
rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF1CDFA9 > /dev/null


# -- Use sources.list.build to build ISO.

cp /configs/files/sources.list.build /etc/apt/sources.list


# -- Update packages list and install packages. Install nx-desktop meta package and base-files package avoiding recommended packages.

printf "\n"
printf "INSTALLING DESKTOP."
printf "\n"

DESKTOP_PACKAGES='
nitrux-minimal
nitrux-standard
nitrux-hardware-drivers
nx-desktop
'

apt update &> /dev/null
apt -yy upgrade
apt -yy install ${DESKTOP_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install &> /dev/null
apt -yy purge --remove vlc &> /dev/null
apt -yy dist-upgrade


# -- Use sources.list.eoan to update packages and install brew.

printf "\n"
printf "UPDATE MISC. PACKAGES."
printf "\n"

cp /configs/files/sources.list.eoan /etc/apt/sources.list

UPGRADE_OS_PACKAGES='
amd64-microcode
broadcom-sta-dkms
dkms
exfat-fuse
exfat-utils
go-mtpfs
grub-common
grub-efi-amd64
grub-efi-amd64-bin
grub-efi-amd64-signed
grub2-common
i965-va-driver
initramfs-tools
initramfs-tools-bin
initramfs-tools-core
ipxe-qemu
libdrm-amdgpu1
libdrm-intel1
libdrm-radeon1
libva-drm2
libva-glx2
libva-x11-2
libva2
linux-firmware
mesa-va-drivers
mesa-vdpau-drivers
mesa-vulkan-drivers
openssh-client
openssl
ovmf
seabios
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
language-pack-de
language-pack-de-base
language-pack-en
language-pack-en-base
language-pack-es
language-pack-es-base
language-pack-fr
language-pack-fr-base
language-pack-pt
language-pack-pt-base
'

ADD_BREW_PACKAGES='
libc-dev-bin
libc6-dev
linux-libc-dev
linuxbrew-wrapper
'

apt update &> /dev/null
apt -yy install ${UPGRADE_OS_PACKAGES//\\n/ } --only-upgrade --no-install-recommends
apt -yy install ${ADD_BREW_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
#FIXME This should be put in our repository.

printf "\n"
printf "INSTALLING APPIMAGE DAEMON."
printf "\n"

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git05c4438.travis209_amd64.deb
'

mkdir /appimaged_deb

for x in $appimgd; do
    wget -q -P /appimaged_deb $x
done

dpkg -iR /appimaged_deb &> /dev/null
apt -yy --fix-broken install &> /dev/null
rm -r /appimaged_deb


# -- Install the kernel.
#FIXME This should be put in our repository.

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.8/linux-headers-5.3.8-050308_5.3.8-050308.201910290940_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.8/linux-headers-5.3.8-050308-generic_5.3.8-050308.201910290940_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.8/linux-image-unsigned-5.3.8-050308-generic_5.3.8-050308.201910290940_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.8/linux-modules-5.3.8-050308-generic_5.3.8-050308.201910290940_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
printf "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- No apt usage past this point. -- #


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
'

mkdir /fw_files

for x in $fw; do
    wget -q -P /fw_files $x
done

mv /fw_files/vega20_ta.bin /lib/firmware/amdgpu/
mv /fw_files/raven_kicker_rlc.bin /lib/firmware/amdgpu/
mv /fw_files/navi10_*.bin /lib/firmware/amdgpu/
mv /fw_files/bxt_huc_ver01_8_2893.bin /lib/firmware/i915/

rm -r /fw_files


# -- Add /Applications to $PATH.

printf "\n"
printf "ADD /APPLICATIONS TO PATH."
printf "\n"

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add system AppImages.
# -- Create /Applications directory for users.
# -- Rename AppImageUpdate, appimage-user-tool and znx.

printf "\n"
printf "ADD APPIMAGES."
printf "\n"

APPS_SYS='
https://github.com/Nitrux/znx/releases/download/continuous-stable/znx_master
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/appimage-cli-tool-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/Binaries/vmetal-free-amd64
https://github.com/Hackerl/Wine_Appimage/releases/download/continuous/Wine-x86_64-ubuntu.latest.AppImage
'

mkdir /Applications

for x in $APPS_SYS; do
    wget -q -P /Applications $x
done

chmod +x /Applications/*
mkdir -p /etc/skel/Applications

APPS_USR='
http://libreoffice.soluzioniopen.com/stable/basic/LibreOffice-6.3.2-x86_64.AppImage
http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/waterfox-classic-latest-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/mpv-0.30.0-x86_64.AppImage
https://repo.nxos.org/appimages/maui-pix/Pix-x86_64.AppImage
https://repo.nxos.org/appimages/buho/Buho-70c0ff7-x86_64.AppImage
'

for x in $APPS_USR; do
    wget -q -P /etc/skel/Applications $x
done

chmod +x /etc/skel/Applications/*

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/appimageupdate
mv /Applications/znx_master /Applications/znx
mv /Applications/vmetal-free-amd64 /Applications/vmetal
mv /Applications/appimage-cli-tool-x86_64.AppImage /Applications/app
mv /Applications/Wine-x86_64-ubuntu.latest.AppImage /Applications/wine

ls -l /Applications
ls -l /etc/skel/Applications


# -- Add AppImage providers for appimage-cli-tool

printf "\n"
printf "ADD APPIMAGE PROVIDERS."
printf "\n"

cp /configs/files/appimage-providers.yaml /etc/


# -- Add znx-gui.
#FIXME We should include the AppImage but firejail prevents the use of sudo.

printf "\n"
printf "ADD ZNX_GUI."
printf "\n"

cp /configs/other/znx-gui.desktop /usr/share/applications
wget -q -O /bin/znx-gui https://raw.githubusercontent.com/UriHerrera/storage/master/Scripts/znx-gui
chmod +x /bin/znx-gui


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add policykit file for KDialog.
# -- Add VMetal desktop launcher.
# -- Overwrite Qt settings file. This file was IN a package but caused installation conflicts with kio-extras.
# -- Overwrite Plasma 5 notification positioning. This file was IN a package but caused installation conflicts with plasma-workspace.
# -- For a strange reason, the Breeze cursors override some of our cursor assets. Delete them from the system to avoid this.
# -- Add Window title plasmoid.
#FIXME This should be included as a deb package downloaded to our repository.
#FIXME These fixes should be included in a package.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

cp /configs/files/sddm.conf /etc
cp /configs/files/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/files/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
cp /configs/files/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/
cp /configs/other/vmetal.desktop /usr/share/applications
/bin/cp /configs/files/Trolltech.conf /etc/xdg/Trolltech.conf
/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
rm -R /usr/share/icons/breeze_cursors /usr/share/icons/Breeze_Snow
cp -a /configs/other/org.kde.windowtitle /usr/share/plasma/plasmoids


# -- Add vfio modules and files.
#FIXME This configuration should be included a in a package; replacing the default package like base-files.

printf "\n"
printf "ADD VFIO ENABLEMENT AND CONFIGURATION."
printf "\n"

echo "install vfio-pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "install vfio_pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep amdgpu pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep i915 pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "vfio" >> /etc/initramfs-tools/modules
echo "vfio_iommu_type1" >> /etc/initramfs-tools/modules
echo "vfio_virqfd" >> /etc/initramfs-tools/modules
echo "options vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci" >> /etc/initramfs-tools/modules
echo "nvidia" >> /etc/initramfs-tools/modules
echo "amdgpu" >> /etc/initramfs-tools/modules
echo "i915" >> /etc/initramfs-tools/modules

echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_pci ids=" >> /etc/modules

cp /configs/files/asound.conf /etc/
cp /configs/files/asound.conf /etc/skel/.asoundrc

cp /configs/files/iommu_unsafe_interrupts.conf /etc/modprobe.d/

cp /configs/files/{amdgpu.conf,i915.conf,kvm.conf,nvidia.conf,qemu-system-x86.conf,vfio_pci.conf,vfio-pci.conf} /etc/modprobe.d/
cp /configs/scripts/{vfio-pci-override-vga.sh,dummy.sh} /bin/

chmod +x /bin/dummy.sh


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
#FIXME This should be put in a package.

sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf


# -- Disable systemd services not deemed necessary.
# -- use 'mask' to fully disable them.

systemctl mask avahi-daemon.service
systemctl disable cupsd.service
systemctl disable cupsd-browsed.service
systemctl disable NetworkManager-wait-online.service
systemctl disable keyboard-setup.service


# -- Fix for broken udev rules (yes, it is broken by default).
#FIXME This should be put in a package.

sed -i 's/ACTION!="add", GOTO="libmtp_rules_end"/ACTION!="bind", ACTION!="add", GOTO="libmtp_rules_end"/g' /lib/udev/rules.d/69-libmtp.rules


# -- Use sources.list.nitrux for release.

/bin/cp /configs/files/sources.list.nitrux /etc/apt/sources.list


# -- Overwrite file so cupt doesn't complain.
# -- Remove APT.
# -- Update package index using cupt.
#FIXME We probably need to provide our own cupt package which also does this.

printf "\n"
printf "REMOVE APT."
printf "\n"

REMOVE_APT='
apt 
apt-utils 
apt-transport-https
'

/bin/cp -a /configs/files/50command-not-found /etc/apt/apt.conf.d/50command-not-found
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_APT//\\n/ } &> /dev/null


# -- Strip kernel modules.
# -- Use XZ compression when creating the initramfs
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.
# -- Add znx_dev_uuid parameter.
#FIXME This should be put in a package.

printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

find /lib/modules/5.3.8-050308-generic/ -iname "*.ko" -exec strip --strip-unneeded {} \;
cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan

update-initramfs -u
lsinitramfs /boot/initrd.img-5.3.8-050308-generic | grep vfio

rm /bin/dummy.sh


# -- Clean the filesystem.

printf "\n"
printf "REMOVE CASPER."
printf "\n"

REMOVE_PACKAGES='
casper
lupin-casper
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_PACKAGES//\\n/ } &> /dev/null


printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
