#! /bin/bash

set -x

REMOVE_FILES='
/etc/alternatives/README
/etc/cron.daily/dpkg
/etc/dpkg
/etc/apt
/etc/logrotate.d/alternatives
/etc/logrotate.d/dpkg
/sbin/start-stop-daemon
/usr/bin/dpkg
/usr/bin/dpkg-deb
/usr/bin/dpkg-divert
/usr/bin/dpkg-maintscript-helper
/usr/bin/dpkg-query
/usr/bin/dpkg-split
/usr/bin/dpkg-statoverride
/usr/bin/dpkg-trigger
/usr/bin/update-alternatives
/usr/share/doc/dpkg/
/usr/share/dpkg/
/usr/share/lintian/overrides/dpkg
/usr/share/polkit-1/actions/org.dpkg.pkexec.update-alternatives.policy
'

rm -r ${REMOVE_FILES//\\n/ }



exit 0