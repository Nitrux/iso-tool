#! /bin/bash

set -x

export LANG=C
export LC_ALL=C

echo -e "\n"
echo -e "STARTING BOOTSTRAP."
echo -e "\n"


# -- Install basic packages.

echo -e "\n"
echo -e "INSTALLING BASIC PACKAGES."
echo -e "\n"

cp /configs/files/sources.list.eoan /etc/apt/sources.list

BASIC_PACKAGES='
apt-transport-https
apt-utils
ca-certificates
casper
dhcpcd5
gnupg2
language-pack-en
language-pack-en-base
libarchive13
libelf1
localechooser-data
locales
lupin-casper
user-setup
wget
xz-utils
'
apt update &> /dev/null
apt -yy install ${BASIC_PACKAGES//\\n/ } --no-install-recommends &> /dev/null


# -- Add key for Neon repository.
# -- Add key for Nitrux repository.
# -- Add key for Devuan repositories #1.
# -- Add key for Devuan repositories #2.
# -- Add key for the Proprietary Graphics Drivers PPA.
# -- Add key for Ubuntu repositories #1.
# -- Add key for Ubuntu repositories #2.
# -- Add key for Kubuntu Backports PPA.

echo -e "\n"
echo -e "ADD REPOSITORY KEYS."
echo -e "\n"

wget -q https://archive.neon.kde.org/public.key -O neon.key
echo -e "ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key" | sha256sum -c &&
apt-key add neon.key > /dev/null
rm neon.key

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1B69B2DA > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 541922FB > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BB23C00C61FC752C > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 > /dev/null
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C > /dev/null

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 2836CB0A8AC93F7A > /dev/null


# -- Use sources.list.devuan and update bionic base to devuan.
# -- WARNING

echo -e "\n"
echo -e "INSTALLING BASE SYSTEM."
echo -e "\n"

cp /configs/files/sources.list.nitrux /etc/apt/sources.list
cp /configs/files/sources.list.devuan /etc/apt/sources.list.d/devuan-repo.list
cp /configs/files/sources.list.eoan /etc/apt/sources.list.d/ubuntu-eoan-repo.list
cp /configs/files/sources.list.gpu /etc/apt/sources.list.d/gpu-ppa-repo.list
cp /configs/files/sources.list.backports /etc/apt/sources.list.d/backports-ppa-repo.list


NITRUX_BASE_PACKAGES='
nitrux-hardware-drivers
nitrux-minimal
nitrux-standard
'

apt update
apt -yy install ${NITRUX_BASE_PACKAGES//\\n/ } --no-install-recommends
apt -yy autoremove


# -- Add SysV as init.

echo -e "\n"
echo -e "ADD SYSVRC AS INIT."
echo -e "\n"

DEVUAN_INIT_PKGS='
init=1.56+nmu1+devuan2
init-system-helpers=1.56+nmu1+devuan2
sysv-rc
sysvinit-core
sysvinit-utils
'

apt -yy install ${DEVUAN_INIT_PKGS//\\n/ } --no-install-recommends --allow-downgrades


# -- Check that init system is not systemd.

echo -e "\n"
echo -e "CHECK INIT LINK."
echo -e "\n"

init --version
stat /sbin/init


# -- Add NX Desktop metapackage.

echo -e "\n"
echo -e "INSTALLING DESKTOP PACKAGES."
echo -e "\n"

NX_DESKTOP_PKG='
nx-desktop
'

apt -yy install ${NX_DESKTOP_PKG//\\n/ } --no-install-recommends


# -- No apt usage past this point. -- #
#WARNING


# -- Install the kernel.
#FIXME This should be synced to our repository.

echo -e "\n"
echo -e "INSTALLING KERNEL."
echo -e "\n"

kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-headers-5.4.21-050421_5.4.21-050421.202002191431_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-headers-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-image-unsigned-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4.21/linux-modules-5.4.21-050421-generic_5.4.21-050421.202002191431_amd64.deb
'

mkdir /latest_kernel

for x in $kfiles; do
echo -e "$x"
    wget -q -P /latest_kernel $x
done

dpkg -iR /latest_kernel &> /dev/null
dpkg --configure -a &> /dev/null
rm -r /latest_kernel


# -- Add /Applications to $PATH.

echo -e "\n"
echo -e "ADD /APPLICATIONS TO PATH."
echo -e "\n"

echo -e "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers


# -- Add vfio modules and files.
#FIXME This configuration should be included a in a package; replacing the default package like base-files.

echo -e "\n"
echo -e "ADD VFIO ENABLEMENT AND CONFIGURATION."
echo -e "\n"

echo "install vfio-pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "install vfio_pci /bin/vfio-pci-override-vga.sh" >> /etc/initramfs-tools/modules
echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep amdgpu pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep radeon pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "softdep i915 pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "vfio" >> /etc/initramfs-tools/modules
echo "vfio_iommu_type1" >> /etc/initramfs-tools/modules
echo "vfio_virqfd" >> /etc/initramfs-tools/modules
echo "options vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci" >> /etc/initramfs-tools/modules
echo "nvidia" >> /etc/initramfs-tools/modules
echo "amdgpu" >> /etc/initramfs-tools/modules
echo "radeon" >> /etc/initramfs-tools/modules
echo "i915" >> /etc/initramfs-tools/modules

echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_pci ids=" >> /etc/modules

cp /configs/files/asound.conf /etc/
cp /configs/files/asound.conf /etc/skel/.asoundrc
cp /configs/files/iommu_unsafe_interrupts.conf /etc/modprobe.d/
cp /configs/files/{amdgpu.conf,i915.conf,kvm.conf,nvidia.conf,qemu-system-x86.conf,radeon.conf,vfio_pci.conf,vfio-pci.conf} /etc/modprobe.d/
cp /configs/scripts/{vfio-pci-override-vga.sh,dummy.sh} /bin/

chmod a+x /bin/dummy.sh /bin/vfio-pci-override-vga.sh


# -- Add oh my zsh.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "ADD OH MY ZSH."
echo -e "\n"

git clone https://github.com/robbyrussell/oh-my-zsh.git /etc/skel/.oh-my-zsh


# -- Remove dash and use mksh as /bin/sh.
# -- Use zsh as default shell for all users.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "REMOVE DASH AND USE MKSH + ZSH."
echo -e "\n"

rm /bin/sh.distrib
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null
ln -sv /bin/mksh /bin/sh
/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path dash &> /dev/null

sed -i 's+SHELL=/bin/sh+SHELL=/bin/zsh+g' /etc/default/useradd


# -- Use GZIP compression when creating the initramfs.
# -- Add initramfs hook script.
# -- Add the persistence and update the initramfs.
# -- Add znx_dev_uuid parameter.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "UPDATE INITRAMFS."
echo -e "\n"

cp /configs/files/initramfs.conf /etc/initramfs-tools/
cp /configs/scripts/hook-scripts.sh /usr/share/initramfs-tools/hooks/
cat /configs/scripts/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
# cp /configs/scripts/iso_scanner /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan

update-initramfs -u
lsinitramfs /boot/initrd.img-5.4.21-050421-generic | grep vfio

rm /bin/dummy.sh


# -- Remove APT.
#FIXME This should be put in a package.

echo -e "\n"
echo -e "REMOVE APT."
echo -e "\n"

REMOVE_APT='
apt
apt-utils
apt-transport-https
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_APT//\\n/ } &> /dev/null


# -- Clean the filesystem.

echo -e "\n"
echo -e "REMOVE CASPER."
echo -e "\n"

REMOVE_PACKAGES='
casper
lupin-casper
'

/usr/bin/dpkg --remove --no-triggers --force-remove-essential --force-bad-path ${REMOVE_PACKAGES//\\n/ } &> /dev/null


# -- No dpkg usage past this point. -- #
#WARNING


# -- Use script to remove dpkg.

echo -e "\n"
echo -e "REMOVE DPKG."
echo -e "\n"

/configs/scripts/./rm-dpkg.sh
rm /configs/scripts/rm-dpkg.sh


echo -e "\n"
echo -e "EXITING BOOTSTRAP."
echo -e "\n"
