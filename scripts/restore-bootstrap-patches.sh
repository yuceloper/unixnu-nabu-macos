#!/usr/bin/env bash
set -euo pipefail

# Merge UniXNU's core XNU patches into the staged Nabu patch module. The tree
# assembler links patches/xnu to the device repository, so without this merge
# the device patch directory hides the core patch directory completely.
# This script only changes host-side source/build files; it never accesses the
# tablet, its partitions, or its ESP.
WORK_ROOT="${1:-$HOME/unixnu-nabu-work}"
UPSTREAM="$WORK_ROOT/UniXNU-build"
TREE="$UPSTREAM/out/nabu/tree"
PATCH_DIR="$TREE/patches/xnu"
XNU_WORK="$TREE/.cache/xnu-work"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OVERRIDE_DIR="$REPO_ROOT/patches/xnu"
EXPECTED="245aca1a9ec5b730b1cad80fade295800d2981f1"

if [[ "$(git -C "$UPSTREAM" rev-parse HEAD)" != "$EXPECTED" ]]; then
  echo "ERROR: UniXNU checkout is not the pinned $EXPECTED" >&2
  exit 1
fi
if [[ ! -d "$PATCH_DIR" ]]; then
  echo "ERROR: staged Nabu patch directory not found: $PATCH_DIR" >&2
  exit 1
fi

copied=0
for src in "$UPSTREAM"/patches/xnu/*.patch; do
  name=${src##*/}
  dst="$PATCH_DIR/$name"
  override="$OVERRIDE_DIR/$name"
  wanted="$src"
  [[ -f "$override" ]] && wanted="$override"

  if [[ -e "$dst" ]] && cmp -s "$wanted" "$dst"; then
    continue
  fi
  if [[ -e "$dst" && ! -f "$override" ]]; then
    echo "ERROR: staged patch conflicts with pinned core patch: $dst" >&2
    exit 1
  fi
  cp "$wanted" "$dst"
  echo "Staged core patch: $name"
  copied=$((copied + 1))
done

# A failed compile can leave startup.o.json without link.filelist. kernel.py
# otherwise treats that partial record as a completed bootstrap and skips
# straight to the archive builders, which then fail with a misleading error.
record="$TREE/build/xnu/ios-obj/DEVELOPMENT_ARM64_BCM2837/osfmk/DEVELOPMENT/startup.o.json"
filelist="$TREE/build/xnu/ios-obj/DEVELOPMENT_ARM64_BCM2837/link.filelist"
if [[ -f "$record" && ! -f "$filelist" ]]; then
  stale="$record.stale-before-bootstrap-retry"
  [[ ! -e "$stale" ]] || stale="$stale.$$"
  mv "$record" "$stale"
  echo "Moved incomplete bootstrap record aside: $stale"
fi

if [[ -d "$XNU_WORK/.git" ]]; then
  echo "XNU work tree exists; the build script will apply/check the merged series."
fi
echo "Ready: merged $copied patch file(s). Run ./unixnu build kernel."
