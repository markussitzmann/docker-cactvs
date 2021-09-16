#!/bin/bash
set -e

if ! id "app" >/dev/null 2>&1; then
    groupadd -g $CACTVS_GID app && \
    useradd --shell /bin/bash -u $CACTVS_UID -g $CACTVS_GID -o -c "" -M app
fi

PGM="/opt/cactvs/lib/cactvs3.4.8.18/lib/pycactvs"

gosu app "$PGM" -obd "$@"

