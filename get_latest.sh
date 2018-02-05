#! /bin/sh

echo " ==> Finding latest release..."
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/{md5.txt,URL}

echo " ==> Downloading ISO..."
wget $(cat URL) -O nitruxos.iso

echo "Calculating md5sum..."
if [ "$(cat md5.txt)" == "$(md5sum nitruxos.iso)" ]; then
	echo " ==> Successfully downloaded 'nitruxos.iso.'"
fi
