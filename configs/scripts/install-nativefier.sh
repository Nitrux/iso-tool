#!/bin/sh

set -eu -o pipefail 

# -- Start npm.

npm init -y

# -- Install nativefier to home dir.

npm install nativefier -g

# -- Check if nativefier dir exists then delete script file.

[ -d ~/.npm/nativefier ] && rm ~/.config/install-nativefier.sh ~/.local/share/applications/install.nativefier.desktop

exit

