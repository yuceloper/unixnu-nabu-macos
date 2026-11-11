#!/usr/bin/env bash
set -euo pipefail

# Restore selected UniXNU core XNU build-compatibility patches to an already
# staged Nabu bootstrap source tree. This touches no tablet partitions.
WORK_ROOT="${1:-$HOME/unixnu-nabu-work}"
UPSTREAM="$WORK_ROOT/UniXNU-build"
TREE="$UPSTREAM/out/nabu/tree"
PATCH_DIR="$TREE/patches/xnu"
XNU_WORK="$TREE/.cache/xnu-work"
EXPECTED="245aca1a9ec5b730b1cad80fade295800d2981f1"

if [[ "$(git -C "$UPSTREAM" rev-parse HEAD)" != "$EXPECTED" ]]; then
  echo "ERROR: UniXNU checkout is not the pinned $EXPECTED" >&2
  exit 1
fi
if [[ ! -d "$XNU_WORK/.git" || ! -d "$PATCH_DIR" ]]; then
  echo "ERROR: staged Nabu tree / XNU work checkout not found" >&2
  exit 1
fi

patches=(
  kernel-sdk-root.patch
  non-apple-pmap-field.patch
  public-entitlements-header.patch
)
for name in "${patches[@]}"; do
  src="$UPSTREAM/patches/xnu/$name"
  dst="$PATCH_DIR/$name"
  if [[ ! -f "$src" ]]; then
    echo "ERROR: missing upstream patch $src" >&2
    exit 1
  fi
  if [[ -e "$dst" ]]; then
    if ! cmp -s "$src" "$dst"; then
      echo "ERROR: existing staged patch differs: $dst" >&2
      exit 1
    fi
    echo "Already staged: $name"
  else
    # Since the staging folder may be symlinked to a local scratch directory,
    # write the file only after proving no conflicting path exists.
    cp "$src" "$dst"
    echo "Staged: $name"
  fi
done

echo "Checking patch applicability against current XNU work tree..."
for name in "${patches[@]}"; do
  p="$PATCH_DIR/$name"
  if git -C "$XNU_WORK" apply --reverse --check "$p" >/dev/null 2>&1; then
    echo "Already applied: $name"
  elif git -C "$XNU_WORK" apply --check "$p" >/dev/null 2>&1; then
    echo "Ready: $name"
  else
    echo "WARNING: $name cannot be applied in current work tree; inspect before rebuilding." >&2
    exit 2
  fi
done
echo "Patch checks passed. Run ./unixnu build kernel separately."
