#! /bin/sh

mkdir out

sha256sum nxos.iso > checksum
curl -i -F filedata=@checksum -F filedata=@nxos.iso https://transfer.sh | sed 's/https/\nhttps/g' | grep https > out/urls

wget -qO - https://github.com/probonopd/uploadtool/raw/master/upload.sh
sh -c ./upload.sh out/*
