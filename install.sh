#!/usr/bin/env bash
set -euo pipefail

readonly project_name="lenovo-14w-trackpad-fix"
readonly install_root="/usr/local/lib/$project_name"
readonly dracut_conf="/etc/dracut.conf.d/99-$project_name.conf"
readonly initramfs_hook="/etc/initramfs-tools/hooks/$project_name"
readonly mkinitcpio_hook="/etc/initcpio/install/lenovo_14w_trackpad"
readonly mkinitcpio_conf="/etc/mkinitcpio.conf.d/99-$project_name.conf"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backend=""
rebuild=yes

usage() {
    cat <<EOF
Usage: sudo ./install.sh [--backend BACKEND] [--no-rebuild]

BACKEND may be: dracut, initramfs-tools, or mkinitcpio.
The backend is normally detected automatically.
EOF
}

while (($#)); do
    case $1 in
        --backend)
            [[ $# -ge 2 ]] || { echo "Missing value for --backend." >&2; exit 2; }
            backend=$2
            shift 2
            ;;
        --no-rebuild)
            rebuild=no
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root (for example: sudo ./install.sh)." >&2
    exit 1
fi

vendor=$(< /sys/class/dmi/id/sys_vendor)
product=$(< /sys/class/dmi/id/product_name)
if [[ $vendor != LENOVO || $product != 82N9 ]]; then
    echo "Refusing installation: expected LENOVO product 82N9, found '$vendor' '$product'." >&2
    exit 1
fi

if [[ ! -e /sys/bus/acpi/devices/ELAN0643:00 ]]; then
    echo "Refusing installation: ACPI device ELAN0643 was not found." >&2
    exit 1
fi

kernel_config="/boot/config-$(uname -r)"
if [[ -r $kernel_config ]] && ! grep -Eq '^CONFIG_ACPI_(TABLE_UPGRADE|INITRD_TABLE_OVERRIDE)=y$' "$kernel_config"; then
    echo "The running kernel does not support ACPI table upgrades." >&2
    exit 1
elif [[ ! -r $kernel_config ]]; then
    echo "Warning: unable to verify ACPI table upgrade support in $kernel_config." >&2
fi

detect_backend() {
    if command -v update-initramfs >/dev/null 2>&1 && [[ -d /etc/initramfs-tools ]]; then
        echo initramfs-tools
    elif command -v mkinitcpio >/dev/null 2>&1 && [[ -f /etc/mkinitcpio.conf ]]; then
        echo mkinitcpio
    elif command -v dracut >/dev/null 2>&1; then
        echo dracut
    else
        return 1
    fi
}

if [[ -z $backend ]]; then
    if ! backend=$(detect_backend); then
        echo "No supported initramfs generator found." >&2
        echo "Supported generators: dracut, initramfs-tools, mkinitcpio." >&2
        exit 1
    fi
fi

case $backend in
    dracut)
        command -v dracut >/dev/null 2>&1 || { echo "dracut is not installed." >&2; exit 1; }
        grep -q 'acpi_override' "$(command -v dracut)" \
            || { echo "This dracut version does not support acpi_override." >&2; exit 1; }
        ;;
    initramfs-tools)
        command -v update-initramfs >/dev/null 2>&1 || { echo "update-initramfs is not installed." >&2; exit 1; }
        command -v cpio >/dev/null 2>&1 || { echo "cpio is not installed." >&2; exit 1; }
        grep -q 'prepend_earlyinitramfs' /usr/share/initramfs-tools/hook-functions \
            || { echo "This initramfs-tools version lacks prepend_earlyinitramfs." >&2; exit 1; }
        ;;
    mkinitcpio)
        command -v mkinitcpio >/dev/null 2>&1 || { echo "mkinitcpio is not installed." >&2; exit 1; }
        grep -q 'add_file_early' /usr/lib/initcpio/functions \
            || { echo "This mkinitcpio version lacks add_file_early." >&2; exit 1; }
        ;;
    *)
        echo "Unsupported backend: $backend" >&2
        exit 1
        ;;
esac

for file in \
    "$script_dir/lenovo-14w-gen2-trackpad.aml" \
    "$script_dir/integrations/dracut/99-$project_name.conf" \
    "$script_dir/integrations/initramfs-tools/$project_name" \
    "$script_dir/integrations/mkinitcpio/lenovo_14w_trackpad" \
    "$script_dir/integrations/mkinitcpio/99-$project_name.conf"; do
    [[ -f $file ]] || { echo "Package file not found: $file" >&2; exit 1; }
done

# Remove only integration files owned by this package. This makes backend
# changes and repeated installations deterministic.
rm -f "$dracut_conf" "$initramfs_hook" "$mkinitcpio_hook" "$mkinitcpio_conf"

install -d -m 0755 "$install_root/acpi"
install -m 0644 \
    "$script_dir/lenovo-14w-gen2-trackpad.aml" \
    "$install_root/acpi/lenovo-14w-gen2-trackpad.aml"
printf '%s\n' "$backend" > "$install_root/backend"
chmod 0644 "$install_root/backend"

case $backend in
    dracut)
        install -D -m 0644 \
            "$script_dir/integrations/dracut/99-$project_name.conf" \
            "$dracut_conf"
        ;;
    initramfs-tools)
        install -D -m 0755 \
            "$script_dir/integrations/initramfs-tools/$project_name" \
            "$initramfs_hook"
        ;;
    mkinitcpio)
        install -D -m 0644 \
            "$script_dir/integrations/mkinitcpio/lenovo_14w_trackpad" \
            "$mkinitcpio_hook"
        install -D -m 0644 \
            "$script_dir/integrations/mkinitcpio/99-$project_name.conf" \
            "$mkinitcpio_conf"
        ;;
esac

if command -v restorecon >/dev/null 2>&1; then
    restorecon -R "$install_root" "$dracut_conf" "$initramfs_hook" \
        "$mkinitcpio_hook" "$mkinitcpio_conf" 2>/dev/null || true
fi

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
    esac
fi

echo "Installed $project_name using $backend."
if [[ $rebuild == yes ]]; then
    echo "Reboot, then run: ./status.sh"
else
    echo "Initramfs rebuild skipped; the fix is not active until images are rebuilt."
fi
