#! /bin/sh

set -xe

# -- Adding liquidshell to autostart works fine for autostarting it, however, it doesn't seem to pick up the theme right away. The only workaround is to
# -- apparently start it, then kill the process and start it again.

sleep 1 && liquidshell -stylesheet /usr/share/liquidshell/style/stylesheet-dark.qss
killall liquidshell
sleep 5 && liquidshell -stylesheet /usr/share/liquidshell/style/stylesheet-dark.qss

exit
