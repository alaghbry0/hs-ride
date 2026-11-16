#!/bin/bash
# إعادة تثبيت Flutter SDK تلقائياً عند فقدانه بعد إعادة تشغيل الـsandbox.
# يُستدعى من .zscripts/dev.sh عند الإقلاع — التنزيل يستغرق ~3-4 دقائق.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="/home/z/flutter/bin:$PATH"
if [ -x /home/z/flutter/bin/flutter ] && flutter --version >/dev/null 2>&1; then
  echo "[flutter-env] Flutter SDK موجود — لا شيء لفعله."
  exit 0
fi
echo "[flutter-env] Flutter SDK مفقود — إعادة التثبيت..."
bash "$PROJECT_DIR/scripts/bootstrap-flutter.sh" || echo "[flutter-env] تحذير: فشل التثبيت التلقائي"
