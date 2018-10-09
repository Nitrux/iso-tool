#! /bin/sh

export LANG=C
export LC_ALL=C

# Install packages for squashfs creation

PACKAGES='
user-setup
localechooser-data
cifs-utils
casper
lupin-casper
dhcpcd5
nomad-desktop
'
apt-get -y -qq update
apt-get -y -qq install -y apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends

# Use optimized sources.list. The LTS repositories are used to support the KDE Neon repository since these packages are built against the latest LTS release of Ubuntu.

rm /etc/apt/sources.list
echo '#######################' >> /etc/apt/sources.list
echo '# Ubuntu Repos Bionic #' >> /etc/apt/sources.list
echo '#######################' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Main' >> /etc/apt/sources.list
echo 'deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Updates' >> /etc/apt/sources.list
echo 'deb http://archive.ubuntu.com/ubuntu bionic-security main restricted universe multiverse' >> /etc/apt/sources.list
echo 'deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu bionic-proposed main restcited universe multiverse' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu bionic-backports main restcited universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Partner' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu bionic partner' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list

apt-get -y -qq update

wget -q https://archive.neon.kde.org/public.key -O neon.key
if echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c; then
	apt-key add neon.key
	echo '##################' >> /etc/apt/sources.list
	echo '# KDE Neon Repos #' >> /etc/apt/sources.list
	echo '##################' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
	echo '# deb http://archive.neon.kde.org/dev/unstable/ bionic main' >> /etc/apt/sources.list
	echo 'deb http://archive.neon.kde.org/dev/stable/ bionic main' >> /etc/apt/sources.list
	echo '# deb http://archive.neon.kde.org/user bionic main' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
fi
rm neon.key

apt-get -y -qq update

wget -q http://repo.nxos.org/public.key -O nxos.key
if echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c; then
	apt-key add nxos.key
	echo '################' >> /etc/apt/sources.list
	echo '# Nitrux Repos #' >> /etc/apt/sources.list
	echo '################' >> /etc/apt/sources.list
	echo 'deb http://repo.nxos.org/stable/ nxos main' >> /etc/apt/sources.list
	echo 'deb http://repo.nxos.org/development/ nxos main' >> /etc/apt/sources.list
	echo 'deb http://repo.nxos.org/testing/ nxos main' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
fi
rm nxos.key

# Update package list and then install packages defined in list

apt-get -y -qq update
apt-get -y -qq install -y $(echo $PACKAGES | tr '\n' ' ') --no-install-recommends > /dev/null
apt-get -y -qq clean


# Install AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
'

mkdir /Applications

for x in $(echo $APPS | tr '\n' ' '); do
	wget -qP /Applications $x
done

chmod +x /Applications/*


# Add znx-gui.

printf \
'[Desktop Entry]
Name=znx
GenericName=Operating System manager
Comment=Operating System manager.
Icon=live-installer
Type=Application
Terminal=false
Exec=sudo -H znx-gui
TryExec=znx-gui
Categories=Utilities;System;
Keywords=deployer;live;

' > /usr/share/applications/znx-gui.desktop

wget -q https://raw.githubusercontent.com/Nitrux/znx-gui/master/znx-gui -O /bin/znx-gui
chmod +x /bin/znx-gui


# Install the latest stable kernel

kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.12/linux-headers-4.18.12-041812_4.18.12-041812.201810032137_all.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.12/linux-headers-4.18.12-041812-generic_4.18.12-041812.201810032137_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.12/linux-image-unsigned-4.18.12-041812-generic_4.18.12-041812.201810032137_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.12/linux-modules-4.18.12-041812-generic_4.18.12-041812.201810032137_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
rm -r latest_kernel

# Install Maui Apps Debs

mauipkgs='
https://raw.githubusercontent.com/UriHerrera/storage/master/mauikit-framework_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/vvave_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/pix_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/index_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/buho_0.1-1_amd64.deb
'

mkdir maui_debs

for x in $mauipkgs; do
	wget -q -P maui_debs $x
done

dpkg -iR maui_debs
rm -r maui_debs


# Install Software Center Maui port

nxsc='
https://raw.githubusercontent.com/UriHerrera/storage/master/libappimageinfo_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/nx-software-center_2.3-1_amd64.deb
'

mkdir nxsc_deps

for x in $nxsc; do
	wget -q -P nxsc_deps $x
done

dpkg --force-all -iR nxsc_deps # For now the software center, libappimage and libappimageinfo provide the same library and to install each one it must be overriden each time.
rm -r nxsc_deps

ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so # needed for the software center
ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0 # needed for the software center
ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0 # needed for the software center


# Install Nomad Desktop meta package avoiding recommended packages from deps

apt-get -yy -q install --only-upgrade base-files=10.4+nxos

# Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers
