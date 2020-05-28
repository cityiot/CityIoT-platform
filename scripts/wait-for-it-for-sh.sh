#!/usr/bin/env sh
# wait-for-it script fot sh shell

apk add --no-cache --quiet bash
/wait-for-it.sh "$@"
