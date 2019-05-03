#! /bin/bash


export LANG=C
export LC_ALL=C


# -- Packages to install.

PACKAGES='
dhcpcd5
user-setup
localechooser-data
cifs-utils
casper
lupin-casper
xz-utils
nomad-desktop
'


# -- Install basic packages.

apt -qq update > /dev/null
apt -yy -qq install apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends > /dev/null


# -- Add key for Neon repository.
# -- Add key for our repository.
# -- Add key for the Graphics Driver PPA.
# -- Add key for the Ubuntu-X PPA.

	wget -q https://archive.neon.kde.org/public.key -O neon.key
	printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
	apt-key add neon.key > /dev/null

	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF1CDFA9 > /dev/null


# -- Use sources.list.build to build ISO.

cp /configs/sources.list.build /etc/apt/sources.list


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package avoiding recommended packages.

apt -qq update > /dev/null
apt -yy -qq upgrade > /dev/null
apt -yy install ${PACKAGES//\\n/ } --no-install-recommends
apt -yy -qq purge --remove vlc > /dev/null
apt -yy -qq dist-upgrade


# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git2e34378.travis108_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done

dpkg -iR appimaged_deb > /dev/null
rm -r appimaged_deb


# -- Install the latest LTS kernel.

printf "INSTALLING NEW KERNEL."

kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.35/linux-headers-4.19.35-041935_4.19.35-041935.201904170334_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.35/linux-headers-4.19.35-041935-generic_4.19.35-041935.201904170334_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.35/linux-image-unsigned-4.19.35-041935-generic_4.19.35-041935.201904170334_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.35/linux-modules-4.19.35-041935-generic_4.19.35-041935.201904170334_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	printf "$x"
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel > /dev/null
rm -r latest_kernel

# -- Install util-linux 2.33.1.

util_linux='
http://mirrors.kernel.org/ubuntu/pool/main/libc/libcap-ng/libcap-ng0_0.7.9-2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/u/util-linux/libsmartcols1_2.33.1-0.1ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/n/ncurses/libtinfo6_6.1+20181013-2ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/s/shadow/login_4.5-1.1ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/u/util-linux/util-linux_2.33.1-0.1ubuntu2_amd64.deb
'

mkdir util_linux_233

for x in $util_linux; do
	printf "$x"
	wget -q -P util_linux_233 $x
done

dpkg --force-all -iR util_linux_233 > /dev/null
rm -r util_linux_233

# -- Install libc6 2.29.

libc6='
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.29-0ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.29-0ubuntu2_all.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.29-0ubuntu2_amd64.deb
'

mkdir libc6_229

for x in $libc6; do
	printf "$x"
	wget -q -P libc6_229 $x
done

dpkg --force-all -iR libc6_229 > /dev/null
rm -r libc6_229


# -- Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add system AppImages.
# -- Create /Applications directory for users.
# -- Rename AppImageUpdate and znx.

APPS_SYS='
https://github.com/Nitrux/znx/releases/download/continuous-development/znx_development
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
'

mkdir /Applications

for x in $APPS_SYS; do
	wget -q -P /Applications $x
done

chmod +x /Applications/*
mkdir -p /etc/skel/Applications

APPS_USR='
http://libreoffice.soluzioniopen.com/stable/basic/LibreOffice-6.2.3-x86_64.AppImage
http://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/AppImage/Waterfox-latest-x86_64.AppImage
http://repo.nxos.org/appimages/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
'

for x in $APPS_USR; do
    wget -q -P /etc/skel/Applications $x
done

chmod +x /etc/skel/Applications/*

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/AppImageUpdate
mv /Applications/znx_development /Applications/znx

# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q -O /bin/znx-gui https://raw.githubusercontent.com/Nitrux/nitrux-iso-tool/development/configs/znx-gui
chmod +x /bin/znx-gui


# -- Add config for SDDM.
# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
# -- Add kservice menu item for Dolphin for AppImageUpdate.
# -- Add custom launchers for Maui apps.
# -- Add policykit file for KDialog.

cp /configs/sddm.conf /etc
cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
cp /configs/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/
# cp /configs/org.kde.* /usr/share/applications
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

cp /configs/initramfs.conf /etc/initramfs-tools/

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

# -- Update the initramfs.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u


# -- Clean the filesystem.

apt -yy -qq purge --remove casper lupin-casper > /dev/null
apt -yy -qq autoremove > /dev/null
apt -yy -qq clean > /dev/null

# -- Use sources.list.nitrux for release.

/bin/cp /configs/sources.list.nitrux /etc/apt/sources.list
