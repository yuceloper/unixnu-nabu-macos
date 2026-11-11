# macOS port feasibility and first milestone — Xiaomi Pad 5 (nabu)

Updated: 2026-11-12

## Objective (not iPadOS)

Boot **real macOS** on the Snapdragon 860 / SM8150 Xiaomi Pad 5, without destroying the existing Android + Windows dual boot. The existing iPadOS 17.7 kernel build is a **hardware/compile reference only**, not a macOS kernel.

## Verified upstream references

- [UniXNU macOS profile: macos-27.3-26C5035r](https://github.com/UniXNU/UniXNU/blob/main/profiles/os/macos-27.3-26C5035r/profile.toml)
  - `[os].arch = "arm64e"`, `[os].target = "macosx"`; product `Mac17,11`.
  - Profile records macOS 27.3 build 26C5035r and an XNU 12377.121.6 source baseline with port patches. Its metadata explicitly says this is **not** the Apple kernel version of the OS release.
  - Requires its own macOS kernelcache, trust caches, DeviceTree, macOS/APFS root, SystemOS/App cryptex inputs, matching original kext closure, signature/owner policies, boot device identity and Data seed.
- [Community macOS-on-sheng status](https://unixnu.com/devices/sheng-macos)
  - SM8550 port reports macOS 26.5 original arm64e launchd on QEMU and hardware; WindowServer still fails during HID/display initialization. This is **not** evidence Nabu can boot macOS.
- [UniXNU porting architecture](https://unixnu.com/porting/)
  - Separate firmware/UEFI, DarwinBoot, kernel, prelink, and original userland layers.
- [Nabu iPadOS reference](https://github.com/zzweiqing/UniXNU-nabu) — Snapdragon 860 / Adreno 640, iPadOS 17.7/21H16.

## Local host baseline (reported, not a clean end-to-end run)

- `kernel.macho`: 50,589,696 bytes, ARM64 Mach-O.
- SHA-256: `eb33b2c23104488636e0049a82e7f1a7a6328a7d382d8d92e25894f7df8a4357`.
- Built on 2026-11-12 using **iPadOS** bootstrap inputs.
- No unresolved external symbols reported; prelink output exists.
- The first bootstrap pass failed on three Nabu component symbols. The subsequent main kernel link succeeded; a later rerun was rejected due to stale platform archive. A clean full build returning exit 0 is **not yet confirmed**.

## Key compatibility gates for a *macOS* Nabu port

1. **ARM64E/PAC/ABI:** verify processor capabilities, XNU arm64e runtime requirements, and whether the existing ArmCpu and platform port can support the profile. Do not assume a built ARM64 kernel can run arm64e macOS launchd.
2. **macOS-specific kernel and prelink:** select the actual `macosx` profile, its source pins/patches and macOS kext ABI. The iPadOS 17.7 profile does not suffice.
3. **Boot identity / early userspace:** DeviceTree/ADT, boot-args, original macOS trust caches, owner/root policies, APFS volume UUIDs, cryptex mounts, Data seed and launchd.
4. **Device bring-up:** adapt Nabu GICv3, SMP, timer, SMMU, memory map, UFS and watchdog/PMGR components to the macOS baseline; check for version-specific ABI changes.
5. **Display input and GPU:** the Adreno 640 work was for iPadOS. Verify Metal plugin compatibility with macOS IOGPUFamily and WindowServer; no macOS hardware acceleration established here.
6. **Persistent boot diagnostics:** verify log capture and rollback before any hardware run.

## Next actionable deliverable: host-only macOS configuration probe

- Preserve the current iPadOS `kernel.macho` and its SHA-256.
- Create a **separate** `macos-nabu` working directory and independently pinned source tree; never overwrite existing iPadOS staging or archives.
- Parse the upstream macOS `profile.toml`, enumerate its kernel patches, kext roots and OS input requirements.
- Draft a Nabu `board.toml` variant **in an isolated experimental branch** with macOS profile selection and no raw-storage or flashing stage.
- Run host-only profile/configuration validation; report unsupported catalog fields, missing dependencies, and arm64e build failures without suppressing checks.
- Only after successful host checks plan EFI package generation and partition-safe testing; treat this as a separate approval gate.

## Device safety gate

**No flash, `dd`, GPT edit, ESP mutation, or direct UFS window write is authorized.** The user's device has Android/Windows dual boot; observed `esp` points at `/dev/block/sda33`, `win` at `/dev/block/sda32`, `userdata` at `/dev/block/sda31`. Third-party scripts which assume ESP is `sda31` are unsafe on this device. Validate device-specific partition start/end and backups before any future writes.

## Definition of done for milestone 1

A pinned macOS-targeted, Nabu-configured **host-side** profile/configuration dry run with a complete discrepancy report and **no device writes**. A kernel merely compiling, or an iPadOS XNU image, does not meet the macOS boot milestone.
