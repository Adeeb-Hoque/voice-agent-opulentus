#!/bin/sh
# deb postinst / rpm %post - create the service user, generate the key if none,
# then enable and start both services.
set -eu

if ! getent passwd opulentus >/dev/null; then
    useradd --system --home-dir /var/lib/opulentus --shell /usr/sbin/nologin opulentus
fi

mkdir -p /var/lib/opulentus
chown opulentus:opulentus /var/lib/opulentus
chmod 750 /var/lib/opulentus

# Installation secrets are root-owned; the service reads them through systemd's
# EnvironmentFile, which runs as root before dropping to the service user.
chown root:root /etc/opulentus/opulentus.env
chmod 600 /etc/opulentus/opulentus.env

# Generate ENCRYPTION_KEY on first install only - an empty value in the template
# marks "never configured", and an upgrade must never touch an existing key.
if grep -q '^ENCRYPTION_KEY=$' /etc/opulentus/opulentus.env; then
    KEY="$(/opt/opulentus/python/bin/python3 -c 'from api.security.crypto import generate_key; print(generate_key())')"
    sed -i "s/^ENCRYPTION_KEY=$/ENCRYPTION_KEY=${KEY}/" /etc/opulentus/opulentus.env
    echo "***********************************************************************"
    echo "Opulentus generated an ENCRYPTION_KEY in /etc/opulentus/opulentus.env."
    echo "BACK IT UP somewhere that is NOT the database backup - losing it makes"
    echo "every credential stored in the dashboard unrecoverable."
    echo "***********************************************************************"
fi

if [ -d /run/systemd/system ]; then
    systemctl daemon-reload
    systemctl enable --now opulentus-api.service opulentus-web.service
    echo "Opulentus is starting: dashboard on http://localhost:38471 (loopback only)."
else
    echo "systemd is not running; start the services yourself when it is:"
    echo "  systemctl enable --now opulentus-api opulentus-web"
fi
