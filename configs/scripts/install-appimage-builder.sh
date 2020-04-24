#!/bin/sh

set -eu -o pipefail 

# -- Install appimage-builder to $HOME.

pip3 install --user appimage-builder

# -- Check if appimage-builder exists then delete script file.

[ -d ~/.local/bin/appimage-builder ] && rm ~/.config/install-appimage-builder.sh ~/.local/share/applications/install.appaimge-builder.desktop

exit

