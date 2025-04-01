#!/usr/bin/env bash

set -euo pipefail

if [[ $BASH_SOURCE = */* ]]; then
	THIS=${BASH_SOURCE%/*}/
else
	THIS=./
fi

cfg="${1:-${THIS}/metrics.cfg}"
metrics=$(cut -f1 -d\# ${cfg} | xargs | tr ' ' ',')

echo "--csv --metrics=${metrics}"
