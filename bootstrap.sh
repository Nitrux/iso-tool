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
nomad-desktop
'


# -- Install basic packages.

apt -qq update > /dev/null
apt -yy -qq install apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends > /dev/null


# -- Use optimized sources.list. The LTS repositories are used to support the KDE Neon repository since these
# -- packages are built against the latest LTS release of Ubuntu.

wget -q https://archive.neon.kde.org/public.key -O neon.key
printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
	apt-key add neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
printf "b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key" | sha256sum -c &&
	apt-key add nxos.key

# -- Add key for the Graphics Driver PPA
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C

# -- Add key for the Ubuntu-X PPA
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF1CDFA9

rm neon.key
rm nxos.key

cp /configs/sources.list /etc/apt/sources.list


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package
# -- avoiding recommended packages.

apt -qq update > /dev/null
apt -yy -qq upgrade > /dev/null
apt -yy -qq install ${PACKAGES//\\n/ } --no-install-recommends


# -- Add AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/AppImages/ungoogled-chromium_70.0.3538.77-1_linux.AppImage
https://libreoffice.soluzioniopen.com/stable/fresh/LibreOffice-fresh.basic-x86_64.AppImage
https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
'

mkdir /Applications

for x in $APPS; do
	wget -q -P /Applications $x
done

chmod +x /Applications/*


# -- Create /Applications dirrectory for users. This directory "should" be created by the Software Center.
# -- Downloading AppImages with the SC will fail if this directory doesn't exist.

mkdir /etc/skel/Applications

# -- Add AppImages to the user /Applications dir. Then remove AppImages from root /Applications, otherwise
# -- the AppImages will not display an icon when added to the menu launcher by appimaged.

mv /Applications/* /etc/skel/Applications


# -- Rename AppImageUpdate file.

mv /etc/skel/Applications/AppImageUpdate* /etc/skel/Applications/AppImageUpdate


# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q -O /bin/znx-gui https://raw.githubusercontent.com/Nitrux/znx-gui/master/znx-gui
chmod +x /bin/znx-gui


# -- Install Maui Apps Debs.

mauipkgs='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/libs/mauikit-framework_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/vvave_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/pix_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/index_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/buho_0.1-1_amd64.deb
'

mkdir maui_debs

for x in $mauipkgs; do
	wget -q -P maui_debs $x
done

dpkg --force-all -iR maui_debs
rm -r maui_debs


# -- Install Software Center.
# -- For now, the software center, libappimage and libappimageinfo provide the same library
# -- and to install each package the library must be overwritten each time.

nxsc='
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/libs/libappimageinfo_0.1.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/Debs/apps/nx-software-center-plasma_2.3-2_amd64.deb
'

mkdir nxsc_deps

for x in $nxsc; do
	wget -q -P nxsc_deps $x
done

dpkg --force-all -iR nxsc_deps > /dev/null
rm -r nxsc_deps

ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so
ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0
ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0


# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-gita3b100b.travis57_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done

dpkg --force-all -iR appimaged_deb
rm -r appimaged_deb


# -- Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add config for SDDM.

cp /configs/sddm.conf /etc


# -- Fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.

cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/


# -- Add kservice menu item for Dolphin for AppImageUpdate.

cp /configs/appimageupdate.desktop /usr/share/kservices5/ServiceMenus/


# -- Install the latest stable kernel.

printf "------- INSTALLING NEW KERNEL. -------"


kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.5/linux-headers-4.19.5-041905_4.19.5-041905.201811271131_all.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.5/linux-headers-4.19.5-041905-generic_4.19.5-041905.201811271131_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.5/linux-image-unsigned-4.19.5-041905-generic_4.19.5-041905.201811271131_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.5/linux-modules-4.19.5-041905-generic_4.19.5-041905.201811271131_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
rm -r latest_kernel


# -- Update the initramfs.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u


# -- Clean the filesystem.

apt -yy -qq purge --remove phonon4qt5-backend-vlc vlc casper lupin-casper > /dev/null
apt -yy -qq autoremove > /dev/null
apt -yy -qq clean > /dev/null
