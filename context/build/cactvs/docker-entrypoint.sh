#!/bin/bash
set -e

if id "app" >/dev/null 2>&1; then
    echo "User 'app' exists, skipping creation."
else
    echo "Creating user 'app' ..." && \
    groupadd -g $CACTVS_GID app && \
    useradd --shell /bin/bash -u $CACTVS_UID -g $CACTVS_GID -o -c "" -M app && \
    mkdir -p /home/app && \
    chown -R $CACTVS_UID:$CACTVS_GID /home/app && \
    export HOME=/home/app && \
    echo "Done."
fi

export PYTHONPATH=/home/app:$PYTHONPATH

#gosu app "$@"
exec "$@"

#PGM="/opt/cactvs/cactvs3.4.8.18/lib/pycactvs"
#gosu app "$PGM" -obd "$@"