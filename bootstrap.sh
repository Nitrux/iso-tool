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
calamares
casper
cupt
dhcpcd5
fuse
gnupg2
grub-pc
grub-pc-bin
language-pack-en
language-pack-en-base
libarchive13
libelf1
localechooser-data
locales
lupin-casper
network-manager
user-setup
wget
xz-utils
'

apt update &> /dev/null
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends


# -- Add key for our repository.
# -- Add key for the Proprietary Graphics Drivers PPA.

printf "\n"
printf "ADD REPOSITORY KEYS."
printf "\n"

wget -q https://archive.neon.kde.org/public.key -O neon.key
	printf "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
	apt-key add neon.key > /dev/null
	rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null


# -- Use sources.list.build to build ISO.

cp /configs/files/sources.list.build /etc/apt/sources.list


# -- Update packages list and install packages.

printf "\n"
printf "INSTALLING DESKTOP."
printf "\n"

DESKTOP_PACKAGES='
nitrux-minimal
nitrux-standard
nitrux-hardware-drivers
nx-desktop-legacy
latte-dock
'

apt update &> /dev/null
apt -yy upgrade
apt -yy install ${DESKTOP_PACKAGES//\\n/ } --no-install-recommends
apt -yy --fix-broken install &> /dev/null
apt -yy purge --remove vlc &> /dev/null
apt -yy dist-upgrade


# -- Use sources.list.eoan to update packages

printf "\n"
printf "UPDATE BASE PACKAGES."
printf "\n"

cp /configs/files/sources.list.eoan /etc/apt/sources.list
apt -qq update

UPGRADE_OS_PACKAGES='
amd64-microcode
broadcom-sta-dkms
cupt
dkms
exfat-fuse
exfat-utils
go-mtpfs
grub-common
grub-efi-amd64
grub-efi-amd64-bin
grub-efi-amd64-signed
grub-pc
grub-pc-bin
grub2-common
i965-va-driver
initramfs-tools
initramfs-tools-bin
initramfs-tools-core
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
mpv
openresolv
openssh-client
openssl
sudo
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

apt update &> /dev/null
apt -yy install ${UPGRADE_OS_PACKAGES//\\n/ } --only-upgrade --no-install-recommends
apt -yy --fix-broken install
apt clean &> /dev/null
apt autoclean &> /dev/null


# -- Install the kernel.

printf "\n"
printf "INSTALLING KERNEL."
printf "\n"


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.1/linux-headers-5.4.1-050401_5.4.1-050401.201911290555_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.1/linux-headers-5.4.1-050401-generic_5.4.1-050401.201911290555_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.1/linux-image-unsigned-5.4.1-050401-generic_5.4.1-050401.201911290555_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.1/linux-modules-5.4.1-050401-generic_5.4.1-050401.201911290555_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
printf "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- No apt usage past this point. -- #


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


# -- Add fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.
#FIXME These fixes should be included in a package.

printf "\n"
printf "ADD MISC. FIXES."
printf "\n"

cp /configs/files/sddm.conf /etc
cp /configs/files/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/
/bin/cp /configs/files/Trolltech.conf /etc/xdg/Trolltech.conf
/bin/cp /configs/files/plasmanotifyrc /etc/xdg/plasmanotifyrc
rm -R /usr/share/icons/breeze_cursors /usr/share/icons/Breeze_Snow


# -- Add oh my zsh.
#FIXME This should be put in a package.

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


# -- Decrease timeout for systemd start and stop services.
#FIXME This should be put in a package.

sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf


# -- Disable systemd services not deemed necessary.
# -- use 'mask' to fully disable them.

systemctl mask avahi-daemon.service
systemctl disable cupsd.service
systemctl disable cupsd-browsed.service
systemctl disable NetworkManager-wait-online.service
systemctl disable keyboard-setup.service


# -- Fix for broken udev rules (yes, it is broken by default).
#FIXME This should be put in a package.

sed -i 's/ACTION!="add", GOTO="libmtp_rules_end"/ACTION!="bind", ACTION!="add", GOTO="libmtp_rules_end"/g' /lib/udev/rules.d/69-libmtp.rules


# -- Use sources.list.nitrux for release.

/bin/cp /configs/files/sources.list.nitrux /etc/apt/sources.list


# -- Overwrite file so cupt doesn't complain.
# -- Remove APT.
# -- Update package index using cupt.
#FIXME We probably need to provide our own cupt package which also does this.

printf "\n"
printf "REMOVE APT."
printf "\n"

REMOVE_APT='
apt 
apt-utils 
apt-transport-https
'

/bin/cp -a /configs/files/50command-not-found /etc/apt/apt.conf.d/50command-not-found
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_APT//\\n/ } &> /dev/null
cupt update


# -- Use XZ compression when creating the ISO.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.

printf "\n"
printf "UPDATE INITRAMFS."
printf "\n"

update-initramfs -u


# -- No dpkg usage past this point. -- #


printf "\n"
printf "EXITING BOOTSTRAP."
printf "\n"
