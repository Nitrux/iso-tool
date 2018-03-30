#! /bin/sh

export LANG=C
export LC_ALL=C

PACKAGES=$(grep -v '^#' packages | tr '\n' ' ')

echo '
deb http://archive.ubuntu.com/ubuntu bionic main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu bionic-security main restricted universe multiverse
' >> /etc/apt/sources.list

apt-get update
apt-get install -y apt-transport-https wget ca-certificates

wget -q https://archive.neon.kde.org/public.key -O neon.key
if echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c; then
	apt-key add neon.key
	echo deb http://archive.neon.kde.org/dev/stable xenial main >> /etc/apt/sources.list
	echo deb http://archive.neon.kde.org/user xenial main >> /etc/apt/sources.list
fi
rm neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
if echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c; then
	apt-key add nxos.key
	echo deb http://repo.nxos.org/stable nxos main >> /etc/apt/sources.list
fi
rm nxos.key

apt-get update
apt-get -qq install $PACKAGES > /dev/null || exit 1
apt-get clean
useradd -m -U -G sudo,cdrom,adm,dip,plugdev -p '' me
echo 'me:nitrux' | chpasswd
echo host > /etc/hostname
systemctl enable sddm
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
rm /etc/resolv.conf
