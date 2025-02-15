#!/bin/sh

set -eu

REPO_ROOT=$(git rev-parse --show-toplevel)

watermark() {
    file=$1
    path="${REPO_ROOT}/${file}"
    tmp="${REPO_ROOT}/${file}.tmp"
    cp "$path" "$tmp"
    sed -e "s/v1.0.0/$(git describe --always --dirty)/g" "$tmp" > "$path"
    rm -f "$tmp"
}

watermark src/version.ml
