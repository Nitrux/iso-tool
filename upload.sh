#! /bin/sh

mkdir release

md5sum nitruxos.iso > release/md5.txt

echo " ==> Uploading the ISO file..."
curl --upload-file nitruxos.iso https://transfer.sh | tee release/URL
echo ''

wget https://github.com/probonopd/uploadtool/raw/master/upload.sh -O u.sh

echo " ==> Creating the release..."
curl --upload-file nitruxos.iso https://transfer.sh > release/URL

wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh -O u.sh
sh ./u.sh release/*
