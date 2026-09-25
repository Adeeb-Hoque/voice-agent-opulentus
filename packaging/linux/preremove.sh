#!/bin/sh
# deb prerm / rpm %preun - stop the services before the files go. Data in
# /var/lib/opulentus and the key in /etc/opulentus survive removal on purpose:
# conversations and the key that unlocks stored credentials are the operator's,
# not the package's.
set -eu
if [ -d /run/systemd/system ]; then
    systemctl disable --now opulentus-api.service opulentus-web.service || true
fi
