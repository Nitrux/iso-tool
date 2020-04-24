#!/bin/sh

set -eu -o pipefail 

# -- Install appimage-builder to $HOME.

pip3 install --user appimage-builder

# -- Check if appimage-builder exists then delete script file.

[ -f ~/.local/bin/appimage-builder ] && rm ~/.config/install-appimage-builder.sh ~/.local/share/applications/install.appaimge-builder.desktop

# -- Refresh shell cache.

hash appimage-builder

exit

