#!/usr/bin/env bash
set -euo pipefail

readonly project_name="lenovo-14w-trackpad-fix"
readonly install_root="/usr/local/lib/$project_name"
readonly dracut_conf="/etc/dracut.conf.d/99-$project_name.conf"
readonly initramfs_hook="/etc/initramfs-tools/hooks/$project_name"
readonly mkinitcpio_hook="/etc/initcpio/install/lenovo_14w_trackpad"
readonly mkinitcpio_conf="/etc/mkinitcpio.conf.d/99-$project_name.conf"

rebuild=yes
if [[ ${1:-} == --no-rebuild ]]; then
    rebuild=no
elif (($#)); then
    echo "Usage: sudo ./uninstall.sh [--no-rebuild]" >&2
    exit 2
fi

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root (for example: sudo ./uninstall.sh)." >&2
    exit 1
fi

backend=""
if [[ -f $install_root/backend ]]; then
    backend=$(< "$install_root/backend")
elif [[ -f $dracut_conf ]]; then
    backend=dracut
elif [[ -f $initramfs_hook ]]; then
    backend=initramfs-tools
elif [[ -f $mkinitcpio_hook || -f $mkinitcpio_conf ]]; then
    backend=mkinitcpio
fi

rm -f "$dracut_conf" "$initramfs_hook" "$mkinitcpio_hook" "$mkinitcpio_conf"
rm -rf "$install_root"

if [[ $rebuild == yes ]]; then
    case $backend in
        dracut)
            dracut --regenerate-all --force
            ;;
        initramfs-tools)
            update-initramfs -u -k all
            ;;
        mkinitcpio)
            mkinitcpio -P
            ;;
        "")
            echo "No installed backend was recorded; no initramfs was rebuilt." >&2
            ;;
        *)
            echo "Unknown recorded backend '$backend'; no initramfs was rebuilt." >&2
            ;;
    esac
fi

echo "Removed $project_name."
