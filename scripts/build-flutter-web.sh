#!/bin/bash
# =============================================================================
# بناء معاينة الويب لتطبيق HS للنقل البري داخل الـsandbox.
#
# المنفذ الوحيد الظاهر للمستخدم هو 3000 (خلف بوابة Caddy) — هذا السكربت
# يبني تطبيق Flutter كملفات ويب ثابتة إلى public/mobile_app ثم تُقدَّم
# من الخادم الثابت mini-services/static-preview.
#
# الاستخدام:
#   bash scripts/build-flutter-web.sh          # بناء release (O2)
#   bash scripts/build-flutter-web.sh --debug  # بناء debug أسرع
#
# حلقة التطوير (لا hot reload داخل الـsandbox):
#   تعديل lib/** → تشغيل هذا السكربت → تحديث صفحة المعاينة.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_DIR/mobile_app"
PUBLIC_DIR="$PROJECT_DIR/public/mobile_app"

# تحميل بيئة Flutter (تُنشأ عبر mini-services/flutter-env).
# shellcheck source=../mini-services/flutter-env/env.sh
if [ -f "$PROJECT_DIR/mini-services/flutter-env/env.sh" ]; then
  source "$PROJECT_DIR/mini-services/flutter-env/env.sh"
fi

BUILD_MODE="release"
if [ "${1:-}" = "--debug" ]; then
  BUILD_MODE="debug"
fi

# dart2js O4 يُقتل بـ OOM على sandbox بذاكرة 4GB — O2 هو الحل الأمثل
# (تصغير كامل بثلث ذروة الذاكرة). بناءات --debug تتجاهله.
D2JS_FLAG=""
if [ "$BUILD_MODE" = "release" ]; then
  D2JS_FLAG="--dart2js-optimization O2 --no-wasm-dry-run"
fi

echo "[build-flutter-web] بناء mobile_app للويب ($BUILD_MODE)..."
cd "$APP_DIR"
# shellcheck disable=SC2086
flutter build web "--${BUILD_MODE}" --base-href / $D2JS_FLAG

echo "[build-flutter-web] النشر إلى $PUBLIC_DIR..."
rm -rf "$PUBLIC_DIR"
mkdir -p "$PUBLIC_DIR"
cp -r build/web/* "$PUBLIC_DIR/"

echo "[build-flutter-web] تم — المعاينة: http://127.0.0.1:3000/ (حدّث الصفحة)"
