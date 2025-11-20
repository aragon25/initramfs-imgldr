# initramfs-imgldr

Provide an image loader that lets a Raspberry Pi boot and run a disk/image as the active system. The project installs lightweight initramfs helpers and boot-config changes so a prepared image file can be started by the device as its root system.

---
## 📌 Key features

- Boot an image as the active system by installing initramfs helpers and updating boot configuration.
- Install/remove initramfs helper scripts into `/etc/initramfs-tools` (`--install`, `--remove`).
- Rebuild initramfs and update `config.txt` boot entries to point to image-based initramfs (`--update_initramfs`).
- Toggle cmdline boot flags used by the loader (fastboot, savedboot, setupmode, boot image/local).

---

## 🧰 Dependencies

Required on the host system (Debian/Raspbian):

- `bash`
- `initramfs-tools`, `cpio`
- `sed`, `grep`, `cut`, `tee`, `cat`, `file`, `find`, `readlink`

Make sure `initramfs-tools` and `cpio` are installed before performing installs or updating initramfs.

---

## 📂 Installation

### Install via `.deb` package (recommended for deployment)

If a release `.deb` is available, install it on a test device first:

```bash
wget https://github.com/aragon25/initramfs-imgldr/releases/download/v2.7-1/initramfs-imgldr_2.7-1_all.deb
sudo apt install ./initramfs-imgldr_2.7-1_all.deb
```

The package will install the loader script and may place helper files and a configurator service into the appropriate system locations.

---

## ⚙️ Usage

The loader script must be run as `root`. It will validate the device (Raspberry Pi model and Raspbian release), check required packages and locate the boot partition before making changes.

```bash
sudo initramfs-imgldr --help
```

Common commands and their purpose:

- `--install` — install initramfs helper scripts so the device can boot an image as its system.
- `--remove` — remove previously installed helper scripts.
- `--update_initramfs` — rebuild initramfs and update boot configuration to use image-based initramfs entries.
- `--cmdline_*` — toggle boot cmdline flags used by the loader.

Notes:
- Use `--install` to deploy scripts into `/etc/initramfs-tools/scripts/init-top/`, `/etc/initramfs-tools/hooks/` and `/etc/initramfs-tools/scripts/image`.
- Installing will add `overlay` to `/etc/initramfs-tools/modules` if required.

---

## 🔧 Developer workflows

- Pack payload into the script (developer):

```bash
sudo initramfs-imgldr --payload_pack
```

- Preview embedded payload without installing:

```bash
sudo initramfs-imgldr --payload_unpack
ls -la initramfs-imgldr_payload
```

Packaging note: inspect `deploy/config/build_deb.conf` and any `preinst`/`postinst` hooks before building or installing `.deb` artifacts.

---

## ⚠️ Safety & recommendations

- This tool modifies the boot partition and rebuilds initramfs images — test on non-critical hardware first.
- Run as `root` only after reviewing intended actions.
- Before installing a `.deb`, check `preinst`/`postinst` scripts for privileged operations.

---

## Examples

Install loader and update initramfs so the device can boot an image:

```bash
sudo initramfs-imgldr --install
sudo initramfs-imgldr --update_initramfs
```

Pack/unpack payload (developer):

```bash
sudo initramfs-imgldr --payload_pack
sudo initramfs-imgldr --payload_unpack
```
