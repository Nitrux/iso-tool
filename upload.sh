#! /bin/sh

mega-login $MAIL $PASSWORD
mega-put --ignore-quota-warn out/*.iso 
mega-logout
