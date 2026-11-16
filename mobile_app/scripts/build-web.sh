#!/usr/bin/env bash
#
# build-web.sh — build the debug web bundle for sandbox preview.
#
# Usage:
#   bash scripts/build-web.sh [--base-href /flutter/] [--release]
#
# Defaults: debug build, base href /flutter/ (the gateway-hub subpath used by
# the live sandbox topology). Debug builds use DDC modules: incremental
# rebuilds take ~15–45 s, and the bundle works fine through the preview proxy
# chain. Pass --release for a dart2js production build (slower, smaller, no
# debug banner).
#
# CanvasKit is pinned LOCALLY (canvaskit/ is copied into build/web by the
# toolchain and FLUTTER_WEB_CANVASKIT_URL points at it) so the preview never
# depends on gstatic being reachable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FLUTTER_BIN="${FLUTTER_BIN:-/home/z/flutter/bin/flutter}"

BASE_HREF="/flutter/"
BUILD_MODE="debug"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-href) BASE_HREF="${2:?}"; shift 2 ;;
    --release)   BUILD_MODE="release"; shift ;;
    --)          shift; EXTRA_ARGS+=("$@"); break ;;
    *)           EXTRA_ARGS+=("$1"); shift ;;
  esac
done

if [[ ! -x "$FLUTTER_BIN" ]]; then
  cat >&2 <<EOF
ERROR: Flutter SDK not found at $FLUTTER_BIN
Run the bootstrap script first (~3–4 minutes, one-time):
  bash scripts/bootstrap-flutter.sh
Or point FLUTTER_BIN at an existing flutter binary.
EOF
  exit 1
fi

cd "$PROJECT_DIR"

echo "[build-web] flutter pub get"
"$FLUTTER_BIN" pub get

echo "[build-web] building ($BUILD_MODE, base-href $BASE_HREF)"
if [[ "$BUILD_MODE" == "release" ]]; then
  "$FLUTTER_BIN" build web \
    --release \
    --base-href "$BASE_HREF" \
    --dart-define="FLUTTER_WEB_CANVASKIT_URL=${BASE_HREF}canvaskit/" \
    "${EXTRA_ARGS[@]}"
else
  "$FLUTTER_BIN" build web \
    --debug \
    --base-href "$BASE_HREF" \
    --dart-define="FLUTTER_WEB_CANVASKIT_URL=${BASE_HREF}canvaskit/" \
    "${EXTRA_ARGS[@]}"
fi

echo "[build-web] done → $PROJECT_DIR/build/web ($(du -sh "$PROJECT_DIR/build/web" | cut -f1))"
echo "[build-web] reload the preview at $BASE_HREF (hard-refresh to bypass cache)"
