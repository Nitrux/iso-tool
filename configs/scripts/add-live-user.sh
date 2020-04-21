#! /bin/sh

adduser -G wheel -m user
printf '%s\n%s\n' 'nitrux' 'nitrux' | passwd user
