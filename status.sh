#!/usr/bin/env bash
set -euo pipefail

readonly install_root="/usr/local/lib/lenovo-14w-trackpad-fix"

if [[ -f $install_root/backend ]]; then
    echo "Installed backend: $(< "$install_root/backend")"
else
    echo "Installed backend: none"
fi

echo
echo "ACPI/kernel messages:"
if command -v journalctl >/dev/null 2>&1; then
    journalctl -k -b --no-pager 2>/dev/null \
        | grep -Ei '14WTPAD|ELAN0643|i2c[_ -]?hid' \
        || echo "No matching kernel messages found."
else
    dmesg 2>/dev/null \
        | grep -Ei '14WTPAD|ELAN0643|i2c[_ -]?hid' \
        || echo "No matching kernel messages found."
fi

echo
echo "Input device:"
if grep -A5 -B1 -i 'ELAN.*Touchpad' /proc/bus/input/devices; then
    :
elif grep -A5 -B1 -i 'Touchpad' /proc/bus/input/devices; then
    :
else
    echo "No touchpad input device found."
    exit 1
fi
