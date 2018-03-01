#! /bin/sh

sha256sum nxos.iso > checksum
curl -i -F filedata=@checksum -F filedata=@nxos.iso https://transfer.sh | sed 's/http/\nhttp/g' | grep http > urls

wget -q https://github.com/probonopd/uploadtool/raw/master/upload.sh
sh -c ./upload.sh urls
