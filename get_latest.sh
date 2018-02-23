#! /bin/sh

echo " ==> Finding latest release..."
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/md5.txt
wget -q --show-progress https://github.com/luis-lavaire/mkiso/releases/download/continuous/URL

echo " ==> Downloading ISO..."
zsync -i ${1:-"nxos.iso"} $(cat URL)

echo -e "Verifying md5sum... \n"
cat md5.txt
md5sum nxos.iso
rm -rf URL md5.txt

echo -e "\n ==> Done. The file was saved as 'nxos.iso'"
