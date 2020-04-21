#! /bin/sh

adduser -G wheel,user,adm,cdrom,sudo,dip,plugdev,lpadmin,sambashare -m user
printf '%s\n%s\n' 'nitrux' 'nitrux' | passwd user
