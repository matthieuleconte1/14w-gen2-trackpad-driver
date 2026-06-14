#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_name=lenovo-14w-trackpad-fix
version=$(< "$script_dir/VERSION")
output_dir=${1:-"$(dirname -- "$script_dir")"}
archive="$output_dir/${project_name}-${version}.tar.gz"

mkdir -p "$output_dir"
tar \
    --sort=name \
    --mtime='UTC 2026-01-01' \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --exclude='*.tar.gz' \
    --exclude='*.tar.gz.sha256' \
    --transform="s#^${project_name}#${project_name}-${version}#" \
    -czf "$archive" \
    -C "$(dirname -- "$script_dir")" \
    "$project_name"

(
    cd "$output_dir"
    sha256sum "$(basename -- "$archive")" > "$(basename -- "$archive").sha256"
)
echo "Created $archive"
echo "Created $archive.sha256"
