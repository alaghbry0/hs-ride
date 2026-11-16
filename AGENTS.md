<div dir="rtl">

# قواعد العمل لوكلاء الذكاء الاصطناعي — HS للنقل البري

تطبيق Flutter عربي RTL (دورة راكب + دورة سائق في تطبيق واحد بخريطة OpenStreetMap)، مبني على قالب `flutter-sandbox-template` وبأسلوب مشروع `finacc-flutter2` المرجعي.

## قواعد أساسية

- **`flutter analyze` صفر مشاكل قبل كل التزام** — أي مخرج analyzer يُصلح قبل الدفع.
- **`flutter test` يجب أن يمر** — الجناح في `mobile_app/test/` (منطق التسعير + المتجر المشترك + تدفق الويدجت).
- **لا تلتزم أبداً** `mobile_app/build/` أو `.dart_tool/` أو `public/mobile_app/` — مخرجات قابلة لإعادة الإنتاج.
- **ادفع بعد كل مرحلة منطقية** — الـsandbox قد يُعاد بناؤه؛ ما ليس في git يُفقد.
- اعتماديات التشغيل مقصودة: `flutter_map` + `latlong2` فقط فوق SDK — أي إضافة تتطلب مبرراً قوياً.
- الواجهة **عربية RTL بالكامل** — أي نص جديد بالعربية، والعملة ر.س، والمسافة كم.

## أوامر جاهزة

```bash
export PATH=/home/z/flutter/bin:$PATH       # بعد bootstrap

cd mobile_app
flutter pub get
flutter analyze                             # بوابة الجودة 1
flutter test                                # بوابة الجودة 2

bash scripts/build-flutter-web.sh           # بناء المعاينة → public/mobile_app
node mini-services/static-preview/server.mjs # خادم المعاينة على 3000
```

## بيئة الـsandbox (Z.ai)

- **المنفذ 3000 هو الوحيد الظاهر** خلف بوابة Caddy — يملكه `static-preview`.
- **الحاصد يقتل عمليات أمر الأداة عند انتهائه** — الخادم يُطلق بنمط double-fork:
  ```bash
  ( setsid nohup bash -c 'cd /home/z/my-project && exec node mini-services/static-preview/server.mjs' >/dev/null 2>&1 </dev/null & )
  ```
- **Flutter SDK في `/home/z/flutter` خارج git** — `scripts/bootstrap-flutter.sh` يعيد تثبيته (~3-4 دقائق) و`mini-services/flutter-env/keeper.sh` يفعل ذلك تلقائياً عند الإقلاع.
- **لا hot reload عبر المعاينة** — الحلقة: تعديل → `build-flutter-web.sh` → تحديث الصفحة.
- الذاكرة ~4GB — بناء الويب بـ **O2** حصراً.

## الإصدارات

- التزامات بصيغة `V{n}: وصف` + وسم `v{n}` تسلسلي إلحاقي (لا يُنقل ولا يُحذف).
- كل وسم `v*` يشغّل بناء APK (مرفق بالـRelease) ومعاينة Pages تلقائياً.

## نطاق النموذج الأولي (افتراضات مقصودة)

- بيانات السائق والرحلات **في الذاكرة** — تُفقد بإغلاق التطبيق (لا قاعدة بيانات في النموذج).
- "الشبكة" محاكاة محلية: السائق البشري (في وضع السائق) هو من يقبل/يرفض فعلياً.
- مواضع الكابتن على الخريطة هندسية تقريبية، لا تتبع GPS حقيقي.
- أرقام التسعير تقديرية مستوحاة من أجرة التاكسي المحلية.

</div>
