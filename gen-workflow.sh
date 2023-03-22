#!/bin/bash

set -eu

while read -r f; do
    dest=$(basename $f .jsonnet).yaml
    echo "jsonnet $f > ${dest}"
    jsonnet $f > ./.github/workflows/${dest}

done < <(find './.github/workflows' -name '*.jsonnet' -mindepth 1 -maxdepth 1)
