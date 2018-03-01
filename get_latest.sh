#! /bin/sh

mkdir latest
cd latest

echo " ==> Fetching latest release..."
for url in $(wget -qO - https://github.com/luis-lavaire/mkiso/releases/download/continuous/urls); do
	wget -q -nc --show-progress $url
done

echo " ==> Verifying the file..."
sha256sum -c checksum
