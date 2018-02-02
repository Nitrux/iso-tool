#! /bin/sh

curl --upload-file nitruxos.iso https://transfer.sh > release/URL
wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh -O u.sh
sh ./u.sh release/*
