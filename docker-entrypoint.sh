#!/bin/bash
set -e

if id "app" >/dev/null 2>&1; then
    echo "User 'app' exists, skipping creation."
else
    echo "Creating user 'app' ..." && \
    groupadd -g $CACTVS_GID app && \
    useradd --shell /bin/bash -u $CACTVS_UID -g $CACTVS_GID -o -c "" -M app && \
    export HOME=/home/app && \
    echo "Done."
fi

exec "$@"
#gosu app "$@"