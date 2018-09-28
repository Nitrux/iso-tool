#! /bin/sh

export LANG=C
export LC_ALL=C

PACKAGES='
casper
lupin-casper
nomad-desktop
plymouth-label
plymouth-themes

iputils-ping
dhcpcd5
'
apt-get -qq update
apt-get -qq install -y apt-transport-https wget ca-certificates gnupg2

# Use optimized sources.list. This sources.list includes the current Ubuntu development release as the main repository and also includes the latest LTS release.
# The LTS repositories are included to add support for the KDE Neon repository since these packages are built against this release of Ubuntu.

rm /etc/apt/sources.list
echo '################' >> /etc/apt/sources.list
echo '# Ubuntu Repos #' >> /etc/apt/sources.list
echo '################' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Main' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Updates' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu cosmic-proposed main restcited universe multiverse' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu cosmic-backports main restcited universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Partner' >> /etc/apt/sources.list
echo '# deb http://archive.ubuntu.com/ubuntu cosmic partner' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '#################' >> /etc/apt/sources.listd
echo '# Ubuntu Source #' >> /etc/apt/sources.list
echo '#################' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Main' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu cosmic main restricted universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Updates' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu cosmic-security main restricted universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu cosmic-updates main restricted universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu cosmic-proposed main restcited universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu cosmic-backports main restcited universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '#######################################################################################' >> /etc/apt/sources.list
echo '#	The Bionic repositories are included to provide support for KDE Neon repositories	#' >> /etc/apt/sources.list
echo '#	Since there are times when updates request packages that were removed in newer		#' >> /etc/apt/sources.list
echo '#	versions of Ubuntu resulting in APT holding back the upgrades. This allows the 	    #' >> /etc/apt/sources.list
echo '#	installation of these packages.                                              	    #' >> /etc/apt/sources.list
echo '#######################################################################################' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '#######################' >> /etc/apt/sources.list
echo '#	Ubuntu Repos Bionic #' >> /etc/apt/sources.list
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
echo '########################' >> /etc/apt/sources.list
echo '# Ubuntu Source Bionic #' >> /etc/apt/sources.list
echo '########################' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Main' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list
echo '### Updates' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu bionic-security main restricted universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu bionic-proposed main restcited universe multiverse' >> /etc/apt/sources.list
echo '# deb-src http://archive.ubuntu.com/ubuntu bionic-backports main restcited universe multiverse' >> /etc/apt/sources.list
echo '' >> /etc/apt/sources.list

wget -q https://archive.neon.kde.org/public.key -O neon.key
if echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c; then
	apt-key add neon.key
	echo '##################' >> /etc/apt/sources.list
	echo '#	KDE Neon Repos #' >> /etc/apt/sources.list
	echo '##################' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
	echo '# deb http://archive.neon.kde.org/dev/unstable/ bionic main' >> /etc/apt/sources.list
	echo 'deb http://archive.neon.kde.org/dev/stable/ bionic main' >> /etc/apt/sources.list
	echo '# deb http://archive.neon.kde.org/user bionic main' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
fi
rm neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
if echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c; then
	apt-key add nxos.key
	echo '################' >> /etc/apt/sources.list
	echo '#	Nitrux Repos #' >> /etc/apt/sources.list
	echo '################' >> /etc/apt/sources.list
	echo 'deb http://repo.nxos.org/stable/ nxos main' >> /etc/apt/sources.list
	echo 'deb http://repo.nxos.org/development/ nxos main' >> /etc/apt/sources.list
	echo '# deb http://repo.nxos.org/testing/ nxos main' >> /etc/apt/sources.list
	echo '' >> /etc/apt/sources.list
fi
rm nxos.key

apt-get -qq update
apt-get -qq install -y $(echo $PACKAGES | tr '\n' ' ') > /dev/null
apt-get clean


# Install AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
'

mkdir /Applications

for x in $(echo $APPS | tr '\n' ' '); do
	wget -qP /Applications $x
done

chmod +x /Applications/*


# Install the latest kernel.

kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.10/linux-headers-4.18.10-041810-generic_4.18.10-041810.201809260332_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.10/linux-image-unsigned-4.18.10-041810-generic_4.18.10-041810.201809260332_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.10/linux-modules-4.18.10-041810-generic_4.18.10-041810.201809260332_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
