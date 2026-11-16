#!/usr/bin/env bash
#
# bootstrap-flutter.sh — install the Flutter SDK into a fresh sandbox.
#
# Downloads the pinned stable release (3.47.7) as a tar.xz (~1 GB download,
# ~2.5 GB extracted) into /home/z/flutter. Idempotent: skips if the SDK is
# already present and healthy. Takes ~3–4 minutes on a fast link.
#
# Env overrides: FLUTTER_INSTALL_DIR (default /home/z/flutter),
#                FLUTTER_VERSION (default 3.47.7-stable).

set -euo pipefail

FLUTTER_INSTALL_DIR="${FLUTTER_INSTALL_DIR:-/home/z/flutter}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7-stable}"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH_DIR="x64" ;;
  aarch64|arm64) ARCH_DIR="arm64" ;;
  *) echo "ERROR: unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

TARBALL="flutter_linux_${FLUTTER_VERSION}.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"

# x86_64 releases dropped the arch suffix in the archive name; fall back to the
# legacy x64-suffixed naming (and keep arm64 on its suffixed name).
if [[ "$ARCH_DIR" == "arm64" ]]; then
  TARBALL="flutter_linux_arm64_${FLUTTER_VERSION}.tar.xz"
  URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"
elif ! curl -fsI --max-time 20 "$URL" >/dev/null 2>&1; then
  TARBALL="flutter_linux_x64_${FLUTTER_VERSION}.tar.xz"
  URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"
fi

if [[ -x "$FLUTTER_INSTALL_DIR/bin/flutter" ]] && "$FLUTTER_INSTALL_DIR/bin/flutter" --version >/dev/null 2>&1; then
  echo "[bootstrap] Flutter SDK already present at $FLUTTER_INSTALL_DIR — nothing to do."
  "$FLUTTER_INSTALL_DIR/bin/flutter" --version | head -2
  exit 0
fi

echo "[bootstrap] No Flutter SDK found — installing $FLUTTER_VERSION into $FLUTTER_INSTALL_DIR"
echo "[bootstrap] Downloading $URL"
curl -fL --retry 3 -o "/tmp/$TARBALL" "$URL"

echo "[bootstrap] Extracting (~2.5 GB)…"
mkdir -p "$(dirname "$FLUTTER_INSTALL_DIR")"
rm -rf "$FLUTTER_INSTALL_DIR"
tar -xJf "/tmp/$TARBALL" -C "$(dirname "$FLUTTER_INSTALL_DIR")"
rm -f "/tmp/$TARBALL"

echo "[bootstrap] First run (cache warm-up)…"
"$FLUTTER_INSTALL_DIR/bin/flutter" config --no-analytics >/dev/null
"$FLUTTER_INSTALL_DIR/bin/flutter" --version | head -2

echo "[bootstrap] Done. Make sure it is on PATH for later shells:"
echo "  export PATH=\"$FLUTTER_INSTALL_DIR/bin:\$PATH\""
