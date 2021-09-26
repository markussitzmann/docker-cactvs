#!/bin/bash
set -e

if ! id "app" >/dev/null 2>&1; then
    echo "creacting user app G $APP_GID U $APP_UID"
    groupadd -g $APP_GID app && \
    useradd --shell /bin/bash -u $APP_UID -g $APP_GID -o -c "" -M app
else
    echo "user app exists"
fi

mkdir -p /home/app/backup
chown -R app.app /home/app/backup

exec "$@"

