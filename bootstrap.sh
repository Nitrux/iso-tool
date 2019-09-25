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
libarchive13
libelf1
libstartup-notification0
localechooser-data
lupin-casper
phonon4qt5
phonon4qt5-backend-vlc
user-setup
wget
xz-utils
'

apt -qq update &> /dev/null
apt -yy -qq install ${BASIC_PACKAGES//\\n/ } --no-install-recommends &> /dev/null


# -- Add key for Neon repository.
# -- Add key for our repository.
# -- Add key for the Proprietary Graphics Drivers PPA.
# -- Add key for Devuan repositories #1.
# -- Add key for Devuan repositories #2.

printf "\n"
printf "ADD REPOSITORY KEYS."
printf "\n"

wget -q https://archive.neon.kde.org/public.key -O neon.key
printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
apt-key add neon.key > /dev/null
rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 541922FB > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BB23C00C61FC752C > /dev/null


# -- Use sources.list.build.stage1 to build ISO.

cp /configs/sources.list.build.stage1 /etc/apt/sources.list


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

apt -qq update &> /dev/null
apt -yy -qq upgrade &> /dev/null
apt -yy install ${DESKTOP_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install &> /dev/null
apt -yy -qq purge --remove vlc &> /dev/null
apt -yy -qq dist-upgrade &> /dev/null


# -- Install the kernel.
#FIXME This should be put in our repository

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.1/linux-headers-5.3.1-050301_5.3.1-050301.201909210632_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.1/linux-headers-5.3.1-050301-generic_5.3.1-050301.201909210632_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.1/linux-image-unsigned-5.3.1-050301-generic_5.3.1-050301.201909210632_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.3.1/linux-modules-5.3.1-050301-generic_5.3.1-050301.201909210632_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
printf "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- Install linuxbrew-wrapper.
#FIXME This package should be included in a metapackage.

printf "\n"
printf "INSTALLING LINUXBREW."
printf "\n"

brewd='
http://mirrors.kernel.org/ubuntu/pool/main/l/linux/linux-libc-dev_5.0.0-29.31_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6-dev_2.29-0ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-dev-bin_2.29-0ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/multiverse/l/linuxbrew-wrapper/linuxbrew-wrapper_20180923-1_all.deb
'

mkdir /brew_deps

for x in $brewd; do
    wget -q -P /brew_deps $x
done

dpkg -iR /brew_deps &> /dev/null
apt -yy --fix-broken install
rm -r /brew_deps


# -- Add Window title plasmoid.
#FIXME This should be included as a deb package downloaded to our repository.

printf "\n"
printf "ADD WINDOW TITLE PLASMOID."
printf "\n"

cp -a /configs/org.kde.windowtitle /usr/share/plasma/plasmoids


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


# -- Use sources.list.eoan to update packages
# -- Update X11, MESA, AMD microcode, and OpenSSH.

printf "\n"
printf "UPDATE BASE PACKAGES."
printf "\n"

cp /configs/sources.list.eoan /etc/apt/sources.list
apt -qq update

UPGRADE_OS_PACKAGES='
amd64-microcode
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

apt -qq update &> /dev/null
apt -yy -qq install ${UPGRADE_OS_PACKAGES//\\n/ } --only-upgrade


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
https://github.com/Nitrux/znx/releases/download/stable/znx_stable
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
https://repo.nxos.org/appimages/appimage-user-tool-x86_64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/vmetal
https://github.com/Nitrux/znx-gui/releases/download/continuous/znx-gui_development-x86_64.AppImage
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
https://github.com/Hackerl/Wine_Appimage/releases/download/continuous/Wine-x86_64-ubuntu.latest.AppImage
'

mkdir /Applications

for x in $APPS_SYS; do
    wget -q -P /Applications $x
done

chmod +x /Applications/*
mkdir -p /etc/skel/Applications

APPS_USR='
http://libreoffice.soluzioniopen.com/stable/basic/LibreOffice-6.3.1-x86_64.AppImage
http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/Waterfox-latest-x86_64.AppImage
https://repo.nxos.org/appimages/vlc/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
https://repo.nxos.org/appimages/maui-pix/Pix-x86_64.AppImage
https://repo.nxos.org/appimages/buho/Buho-70c0ff7-x86_64.AppImage
'

for x in $APPS_USR; do
    wget -q -P /etc/skel/Applications $x
done

chmod +x /etc/skel/Applications/*

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/appimageupdate
mv /Applications/znx_stable /Applications/znx
mv /Applications/znx-gui_development-x86_64.AppImage /Applications/znx-gui
mv /Applications/appimage-user-tool-x86_64.AppImage /Applications/app
mv /Applications/Wine-x86_64-ubuntu.latest.AppImage /Applications/wine

ls -l /Applications
ls -l /etc/skel/Applications


# -- Add AppImage providers for appimage-cli-tool

printf "\n"
printf "ADD APPIMAGE PROVIDERS."
printf "\n"

cp /configs/appimage-providers.yaml /etc/


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add policykit file for KDialog.
# -- Add VMetal desktop launcher.
#FIXME These fixes should be included in a package.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

cp /configs/sddm.conf /etc
cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
cp /configs/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/
cp /configs/vmetal.desktop /usr/share/applications


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

cp /configs/asound.conf /etc/
cp /configs/asound.conf /etc/skel/.asoundrc

cp /configs/iommu_unsafe_interrupts.conf /etc/modprobe.d/

cp /configs/amdgpu.conf /etc/modprobe.d/
cp /configs/i915.conf /etc/modprobe.d/
cp /configs/kvm.conf /etc/modprobe.d/
cp /configs/nvidia.conf /etc/modprobe.d/
cp /configs/qemu-system-x86.conf /etc/modprobe.d
cp /configs/vfio_pci.conf /etc/modprobe.d/
cp /configs/vfio-pci.conf /etc/modprobe.d/

cp /configs/vfio-pci-override-vga.sh /bin/
cp /configs/dummy.sh /bin/

chmod +x /bin/dummy.sh /bin/vfio-pci-override-vga.sh


# -- Add itch.io store launcher.
#FIXME This should be in a package.

printf "\n"
printf "ADD ITCH.IO LAUNCHER."
printf "\n"


mkdir -p /etc/skel/.local/share/applications
cp /configs/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/install-itch-io.sh /etc/skel/.config


# -- Add oh my zsh.

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


# # -- Decrease timeout for systemd start and stop services.
# 
# sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
# sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf


# -- Use XZ compression when creating the ISO.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.
#FIXME This should be put in a package.

printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

cp /configs/initramfs.conf /etc/initramfs-tools/
cp /configs/hook-scripts.sh /usr/share/initramfs-tools/hooks/
chmod +x /usr/share/initramfs-tools/hooks/hook-scripts.sh
cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u
lsinitramfs /boot/initrd.img-5.3.1-050301-generic | grep vfio

rm /bin/dummy.sh
rm /usr/share/initramfs-tools/hooks/hook-scripts.sh

printf "\n"
printf "STAGE 1 COMPLETE."
printf "\n"


# -- Downgrade packages using Devuan.
# -- Use sources.list.build.stage2 to add init from Devuan.

cp /configs/sources.list.build.stage2 /etc/apt/sources.list
apt -qq update &> /dev/null


# -- Download and install libsystemd0 from Devuan.

libsystemd0='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/libs/libsystemd0_241-5~bpo9%2B1_amd64.deb
'

mkdir /libsystemd0_deb

for x in $libsystemd0; do
    wget -q -P /libsystemd0_deb $x
done

dpkg -iR /libsystemd0_deb &> /dev/null
apt -yy --fix-broken install
rm -r /libsystemd0_deb


libnih='
http://ftp.us.debian.org/debian/pool/main/libn/libnih/libnih1_1.0.3-10+b4_amd64.deb
http://ftp.us.debian.org/debian/pool/main/libn/libnih/libnih-dbus1_1.0.3-10+b4_amd64.deb
'

mkdir /libnih_debs

for x in $libnih; do
    wget -q -P /libnih_debs $x
done

dpkg -iR /libnih_debs &> /dev/null
apt -yy --fix-broken install
rm -r /libnih_debs


# -- Use PolicyKit packages from Devuan.

DEVUAN_POLKIT_PACKAGES='
libpolkit-agent-1-0
libpolkit-backend-1-0
libpolkit-backend-consolekit-1-0
libpolkit-gobject-1-0
libpolkit-gobject-consolekit-1-0
libpolkit-qt5-1-1=0.112.0-5
libpolkit-qt-1-1=0.112.0-5
policykit-1
'

apt -yy install ${DEVUAN_POLKIT_PACKAGES//\\n/ } --no-install-recommends


DEVUAN_PACKAGES='
network-manager=1.6.2-3+devuan1.1
libnm0=1.6.2-3+devuan1.1
udisks2=2.1.8-1+devuan2
libudisks2-0=2.1.8-1+devuan2
'

apt -yy install ${DEVUAN_PACKAGES//\\n/ } --no-install-recommends


# -- Add SysV as init.

printf "\n"
printf "ADD SYSVRC AS INIT."
printf "\n"

DEVUAN_INIT_PACKAGES='
init
init-system-helpers
sysv-rc
sysvinit-core
sysvinit-utils
'

apt -yy install ${DEVUAN_INIT_PACKAGES//\\n/ } --no-install-recommends


# -- Check that init system is not systemd.

printf "\n"
printf "Check init link."
printf "\n"

init --version
stat /sbin/init


# -- Install packages from Xenial.

XENIAL_PACKAGES='
plymouth=0.9.2-3ubuntu13
plymouth-label=0.9.2-3ubuntu13
plymouth-themes=0.9.2-3ubuntu13
ttf-ubuntu-font-family
'

apt -yy install ${XENIAL_PACKAGES//\\n/ } --no-install-recommends
apt -yy purge --remove dracut dracut-core kpartx pkg-config systemd systemd-sysv


# -- Put packages on hold.

PIN_PACKAGES_HOLD='
libpolkit-agent-1-0
libpolkit-gobject-1-0
udisks2
network-manager
'

apt-mark hold ${PIN_PACKAGES_HOLD//\\n/ } &> /dev/null


# -- Mark packages as manual.

PIN_PACKAGES_MANUAL='
libudev1
libudisks2-0
sysvinit-core
libnm0
'

apt-mark manual ${PIN_PACKAGES_MANUAL//\\n/ } &> /dev/null


# -- Reinstall Nitrux metapackages.

apt -yy install ${DESKTOP_PACKAGES//\\n/ } --no-install-recommends --reinstall
apt -yy --fix-broken install


printf "\n"
printf "STAGE 2 COMPLETE."
printf "\n"


# -- Use sources.list.nitrux for release.

/bin/cp /configs/sources.list.nitrux /etc/apt/sources.list


# -- Overwrite file so cupt doesn't complain.
# -- Remove APT.
# -- Update package index using cupt.
#FIXME We probably need to provide our own cupt package which also does this.

printf "\n"
printf "REMOVE APT."
printf "\n"

/bin/cp -a /configs/50command-not-found /etc/apt/apt.conf.d/50command-not-found
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path apt apt-utils apt-transport-https
cupt -q update


# -- Clean the filesystem.

printf "\n"
printf "REMOVE CASPER."
printf "\n"

REMOVE_PACKAGES='
casper
lupin-casper
'

cupt -y purge ${REMOVE_PACKAGES//\\n/ }
cupt -y -q clean &> /dev/null


printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
