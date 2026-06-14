#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_file="$script_dir/lenovo-14w-gen2-trackpad.asl"
output_file="$script_dir/lenovo-14w-gen2-trackpad.aml"

if command -v iasl >/dev/null 2>&1; then
    iasl_bin=$(command -v iasl)
elif [[ -x /tmp/acpica-tools-extracted/usr/bin/iasl ]]; then
    iasl_bin=/tmp/acpica-tools-extracted/usr/bin/iasl
else
    echo "iasl is required (Fedora: acpica-tools, Debian/Ubuntu: acpica-tools, Arch: acpica)." >&2
    exit 1
fi

"$iasl_bin" -p "${output_file%.aml}" "$source_file"
echo "Built $output_file"
