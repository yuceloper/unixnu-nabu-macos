# UniXNU Nabu macOS Port

Experimental research project to bring **macOS on ARM64** to the **Xiaomi Pad 5 (nabu)** using [UniXNU](https://github.com/UniXNU/UniXNU).

> **Status: research / bootstrap build. macOS has not been booted on this device in this project.**

## Hardware and existing setup

- Device: Xiaomi Pad 5 (`nabu`)
- SoC: Qualcomm Snapdragon 860 / SM8150
- GPU: Adreno 640
- RAM: 6 GB
- Existing systems: Android + Windows 11 dual boot
- Existing ESP: `/dev/block/sda33` (observed via Android's `/dev/block/by-name/esp`)
- Existing Windows partition: `/dev/block/sda32`

**Never apply third-party ESP partition paths or raw UFS LBA ranges without validating them against this device's actual partition map.** A source port's documentation references `sda31` for ESP, whereas on this device `sda31` is `userdata`.

## Upstream references

- [UniXNU core](https://github.com/UniXNU/UniXNU)
- [UniXNU-nabu device port](https://github.com/zzweiqing/UniXNU-nabu)
- [UniXNU-sheng macOS reference](https://github.com/UniXNU/UniXNU-sheng)

The current Nabu reference port targets **iPadOS 17.7 (21H16)**, not macOS. An iPadOS bootstrap build is a prerequisite experiment, not evidence of macOS support.

## Bootstrap build

The Nabu source preparation workflow requires UniXNU core revision:

```text
245aca1a9ec5b730b1cad80fade295800d2981f1
```

Its `nabu_bootstrap_defconfig` profile deliberately omits GPU/display, physical storage, and full userland. The Nabu build script stages a modified device tree; UniXNU must be told where that staged device directory is.

A local build may be resumed **after** `prepare_source.py` succeeded:

```sh
cd ~/unixnu-nabu-work
export UNIXNU_IPSW="$PWD/inputs/ipsw-21h16-small.zip"
export UNIXNU_DEVICE="$PWD/nabu-bootstrap-build/device"
./unixnu-nabu-macos/scripts/restore-bootstrap-patches.sh "$PWD"
cd UniXNU-build
./unixnu defconfig nabu_bootstrap_defconfig
./unixnu build kernel
```

The restore step is required because UniXNU's tree assembler links the Nabu
device's `patches/xnu` directory over the core directory. It merges the full
pinned core patch set, installs the qualified component-probe override without
duplicating Nabu's console patches, and moves aside an incomplete bootstrap
record when `link.filelist` was never produced.

Latest verified host build (2026-11-12):

```text
out/nabu/kernel/kernel.macho
sha256 eb33b2c23104488636e0049a82e7f1a7a6328a7d382d8d92e25894f7df8a4357
```

Do not run `nabu-build.sh` repeatedly against a modified upstream tree. Recreate a clean pinned worktree before a fresh full pipeline.

## Safety and reproducibility

- Keep Android, Windows, and the ESP unchanged during host-side bootstrap work.
- Never commit IPSW images, firmware blobs, private keys, device identity values, partition images, or generated payloads.
- Verify full GPT ranges and back up the complete ESP before attempting any future bootloader installation.
- Document source pins, local build outputs, failure logs, and required fixes without publishing device-specific secrets.

## Milestones

1. Host-side bootstrap `kernel.macho` build — in progress.
2. Isolated UEFI and XNU bring-up feasibility, with rollback and partition map verified.
3. Evaluate macOS ARM64/ARM64E boot ABI requirements and port compatibility.
4. Prototype macOS kernel/userspace boot chain.
5. Hardware drivers and graphics acceleration.

There is currently **no verified installable macOS image** for this repository.
