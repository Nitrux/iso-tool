#! /bin/sh

# -- Exit on errors.

set -x


# -- Use sources.list.focal to update xorriso and GRUB.
#WARNING

wget -O /etc/apt/sources.list https://raw.githubusercontent.com/Nitrux/nitrux-iso-tool/dev-test/configs/files/sources.list.focal

XORRISO_PACKAGES='
gcc-10-base
grub-common
grub-efi-amd64-bin
grub-pc
grub-pc-bin
grub2-common
libburn4
libc-bin
libc6
libefiboot1
libefivar1
libgcc1
libisoburn1
libisofs6
libjte1
libreadline8
libtinfo6
locales
readline-common
xorriso
'

apt update &> /dev/null
apt -yy install ${XORRISO_PACKAGES//\\n/ } --only-upgrade --no-install-recommends &> /dev/null


# -- Prepare the directories for the build.

BUILD_DIR=$(mktemp -d)
ISO_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)

CONFIG_DIR=$PWD/configs


# -- The name of the ISO image.

IMAGE=nitrux-$(printf $TRAVIS_BRANCH | sed 's/master/stable/')-amd64.iso
UPDATE_URL=http://repo.nxos.org:8000/${IMAGE%.iso}.zsync
HASH_URL=http://repo.nxos.org:8000/${IMAGE%.iso}.md5sum


# -- Prepare the directory where the filesystem will be created.

wget -O base.tar.gz -q http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.4-base-amd64.tar.gz
tar xf base.tar.gz -C $BUILD_DIR


# -- Populate $BUILD_DIR.

wget -qO /bin/runch https://raw.githubusercontent.com/Nitrux/tools/master/runch
chmod +x /bin/runch

cat bootstrap.sh | runch $BUILD_DIR sh || true


# -- Copy the kernel and initramfs to $ISO_DIR.

mkdir -p $ISO_DIR/boot
ls -l $BUILD_DIR/boot

# -- BUG vmlinuz and initrd are not moved to / they're put and left at /boot

cp $(echo $BUILD_DIR/boot/vmlinuz* | tr ' ' '\n' | sort | tail -n 1) $ISO_DIR/boot/kernel
cp $(echo $BUILD_DIR/boot/initrd* | tr ' ' '\n' | sort | tail -n 1) $ISO_DIR/boot/initramfs

ls -l $BUILD_DIR/


# -- Compress the root filesystem.

(while :; do sleep 300; printf "."; done) &

mkdir -p $ISO_DIR/casper
mksquashfs $BUILD_DIR $ISO_DIR/casper/filesystem.squashfs -comp gzip -no-progress -b 16384


# -- Generate the ISO image.

wget -qO /bin/mkiso https://raw.githubusercontent.com/Nitrux/tools/master/mkiso
chmod +x /bin/mkiso

git clone https://github.com/Nitrux/nitrux-grub-theme grub-theme

mkiso \
	-V "NITRUX" \
	-b \
	-e \
	-u "$UPDATE_URL" \
	-s "$HASH_URL" \
	-r "${TRAVIS_COMMIT:0:7}" \
	-g $CONFIG_DIR/files/grub.cfg \
	-g $CONFIG_DIR/files/loopback.cfg \
	-t grub-theme/nitrux \
	$ISO_DIR $OUTPUT_DIR/$IMAGE


# -- Calculate the checksum.

md5sum $OUTPUT_DIR/$IMAGE > $OUTPUT_DIR/${IMAGE%.iso}.md5sum


# -- Generate the zsync file.

zsyncmake \
	$OUTPUT_DIR/$IMAGE \
	-u ${UPDATE_URL%.zsync}.iso \
	-o $OUTPUT_DIR/${IMAGE%.iso}.zsync


# -- Upload the ISO image.

cd $OUTPUT_DIR

export SSHPASS=$DEPLOY_PASS

for f in *; do
    sshpass -e scp -q -o stricthostkeychecking=no $f $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH
done
