# Lenovo 14w Gen 2 Touchpad Fix for Linux

Enables the `ELAN0643` touchpad on the Lenovo 14w Gen 2 (`82N9`).

## Supported distributions

- Fedora and openSUSE (`dracut`)
- Debian, Ubuntu and Linux Mint (`initramfs-tools`)
- Arch Linux, Manjaro and EndeavourOS (`mkinitcpio`)

## Install

Open a terminal and run:

```bash
git clone https://github.com/matthieuleconte1/14w-gen2-trackpad-driver.git
cd 14w-gen2-trackpad-driver
sudo ./install.sh
sudo reboot
```

The installer automatically detects your distribution.

### Without Git

1. Click **Code**, then **Download ZIP**.
2. Extract the ZIP file.
3. Open a terminal inside the extracted folder.
4. Run:

```bash
sudo ./install.sh
sudo reboot
```

## Verify

After rebooting, open a terminal in the project folder and run:

```bash
./status.sh
```

The output should contain `ELAN0643` and `Touchpad`.

## Uninstall

Open a terminal in the project folder and run:

```bash
sudo ./uninstall.sh
sudo reboot
```

## Compatibility check

The installer only runs when both conditions are detected:

- Lenovo machine type `82N9`
- ACPI device `ELAN0643`

Do not force this fix onto another computer model.

## How it works

The Lenovo firmware does not provide valid I2C resources for the touchpad to
Linux. This project loads a small SSDT correction from the initramfs, allowing
the standard Linux `i2c_hid_acpi` and `hid-multitouch` drivers to detect it.

No custom kernel driver is installed.

## License

[MIT](LICENSE)
