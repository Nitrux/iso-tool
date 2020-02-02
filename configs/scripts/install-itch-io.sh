#!/bin/sh

set -eu -o pipefail 

# -- Download setup file.

wget -q -O ~/.config/itch-setup https://raw.githubusercontent.com/UriHerrera/storage/master/Files/itch-setup

# -- Run setup.
chmod +x ~/.config/itch-setup
~/.config/./itch-setup

# -- Check if itch dir exists then delete setup file.

[ -d ~/.itch ] && rm ~/.config/itch-setup ~/.local/share/applications/install.itch.io.desktop

exit
