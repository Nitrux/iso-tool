#! /bin/sh

mkdir -p latest
cd latest

echo " ==> Finding latest release..."
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/md5.txt
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/URL

echo " ==> Downloading ISO..."
wget -q --show-progress $(cat URL) -O nitruxos.iso

echo -e "Verifying md5sum... \n"
cat md5.txt
md5sum nitruxos.iso
rm -rf URL md5.txt

echo -e "\n ==> Done. The file was saved as 'nitruxos.iso'"
