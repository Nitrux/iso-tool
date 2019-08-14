#! /bin/bash

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
# -- Add key for the Ubuntu-X PPA.


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

cp /configs/sources.list.build /etc/apt/sources.list


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package avoiding recommended packages.

printf "\n"
printf "INSTALLING DESKTOP."
printf "\n"

DESKTOP_PACKAGES='
nitrux-minimal
nitrux-standard
nitrux-hardware-drivers
nx-desktop
'

apt -qq update
apt -yy -qq upgrade
apt -yy -qq install ${DESKTOP_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install
apt -yy -qq purge --remove vlc
apt -yy -qq dist-upgrade


# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

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

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.2.8/linux-headers-5.2.8-050208_5.2.8-050208.201908091630_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.2.8/linux-headers-5.2.8-050208-generic_5.2.8-050208.201908091630_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.2.8/linux-image-unsigned-5.2.8-050208-generic_5.2.8-050208.201908091630_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.2.8/linux-modules-5.2.8-050208-generic_5.2.8-050208.201908091630_amd64.deb
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
http://mirrors.kernel.org/ubuntu/pool/main/l/linux/linux-libc-dev_5.0.0-17.18_amd64.deb
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
#FIXME This should be included as a deb package downloaded from our repository.

printf "\n"
printf "ADD WINDOW TITLE PLASMOID."
printf "\n"

cp -a /configs/org.kde.windowtitle /usr/share/plasma/plasmoids


# -- Add missing firmware modules.
#FIXME This files should be included to a package.

printf "\n"
printf "ADDING MISSING FIRMWARE."
printf "\n"

fw='
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/vega20_ta.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/bxt_huc_ver01_8_2893.bin
https://raw.githubusercontent.com/UriHerrera/storage/master/Files/raven_kicker_rlc.bin
'

mkdir /fw_files

for x in $fw; do
    wget -q -P /fw_files $x
done

mv /fw_files/vega20_ta.bin /lib/firmware/amdgpu/
mv /fw_files/raven_kicker_rlc.bin /lib/firmware/amdgpu/
mv /fw_files/bxt_huc_ver01_8_2893.bin /lib/firmware/i915/

rm -r /fw_files


# -- Use sources.list.eoan to update packages
# -- Update X11, Intel and AMD microcode, and OpenSSH.

printf "\n"
printf "UPDATE BASE PACKAGES."
printf "\n"

cp /configs/sources.list.eoan /etc/apt/sources.list
apt -qq update

UPGRADE_OS_PACKAGES='
openssl
openssh-client
x11-session-utils
xinit
xserver-xorg-core
xserver-xorg-input-wacom
xserver-xorg-input-libinput
xserver-xorg-input-mouse
xserver-xorg-input-evdev
xserver-xorg-input-synaptics
xserver-xorg-input-void
xserver-xorg-video-amdgpu
xserver-xorg-video-intel
xserver-xorg-video-qxl
xserver-xorg-video-radeon
xserver-xorg-video-vmware
libdrm-amdgpu1
libdrm-radeon1
i965-va-driver
libdrm-intel1
libva-drm2
libva-glx2
libva-x11-2
libva2
thunderbolt-tools
mesa-va-drivers
mesa-vdpau-drivers
mesa-vulkan-drivers
amd64-microcode
intel-microcode
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
# -- Rename AppImageUpdate and znx.

printf "\n"
printf "ADD APPIMAGES."
printf "\n"

APPS_SYS='
https://github.com/Nitrux/znx/releases/download/stable/znx_stable
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
https://repo.nxos.org/appimages/appimage-user-tool-x86_64.AppImage
'

mkdir /Applications

for x in $APPS_SYS; do
    wget -q -P /Applications $x
done

chmod +x /Applications/*
mkdir -p /etc/skel/Applications

APPS_USR='
http://libreoffice.soluzioniopen.com/stable/basic/LibreOffice-6.3.0-x86_64.AppImage
http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/Waterfox-latest-x86_64.AppImage
https://github.com/Hackerl/Wine_Appimage/releases/download/continuous/Wine-x86_64-ubuntu.latest.AppImage
https://github.com/icflorescu/vlc-3-appimage/releases/download/3.0.3/VLC_media_player-x86_64.AppImage
https://repo.nxos.org/appimages/Pix-x86_64.AppImage
'

for x in $APPS_USR; do
    wget -q -P /etc/skel/Applications $x
done

chmod +x /etc/skel/Applications/*

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/appimageupdate
mv /Applications/znx_stable /Applications/znx
mv /Applications/appimage-user-tool-x86_64.AppImage /Applications/app


# -- Add AppImage providers for appimage-cli-tool

printf "\n"
printf "ADD APPIMAGE PROVIDERS."
printf "\n"

cp /configs/appimage-providers.yaml /etc/


# -- Add znx-gui.
#FIXME We should include the AppImage but firejail prevents the use of sudo.

printf "\n"
printf "ADD ZNX_GUI."
printf "\n"

cp /configs/znx-gui.desktop /usr/share/applications
wget -q -O /bin/znx-gui https://raw.githubusercontent.com/Nitrux/nitrux-iso-tool/development/configs/znx-gui
chmod +x /bin/znx-gui


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add policykit file for KDialog.
#FIXME These fixes should be included in a package.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

cp /configs/sddm.conf /etc
cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
cp /configs/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/


# -- Add vfio modules and files.
#FIXME This configuration should be included a in a package; replacing the defaul package like base-files.

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

chmod +x /bin/dummy.sh


# -- Add itch.io store launcher.
#FIXME This should be in a package.

printf "\n"
printf "ADD ITCH.IO LAUNCHER."
printf "\n"


mkdir -p /etc/skel/.local/share/applications
cp /configs/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/install-itch-io.sh /etc/skel/.config


# -- Remove dash and use mksh as /bin/sh.
# -- Use mksh as default shell for all users.
#FIXME This should be put in a package.

printf "\n"
printf "REMOVE DASH AND USE MKSH."
printf "\n"

rm /bin/sh.distrib
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null
ln -sv /bin/mksh /bin/sh
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null

sed -i 's+SHELL=/bin/sh+SHELL=/bin/mksh+g' /etc/default/useradd
sed -i 's+DSHELL=/bin/bash+DSHELL=/bin/mksh+g' /etc/adduser.conf


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


# -- Use XZ compression when creating the ISO.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.

printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

cp /configs/initramfs.conf /etc/initramfs-tools/

cp /configs/hook-scripts.sh /usr/share/initramfs-tools/hooks/

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u

lsinitramfs /boot/initrd.img-5.2.8-050208-generic | grep vfio

rm /bin/dummy.sh


# -- Clean the filesystem.

printf "\n"
printf "REMOVE CASPER."
printf "\n"

REMOVE_PACKAGES='
casper
lupin-casper
'

cupt -y -q purge ${REMOVE_PACKAGES//\\n/ }
cupt -y -q clean &> /dev/null


printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
