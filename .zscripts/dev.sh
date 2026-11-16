#!/bin/bash
# =============================================================================
# dev.sh — يُستدعى تلقائياً عند إقلاع حاوية الـsandbox.
#
# المهام بالترتيب:
# 1. إعادة تثبيت Flutter SDK إن فُقد (keeper).
# 2. إطلاق خادم المعاينة الثابت على المنفذ 3000 (double-fork).
# 3. إعادة بناء معاينة الويب إن لم تكن مبنية (بالخلفية).
#
# ملاحظة: هذا الـsandbox لا يشغّل .zscripts تلقائياً (بيئة Z.ai الافتراضية)؛
# الملف موثق هنا للاستخدام اليدوي ولأي بيئة تدعم auto-boot.
# =============================================================================
exec 2>&1
set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "[dev] HS للنقل البري — إقلاع الخدمات..."

# 1) Flutter SDK keeper.
if [ -f mini-services/flutter-env/keeper.sh ]; then
  ( setsid nohup bash mini-services/flutter-env/keeper.sh >> /tmp/mini-service-flutter-env.log 2>&1 < /dev/null & ) || true
fi

# 2) خادم المعاينة الثابت (double-fork ليصمد أمام الحاصد).
if [ -f mini-services/static-preview/server.mjs ]; then
  ( setsid nohup bash -c "cd $PROJECT_DIR && exec node mini-services/static-preview/server.mjs" >> /tmp/mini-service-static-preview.log 2>&1 < /dev/null & ) || true
  echo "[dev] خادم المعاينة أُطلق على المنفذ 3000."
fi

# 3) إعادة بناء المعاينة إن لم تكن مبنية.
if [ ! -f public/mobile_app/index.html ]; then
  echo "[dev] بناء المعاينة غير موجود — بدء البناء بالخلفية..."
  (
    setsid nohup bash -c "
      cd $PROJECT_DIR
      export PATH=/home/z/flutter/bin:\$PATH
      bash scripts/build-flutter-web.sh --debug
    " >> /tmp/mini-service-build.log 2>&1 < /dev/null &
  ) || true
else
  echo "[dev] بناء المعاينة موجود — تخطي."
fi

echo "[dev] تم."
