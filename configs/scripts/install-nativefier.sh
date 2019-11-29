#!/bin/sh

set -eu -o pipefail 

# -- Install nativefier to home dir.

npm install nativefier -g

# -- Check if nativefier dir exists then delete script file.

[ -d ~/.npm-packages/lib/node_modules/nativefier ] && rm ~/.config/install-nativefier.sh ~/.local/share/applications/install.nativefier.desktop

exit

