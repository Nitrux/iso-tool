#! /bin/sh

debootstrap --verbose --components=main,restricted,universe,multiverse,stable \
	--include=linux-image-generic \
	--exclude=nano \
	--arch amd64 xenial . http://us.archive.ubuntu.com/ubuntu/
