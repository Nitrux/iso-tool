#! /bin/sh

mkdir -p latest
cd latest

echo " ==> Finding latest release..."
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/md5.txt
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/URL

echo " ==> Downloading ISO..."
wget $(cat URL) -O nitruxos.iso

echo "Calculating md5sum..."
if [ "$(cat md5.txt)" == "$(md5sum nitruxos.iso)" ]; then
	echo " ==> Successfully downloaded 'nitruxos.iso.'"
else
	echo " ==> The file is corrupted or the download failed."
	echo -n " ==> Do you want to remove the files? [Y/n]"
	_ANS=Y
	read _ANS

	if [ $_ANS == Y ]; then
		rm -rf nitruxos.iso
	fi
fi

rm -rf URL md5.txt

echo " ==> Done. The file was saved as latest/nitruxos.iso"
