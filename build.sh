#! /bin/sh 

set -e

FS_DIR=$PWD/root
ISO_DIR=$PWD/image
OUTPUT_DIR=$PWD/out

IMAGE_NAME=nitrux_release_testing.iso


# Function for running commands in a chroot.

run_chroot () {

	mountpoint -q $FS_DIR/dev/ || \
		rm -rf $FS_DIR/dev/*

	mount -t proc -o nosuid,noexec,nodev . $FS_DIR/proc
	mount -t sysfs -o nosuid,noexec,nodev,ro . $FS_DIR/sys
	mount -t devtmpfs -o mode=0755,nosuid . $FS_DIR/dev
	mount -t tmpfs -o nosuid,nodev,mode=0755 . $FS_DIR/run
	mount -t tmpfs -o mode=1777,strictatime,nodev,nosuid . $FS_DIR/tmp

	cp /etc/resolv.conf $FS_DIR/etc

	if [ -f $1 -a -x $1 ]; then
		cp $1 $FS_DIR/
		chroot $FS_DIR/ /$@
		rm -r $FS_DIR/$1
	else
		chroot $FS_DIR/ $@
	fi

	for d in $FS_DIR/*; do
		mountpoint -q $d && \
			umount -f $d
	done

	rm $FS_DIR/etc/resolv.conf

}


# Prepare the directory were the filesystem will be created.

mkdir -p $FS_DIR

wget -O base.tar.gz -q http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.1-base-amd64.tar.gz
tar xf base.tar.gz -C $FS_DIR


# Create the filesystem.

run_chroot bootstrap.sh || true


# Copy the kernel to $ISO_DIR.

cp $FS_DIR/vmlinuz $ISO_DIR/boot/kernel


# Customize the initramfs file and put it in $ISO_DIR.

cat persistence >> $FS_DIR/usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
run_chroot update-initramfs -u
cp $FS_DIR/initrd.img $ISO_DIR/boot/initramfs


# Clean the filesystem.

run_chroot ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so # needed for the software center
run_chroot ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0 # needed for the software center
run_chroot ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0 # needed for the software center

run_chroot apt-get -yy install --only-upgrade base-files=10.4+nxos

run_chroot apt-get -yy purge --remove casper lupin-casper kwalletmanager plasma-discover xpra at-spi2-core build-essential colord colord-data dpkg-dev enchant gdbserver geoclue-2.0 gnome-terminal gnome-terminal-data gsfonts gvfs gvfs-common gvfs-daemons gvfs-libs i965-va-driver iio-sensor-proxy  ippusbxd javascript-common kamera kgamma5 kwrited media-player-info mysql-common nautilus-extension-gnome-terminal netpbm network-manager-pptp networkd-dispatcher openresolv patch ppp pptp-linux qtwayland5 rake rtkit ruby ruby-did-you-mean ruby-minitest ruby-net-telnet ruby-power-assert ruby-test-unit ruby2.5 rubygems-integration sane-utils sni-qt sonnet-plugins vbetool vlc-plugin-samba wireless-tools yelp yelp-xsl
run_chroot apt-get -yy autoremove


rm -rf $FS_DIR/tmp/* \
	$FS_DIR/boot \
	$FS_DIR/vmlinuz* \
	$FS_DIR/initrd.img* \
	$FS_DIR/var/log/* \
	$FS_DIR/var/lib/dbus/machine-id


# Compress the root filesystem.

(while :; do sleep 300; echo '.'; done) &

echo "Compressing the root filesystem"
mkdir -p $ISO_DIR/casper
mksquashfs $FS_DIR $ISO_DIR/casper/filesystem.squashfs -comp xz -no-progress
kill $!


# Create the output directory.

mkdir $OUTPUT_DIR


# Generate the ISO image.

(
	cd $ISO_DIR
	echo -n $(du -sx --block-size=1 . | tail -n 1 | awk '{ print $1 }') > casper/filesystem.size

	xorriso -as mkisofs -r -J -l \
		-V 'NITRUX_OS' \
		-e boot/grub/efi.img \
		-no-emul-boot \
		-o $OUTPUT_DIR/$IMAGE_NAME .
)


# Embed the update information in the image.

UPDATE_URL=http://88.198.66.58:8000/$IMAGE_NAME.zsync
echo $UPDATE_URL | dd of=$OUTPUT_DIR/$IMAGE_NAME bs=1 seek=33651 count=512 conv=notrunc


# Generate the zsync file.

zsyncmake $OUTPUT_DIR/$IMAGE_NAME -u ${UPDATE_URL/.zsync} -o $OUTPUT_DIR/$IMAGE_NAME.zsync


# Calculate the checksum.

sha256sum $OUTPUT_DIR/$IMAGE_NAME > $OUTPUT_DIR/$IMAGE_NAME.sha256sum


# Deploy the image.

export SSHPASS=$DEPLOY_PASS

(sleep 300; echo '.') &
for f in $OUTPUT_DIR/$IMAGE_NAME*; do
    sshpass -e scp -o stricthostkeychecking=no $f $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH > /dev/null
done
