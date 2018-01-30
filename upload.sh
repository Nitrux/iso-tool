#! /bin/sh

#mega-login $MAIL $PASSWORD
#mega-put --ignore-quota-warn nitruxos.iso 
#mega-logout

curl --upload-file nitruxos.iso https://transfer.sh/nitruxos.iso
