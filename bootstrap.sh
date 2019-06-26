#! /bin/bash


printf "\n"
printf "STARTING BOOTSTRAP."
printf "\n"


# -- Packages to install.

PACKAGES='
nitrux-minimal
nitrux-standard
nitrux-hardware-drivers
nx-desktop
'


# -- Install basic packages.

printf "\n"
printf "INSTALLING BASIC PACKAGES."
printf "\n"

apt -qq update &> /dev/null
apt -yy install apt-transport-https wget ca-certificates gnupg2 apt-utils xz-utils casper lupin-casper libarchive13 fuse dhcpcd5 user-setup localechooser-data libelf1 phonon4qt5 phonon4qt5-backend-vlc &> /dev/null


# -- Add key for Neon repository.
# -- Add key for our repository.
# -- Add key for the Proprietary Graphics Drivers PPA.
# -- Add key for the Ubuntu-X PPA.

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

apt -qq update &> /dev/null
apt -yy -qq upgrade &> /dev/null
apt -yy -qq install ${PACKAGES//\\n/ } --no-install-recommends
apt -yy -qq purge --remove vlc &> /dev/null
apt -yy -qq dist-upgrade > /dev/null


# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

printf "\n"
printf "INSTALLING APPIMAGE DAEMON."
printf "\n"

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git05c4438.travis209_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done

dpkg -iR appimaged_deb &> /dev/null
apt -yy --fix-broken install &> /dev/null
rm -r appimaged_deb


# -- Install the kernel.

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.1.14/linux-headers-5.1.14-050114_5.1.14-050114.201906221030_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.1.14/linux-headers-5.1.14-050114-generic_5.1.14-050114.201906221030_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.1.14/linux-image-unsigned-5.1.14-050114-generic_5.1.14-050114.201906221030_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.1.14/linux-modules-5.1.14-050114-generic_5.1.14-050114.201906221030_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	printf "$x"
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r latest_kernel


# -- Add /Applications to $PATH.

printf "\n"
printf "ADD APPIMAGES."
printf "\n"

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add system AppImages.
# -- Create /Applications directory for users.
# -- Rename AppImageUpdate and znx.
# -- Add znx-gui.

APPS_SYS='
https://github.com/Nitrux/znx/releases/download/continuous-development/znx_development
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
https://github.com/Nitrux/znx-gui/releases/download/continuous/znx-gui_master-x86_64.AppImage
'

mkdir /Applications

for x in $APPS_SYS; do
	wget -q -P /Applications $x
done

chmod +x /Applications/*
mkdir -p /etc/skel/Applications

APPS_USR='
http://libreoffice.soluzioniopen.com/stable/basic/LibreOffice-6.2.4-x86_64.AppImage
http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/Waterfox-latest-x86_64.AppImage
https://github.com/Hackerl/Wine_Appimage/releases/download/continuous/Wine-x86_64-ubuntu.latest.AppImage
https://repo.nxos.org/appimages/Index-x86_64.AppImage
https://repo.nxos.org/appimages/Pix-x86_64.AppImage
https://repo.nxos.org/appimages/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
https://repo.nxos.org/appimages/appimage-user-tool-x86_64.AppImage
https://repo.nxos.org/appimages/vvave-x86_64.AppImage
'

for x in $APPS_USR; do
    wget -q -P --user-agent="Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0" /etc/skel/Applications $x
done

chmod +x /etc/skel/Applications/*

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/AppImageUpdate
mv /Applications/znx_development /Applications/znx
mv /Applications/znx-gui_master-x86_64.AppImage /Applications/znx-gui


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add custom launchers for Maui apps.
# -- Add policykit file for KDialog.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

cp /configs/sddm.conf /etc
cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
cp /configs/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/


# -- Add vfio modules and files.

echo "install vfio-pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "install vfio_pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep amdgpu pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "vfio" >> /etc/initramfs-tools/modules
echo "vfio_iommu_type1" >> /etc/initramfs-tools/modules
echo "vfio_virqfd" >> /etc/initramfs-tools/modules
echo "options vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci" >> /etc/initramfs-tools/modules
echo "nvidia" >> /etc/initramfs-tools/modules
echo "amdgpu" >> /etc/initramfs-tools/modules

echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_pci ids=" >> /etc/modules

cp /configs/asound.conf /etc/
cp /configs/asound.conf /etc/skel/.asoundrc

cp /configs/iommu_unsafe_interrupts.conf /etc/modprobe.d/

cp /configs/amdgpu.conf /etc/modprobe.d/
cp /configs/kvm.conf /etc/modprobe.d/
cp /configs/nvidia.conf /etc/modprobe.d/
cp /configs/qemu-system-x86.conf /etc/modprobe.d
cp /configs/vfio_pci.conf /etc/modprobe.d/
cp /configs/vfio-pci.conf /etc/modprobe.d/

cp /configs/vfio-pci-override-vga.sh /bin/


# -- Add itch.io store launcher.

mkdir -p /etc/skel/.local/share/applications
cp /configs/install.itch.io.desktop /etc/skel/.local/share/applications
cp /configs/install-itch-io.sh /etc/skel/.config


# -- Add Window title plasmoid.

printf "\n"
printf "ADD WINDOW TITLE PLASMOID."
printf "\n"

cp -a /configs/org.kde.windowtitle /usr/share/plasma/plasmoids


# -- Update the initramfs.

printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

cp /configs/initramfs.conf /etc/initramfs-tools/

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u


# -- Clean the filesystem.

printf "\n"
printf "REMOVE CASPER."
printf "\n"

apt -yy -qq purge --remove casper lupin-casper &> /dev/null
apt -yy -qq autoremove
apt -yy -qq clean &> /dev/null


# -- Use sources.list.nitrux for release.

/bin/cp /configs/sources.list.nitrux /etc/apt/sources.list


printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
