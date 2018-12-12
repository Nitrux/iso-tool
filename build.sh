#! /bin/sh 

# -- Exit on errors.

set -e


# -- Prepare the directories for the build.

BUILD_DIR=$(mktemp -d)
ISO_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)

CONFIG_DIR=$PWD/configs


# -- The name of the ISO image.

IMAGE=nitrux_release_$(printf $TRAVIS_BRANCH | sed 's/master/stable/')


# -- Prepare the directory where the filesystem will be created.

wget -O base.tar.gz -q http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.1-base-amd64.tar.gz
tar xf base.tar.gz -C $BUILD_DIR


# -- Populate $BUILD_DIR.

wget -qO /bin/runc https://raw.githubusercontent.com/Nitrux/runc/master/runc
chmod +x /bin/runc

runc -d configs $BUILD_DIR bootstrap.sh || true


# -- Copy the kernel and initramfs to $ISO_DIR.

mkdir -p $ISO_DIR/boot

cp $BUILD_DIR/vmlinuz $ISO_DIR/boot/kernel
cp $BUILD_DIR/initrd.img $ISO_DIR/boot/initramfs


# -- Compress the root filesystem.

(while :; do sleep 300; printf ".\n"; done) &

mkdir -p $ISO_DIR/casper
mksquashfs $BUILD_DIR $ISO_DIR/casper/filesystem.squashfs -comp xz -no-progress


# -- Write the commit hash that generated the image.

printf "${TRAVIS_COMMIT:0:7}" > $ISO_DIR/.git-commit


# -- Generate the ISO image.

wget -qO /bin/mkiso https://raw.githubusercontent.com/Nitrux/mkiso/master/mkiso
chmod +x /bin/mkiso

mkiso \
	-d $ISO_DIR \
	-V "NITRUX" \
	-g $CONFIG_DIR/grub.cfg \
	-g $CONFIG_DIR/loopback.cfg \
	-t $CONFIG_DIR/nitrux-grub-theme \
	-o $OUTPUT_DIR/$IMAGE


# -- Embed the update information in the image.

UPDATE_URL=http://repo.nxos.org:8000/$IMAGE.zsync
printf "zsync|$UPDATE_URL" | dd of=$OUTPUT_DIR/$IMAGE bs=1 seek=33651 count=512 conv=notrunc


# -- Calculate the checksum.

sha256sum $OUTPUT_DIR/$IMAGE > $OUTPUT_DIR/$IMAGE.sha256sum


# -- Generate the zsync file.

zsyncmake \
	$OUTPUT_DIR/$IMAGE \
	-u ${UPDATE_URL/.zsync} \
	-o $OUTPUT_DIR/$IMAGE.zsync


# -- Upload the ISO image.

cd $OUTPUT_DIR

export SSHPASS=$DEPLOY_PASS

for f in *; do
    sshpass -e scp -q -o stricthostkeychecking=no $f $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH
done
