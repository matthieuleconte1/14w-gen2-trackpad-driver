# Correctif trackpad Lenovo 14w Gen 2 sous Linux

Ce paquet corrige le trackpad `ELAN0643` du Lenovo 14w Gen 2, type machine
`82N9`. Le firmware annonce le périphérique, mais sa méthode ACPI dynamique
`_CRS` ne fournit pas les ressources I2C sous Linux. Le pilote standard
`i2c_hid_acpi` ne peut donc pas s'y attacher.

Il ne s'agit pas d'un pilote propriétaire. Le fichier SSDT fournit au noyau
les ressources correctes déjà présentes dans la DSDT Lenovo :

- contrôleur : `\\_SB.I2CD`
- adresse I2C : `0x15`
- vitesse : 400 kHz
- interruption : `\\_SB.GPIO`, broche `0x09`, active bas
- registre du descripteur HID : `0x01`

## Distributions prises en charge

- Fedora, openSUSE et autres systèmes utilisant `dracut`
- Debian, Ubuntu, Mint et dérivées utilisant `initramfs-tools`
- Arch Linux, EndeavourOS, Manjaro et dérivées utilisant `mkinitcpio`

L'installateur détecte automatiquement le générateur d'initramfs. Il installe
un hook permanent : le correctif est donc réintégré lors des futures mises à
jour du noyau. Les UKI générées par les outils natifs sont également
reconstruites par ces outils.

## Installation

Copier l'archive sur l'autre distribution, puis lancer :

```bash
tar -xzf lenovo-14w-trackpad-fix-1.0.0.tar.gz
cd lenovo-14w-trackpad-fix-1.0.0
sudo ./install.sh
sudo reboot
```

L'intégrité de l'archive peut être vérifiée avec :

```bash
sha256sum -c lenovo-14w-trackpad-fix-1.0.0.tar.gz.sha256
```

Après redémarrage :

```bash
./status.sh
```

Une détection manuelle reste possible :

```bash
sudo ./install.sh --backend dracut
sudo ./install.sh --backend initramfs-tools
sudo ./install.sh --backend mkinitcpio
```

## Désinstallation

```bash
sudo ./uninstall.sh
sudo reboot
```

## Recompiler le SSDT

Le fichier AML précompilé est inclus, donc `iasl` n'est pas requis pour
l'installation. Pour le reconstruire depuis la source :

```bash
./build.sh
```

Paquets contenant `iasl` : `acpica-tools` sur Fedora/Debian/Ubuntu et `acpica`
sur Arch Linux.

## Créer une archive à distribuer

```bash
./make-release.sh
```

Cette commande crée l'archive `.tar.gz` et son fichier de contrôle `.sha256`
dans le dossier parent.

## Sécurité

L'installation refuse de s'exécuter si le DMI n'indique pas `LENOVO 82N9` ou
si le périphérique ACPI `ELAN0643` est absent. Le noyau doit avoir
`CONFIG_ACPI_TABLE_UPGRADE=y`, ce qui est le cas des noyaux génériques usuels.

Le chargement des tables ACPI depuis l'initramfs est documenté par le noyau
Linux :

https://docs.kernel.org/admin-guide/acpi/initrd_table_override.html
