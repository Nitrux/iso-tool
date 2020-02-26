#! /bin/sh

# -- Exit on errors.

set -x

# -- Update xorriso and grub.

xorriso='
http://mirrors.kernel.org/ubuntu/pool/main/e/efivar/libefiboot1_37-2ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/e/efivar/libefivar1_37-2ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/gcc-9/gcc-9-base_9.2.1-25ubuntu1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/gcc-9/libgcc1_9.2.1-21ubuntu1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc-bin_2.30-0ubuntu3_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/libc6_2.30-0ubuntu3_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/glibc/locales_2.30-0ubuntu3_all.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/grub2/grub-common_2.04-1ubuntu16_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/grub2/grub-efi-amd64-bin_2.04-1ubuntu16_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/grub2/grub2-common_2.04-1ubuntu16_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/grub2/grub-pc-bin_2.04-1ubuntu16_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/g/grub2/grub-pc_2.04-1ubuntu16_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/n/ncurses/libtinfo6_6.1+20181013-2ubuntu2_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/r/readline/libreadline8_8.0-1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/main/r/readline/readline-common_8.0-1_all.deb
http://mirrors.kernel.org/ubuntu/pool/universe/libb/libburn/libburn4_1.5.0-1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/libi/libisoburn/libisoburn1_1.5.0-1build1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/libi/libisoburn/xorriso_1.5.0-1build1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/libi/libisofs/libisofs6_1.5.0-1_amd64.deb
http://mirrors.kernel.org/ubuntu/pool/universe/j/jigit/libjte1_1.21-1ubuntu1_amd64.deb
'

mkdir /latest_xorriso

for x in $xorriso; do
printf "$x"
    wget -q -P /latest_xorriso $x
done

dpkg -iR --force-all /latest_xorriso/
dpkg --configure -a
rm -r /latest_xorriso


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

cp -r configs $BUILD_DIR/

runch $BUILD_DIR -s bootstrap.sh || true

rm -rf $BUILD_DIR/configs


# -- Copy the kernel and initramfs to $ISO_DIR.

mkdir -p $ISO_DIR/boot

cp $(echo $BUILD_DIR/vmlinuz* | tr ' ' '\n' | sort | tail -n 1) $ISO_DIR/boot/kernel
cp $(echo $BUILD_DIR/initrd* | tr ' ' '\n' | sort | tail -n 1) $ISO_DIR/boot/initramfs


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
