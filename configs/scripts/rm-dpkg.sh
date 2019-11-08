#! /bin/bash

set -x

REMOVE_FILES='
/etc/alternatives/README
/etc/cron.daily/dpkg
/etc/dpkg/dpkg.cfg
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
/usr/share/doc/dpkg/changelog.Debian.gz
/usr/share/doc/dpkg/copyright
/usr/share/dpkg/abitable
/usr/share/dpkg/cputable
/usr/share/dpkg/ostable
/usr/share/dpkg/tupletable
/usr/share/lintian/overrides/dpkg
/usr/share/polkit-1/actions/org.dpkg.pkexec.update-alternatives.policy
'

rm -r ${REMOVE_FILES//\\n/ }

exit 0


