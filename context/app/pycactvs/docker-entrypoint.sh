#!/bin/bash
set -e

source .env

if ! id "app" >/dev/null 2>&1; then
    groupadd -g $CACTVS_GID app && \
    useradd --shell /bin/bash -u $CACTVS_UID -g $CACTVS_GID -o -c "" -M app
fi

PGM="/opt/cactvs/lib/${CACTVS_VERSION}/pycactvs"

gosu app "$PGM" -obd "$@"

