#!/bin/sh

set -eu -o pipefail 

# -- Install appimage-builder.

pip3 appimage-builder

# -- Check if appimage-builder exists then delete script file.

[ -f /usr/local/bin/appimage-builder ] && rm ~/.config/install-appimage-builder.sh ~/.local/share/applications/install.appaimge-builder.desktop

exit

