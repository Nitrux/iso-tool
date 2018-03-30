#! /bin/sh

export LANG=C
export LC_ALL=C

PACKAGES=$(grep -v '^#' packages | tr '\n' ' ')

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
if echo de7501e2951a9178173f67bdd29a9de45a572f19e387db5f4e29eb22100c2d0e nxos.key | sha256sum -c; then
	apt-key add nxos.key
	echo deb http://repo.nxos.org nxos main >> /etc/apt/sources.list
	echo deb http://repo.nxos.org nxos testing >> /etc/apt/sources.list
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
