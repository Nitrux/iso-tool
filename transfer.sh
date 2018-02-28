#! /bin/sh

# Now I will use `zsync` in order to reduce bandwidth usage.

mkdir release

md5sum nxos.iso > release/md5.txt
zsyncmake -e -f nxos.iso -o nxos.zsync
curl -i -F filedata=@nxos.zsync -F filedata=@nxos.iso https://transfer.sh | sed 's/https/\nhttps/g' > release/urls

wget -qO - https://github.com/probonopd/uploadtool/raw/master/upload.sh
sh -c ./upload.sh release/*
