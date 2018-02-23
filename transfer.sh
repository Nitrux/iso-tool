#! /bin/sh

# Now I will use `zsync` in order to reduce bandwidth usage.

mkdir release

md5sum nxos.iso > release/md5.txt
curl -T nitruxos.iso https://transfer.sh > release/URL

wget -qO - https://github.com/probonopd/uploadtool/raw/master/upload.sh
sh -c ./upload.sh release/*
