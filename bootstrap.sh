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


# -- Add key for our repository.
wget -q http://repo.nxos.org/public.key -O nxos.key
printf "b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key" | sha256sum -c &&
	apt-key add nxos.key > /dev/null

# -- Add key for the Graphics Driver PPA.
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C > /dev/null

# -- Add key for the Ubuntu-X PPA.
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF1CDFA9 > /dev/null

# -- Remove key files
rm nxos.key


# -- Use optimized sources.list.

cp /configs/sources.list /etc/apt/sources.list


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package
# -- avoiding recommended packages.

apt -qq update > /dev/null
apt -yy -qq upgrade > /dev/null
apt -yy -qq install ${PACKAGES//\\n/ } --no-install-recommends > /dev/null
apt -yy -qq purge --remove vlc > /dev/null


# -- Add AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous-stable/znx_stable
http://repo.nxos.org/appimages/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
http://repo.nxos.org/appimages/ungoogled-chromium_71.0.3578.98-2_linux.AppImage
http://libreoffice.soluzioniopen.com/pre-releases/beta2/standard/LibreOffice-pre.standard-x86_64.AppImage
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

# -- Add AppImages to the skel /Applications dir. Then remove AppImages from root /Applications, otherwise
# -- the AppImages will not display an icon when added to the menu launcher by appimaged.

cp -a /Applications/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage /etc/skel/Applications
cp -a /Applications/ungoogled-chromium_71.0.3578.98-2_linux.AppImage /etc/skel/Applications
cp -a /Applications/LibreOffice-pre.standard-x86_64.AppImage /etc/skel/Applications

rm /Applications/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
rm /Applications/ungoogled-chromium_71.0.3578.98-2_linux.AppImage
rm /Applications/LibreOffice-pre.standard-x86_64.AppImage


# -- Rename AppImageUpdate and znx.

mv /Applications/AppImageUpdate-x86_64.AppImage /Applications/AppImageUpdate
mv /Applications/znx_stable /Applications/znx


# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q -O /bin/znx-gui https://raw.githubusercontent.com/Nitrux/nitrux-iso-tool/development/configs/znx-gui
chmod +x /bin/znx-gui


# -- For now, the software center, libappimage and libappimageinfo provide the same library
# -- and to install each package the library must be overwritten each time.

nxsc='
http://repo.nxos.org/stable/pool/main/liba/libappimageinfo/libappimageinfo_0.1.1-1_amd64.deb
http://repo.nxos.org/stable/pool/main/n/nx-software-center-plasma/nx-software-center-plasma_2.3-2_amd64.deb
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


-- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
-- firejail should be automatically used by the daemon to sandbox AppImages.

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git369c33a.travis92_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done

dpkg -iR appimaged_deb > /dev/null
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


# -- Add custom launchers for Maui apps.

cp /configs/org.kde.* /usr/share/applications


# -- Add policykit file for KDialog.

cp /configs/org.freedesktop.policykit.kdialog.policy /usr/share/polkit-1/actions/


# -- Add vfio modules and files.

echo "softdep nvidia pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "# softdep amdgpu pre: vfio vfio_pci" >> /etc/initramfs-tools/modules
echo "vfio" >> /etc/initramfs-tools/modules
echo "vfio_iommu_type1" >> /etc/initramfs-tools/modules
echo "vfio_virqfd" >> /etc/initramfs-tools/modules
echo "options vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci ids=" >> /etc/initramfs-tools/modules
echo "vfio_pci" >> /etc/initramfs-tools/modules
echo "nvidia" >> /etc/initramfs-tools/modules
echo "# amdgpu" >> /etc/initramfs-tools/modules

echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci ids=" >> /etc/modules

cp /configs/amdgpu.conf /etc/modprobe.d/
cp /configs/nvidia.conf /etc/modprobe.d/
cp /configs/vfio_pci.conf /etc/modprobe.d/
cp /configs/iommu_unsafe_interrupts.conf /etc/modprobe.d/
cp /configs/kvm.conf /etc/modprobe.d/

cp /configs/asound.conf /etc/
cp /configs/asound.conf /etc/skel/.asoundrc


# -- Install the latest stable kernel.

printf "INSTALLING NEW KERNEL."


kfiles='
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.20.6/linux-headers-4.20.6-042006_4.20.6-042006.201901310331_all.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.20.6/linux-headers-4.20.6-042006-generic_4.20.6-042006.201901310331_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.20.6/linux-image-unsigned-4.20.6-042006-generic_4.20.6-042006.201901310331_amd64.deb
https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.20.6/linux-modules-4.20.6-042006-generic_4.20.6-042006.201901310331_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	printf "$x"
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel > /dev/null
rm -r latest_kernel


# -- Update the initramfs.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
update-initramfs -u


# -- Clean the filesystem.

apt -yy -qq purge --remove casper lupin-casper > /dev/null
apt -yy -qq autoremove > /dev/null
apt -yy -qq clean > /dev/null

