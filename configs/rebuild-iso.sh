#! /bin/sh


# -- Exit on error.

set -e


# -- Clean on exit.

clean () {

	mountpoint -q $UPPER_DIR &&
		umount $UPPER_DIR

	rm -rf \
		$UPPER_DIR \
		$WORK_DIR

}

trap clean EXIT HUP INT TERM


# -- Wrapper for errors.

error () {
	printf %b "$0: \e[31mError\e[0m: $@\n" >& 2
	exit 1
}


# -- Prepare the environment for the ISO image generation.

mountpoint -q /cdrom ||
	error "Not running from a live session."

LOWER_DIR=/cdrom
UPPER_DIR=$(mktemp -d)
WORK_DIR=$(mktemp -d)

mount -t overlay \
	-o lowerdir=$LOWER_DIR \
	-o upperdir=$UPPER_DIR \
	-o workdir=$WORK_DIR \
	. $UPPER_DIR


# -- Generate the image.

IMAGE=/NITRUX.ISO

mkiso -V NITRUX -d $UPPER_DIR -o $IMAGE &&
	printf "$IMAGE.\n" ||
	error "Failed to generate $IMAGE."
