#! /bin/sh

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


# # -- Make /bin, /sbin and /usr/sbin, symlinks to /usr/bin.
# 
# # make copies of commands before moving
# cp /bin/mv /usr/bin/mv_clone
# cp /bin/ln /usr/bin/ln_clone
# 
# # copy contents to usr/bin, delete dirs and create symlinks
# mv_clone /bin/* /usr/bin
# rm -rf /bin
# ln_clone -sv /usr/bin /bin
# 
# mv_clone /sbin/* /usr/bin
# rm -rf /sbin
# ln_clone -sv /usr/bin /sbin
# 
# mv_clone /usr/sbin/* /usr/bin
# rm -rf /usr/sbin
# ln_clone -sv /usr/bin /usr/sbin
# 
# # delete copies of commands
# rm /usr/bin/mv_clone /usr/bin/ln_clone


# -- Install basic packages.

apt -qq update
apt -yy -qq install apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends > /dev/null


# -- Use optimized sources.list. The LTS repositories are used to support the KDE Neon repository since these
# -- packages are built against the latest LTS release of Ubuntu.

wget -q https://archive.neon.kde.org/public.key -O neon.key
echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c &&
	apt-key add neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c &&
	apt-key add nxos.key
	
cp /configs/sources.list /etc/apt/sources.list

rm neon.key
rm nxos.key


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package
# -- avoiding recommended packages.

apt -qq update
apt -yy install $(echo $PACKAGES | tr '\n' ' ') --no-install-recommends
apt -yy -qq install --only-upgrade base-files=10.4+nxos > /dev/null
apt -qq clean
apt -qq autoclean


# -- Install AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
'

mkdir /Applications

for x in $(echo $APPS | tr '\n' ' '); do
	wget -qP /Applications $x
done

chmod +x /Applications/*


# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q https://raw.githubusercontent.com/Nitrux/znx-gui/master/znx-gui -O /bin/znx-gui
chmod +x /bin/znx-gui


# -- Install the latest stable kernel.

kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.13/linux-headers-4.18.13-041813_4.18.13-041813.201810100332_all.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.13/linux-headers-4.18.13-041813-generic_4.18.13-041813.201810100332_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.13/linux-image-unsigned-4.18.13-041813-generic_4.18.13-041813.201810100332_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.18.13/linux-modules-4.18.13-041813-generic_4.18.13-041813.201810100332_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
rm -r latest_kernel


# -- Install Maui Apps Debs.

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


# -- Install Software Center Maui port.

nxsc='
https://raw.githubusercontent.com/UriHerrera/storage/master/libappimageinfo_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/nx-software-center_2.3-1_amd64.deb
'

mkdir nxsc_deps

for x in $nxsc; do
	wget -q -P nxsc_deps $x
done
dpkg --force-all -iR nxsc_deps
rm -r nxsc_deps


# -- For now, the software center, libappimage and libappimageinfo provide the same library and to install each one it must be overriden each time.

ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so
ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0
ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0


# -- Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add config for SDDM.

cp /configs/sddm.conf /etc


# -- Modify the initramfs code.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u
