#! /bin/sh

set -xe

# -- Start welcome wizard and then start latte-dock.
# -- Restart latte-dock on login so that icons for AppImages are loaded. Not necessary once deployed but necessary for first time boot.

nx-welcome-wizard &&
killall latte-dock
sleep 1 && latte-dock --replace
killall latte-dock
sleep 5 && latte-dock --replace

exit
