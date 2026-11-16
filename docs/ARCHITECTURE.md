<div dir="rtl">

# معمارية HS للنقل البري

## خريطة الطبقات

```
┌─────────────────────────────────────────────────────────────┐
│ UI (features/)                                               │
│  role_selection/   passenger/           driver/              │
│  شاشة البداية      الخريطة + اللوحات      التسجيل + اللوحة    │
├─────────────────────────────────────────────────────────────┤
│ الوصول للمتجر: HSAppScope (InheritedNotifier<RideStore>)     │
├─────────────────────────────────────────────────────────────┤
│ الحالة المشتركة: RideStore (ChangeNotifier) ← Mock Service  │
├─────────────────────────────────────────────────────────────┤
│ المنطق النقي: FareCalculator (haversine) · PlacesRepository │
├─────────────────────────────────────────────────────────────┤
│ النماذج: Ride · Place · Captain · FareEstimate · TripRecord │
└─────────────────────────────────────────────────────────────┘
```

## القرار المعماري الأساسي: متجر واحد لدورتين

المتطلب الجوهري: *"إذا طلب الراكب رحلة ثم قمت بالتبديل لوضع السائق، يظهر الطلب لدى السائق ويمكنه قبوله"* — بلا خادم خارجي.

الحل: `RideStore` واحد (`ChangeNotifier`) يُنشأ في `main.dart` كـ singleton ويُمرَّر عبر `HSAppScope` (InheritedNotifier). شاشات الراكب والسائق تقرأ نفس الكائن وتستمع لتغييراته:

- الراكب يستدعي `requestRide()` → الرحلة تدخل `RidePhase.searching`.
- `pendingRequest` getter يعرض الطلب لأي واجهة سائق طالما الحالة `searching`.
- السائق يستدعي `acceptRequest()` → الحالة تصبح `driverOnTheWay` ويرى الراكب التتبع فوراً.
- استمرارية الحالة عبر التبديل مضمونة لأن المتجر لا يُعاد إنشاؤه عند تغيير الدور — فقط الـ widget tree تتبدل.

## دورة حياة الرحلة (RidePhase)

```
idle ──requestRide()──▶ searching ──acceptRequest()──▶ driverOnTheWay
                          │ rejectRequest()/cancel              │ markDriverArrived()
                          ▼                                    ▼
                       cancelled ◀──cancelRideByPassenger    driverArrived
                                                               │ startRide()
                                                               ▼
                              completed ◀──rateRide()── rating ◀──endRide()
                                 (resetRide() → عودة idle)
```

## محاكاة الخدمة (Mock Service)

| ما يحتاجه خادم حقيقي | البديل في النموذج |
|---|---|
| مطابقة الراكب بكابتن | طلب الراكب يبقى `searching` حتى يقبل السائق البشري (في وضع السائق)، أو كابتن وهمي تلقائي بعد 4 ثوانٍ إذا فعّل المستخدم auto-accept |
| تتبع GPS لحظي | مواضع أيقونات محسوبة هندسياً بين نقطتي المسار حسب المرحلة |
| حفظ حساب السائق | `DriverProfile` في الذاكرة (طوال عمر الجلسة) |
| سجل الأرباح | `List<TripRecord>` + تجميع يومي بالتاريخ |

## التسعير

`FareCalculator` بمنطق نقي قابل للاختبار (بلا Flutter):
- المسافة: **haversine** بين الإحداثيات.
- المدة: المسافة ÷ متوسط سرعة حضرية 32 كم/س.
- الأجرة: `(افتتاحية 8 ر.س + مسافة×1.85 + دقائق×0.35) × مضاعف الفئة`، بحد أدنى 12 ر.س.
- مضاعفات الفئات: اقتصادي 1.0 · عائلي 1.35 · VIP 1.9.

## الخريطة

flutter_map + بلاطات OpenStreetMap العامة (`tile.openstreetmap.org`) — بلا مفاتيح API وبلا تكلفة، مع `userAgentPackageName: sa.hs.ride` التزاماً بسياسة الاستخدام. العلامات مخصصة (انطلاق أخضر/وجهة داكنة/كابتن متوهج) والمسار polyline بحدود بيضاء.

## طوبولوجيا المعاينة في الـsandbox

```
متصفح المستخدم ──▶ بوابة Caddy (81) ──▶ static-preview (3000)
                                          │
                                          ├── /            → public/mobile_app (بناء Flutter Web)
                                          ├── /api/status   → حالة البناء
                                          └── SPA fallback  → index.html
```

- البناء: `scripts/build-flutter-web.sh` — dart2js **O2** (O4 يقتل بالـ OOM على 4GB) + `--no-wasm-dry-run`، base-href `/`.
- الخادم: `mini-services/static-preview/server.mjs` — Node بلا تبعيات، كاش mtime/size، بطاقة "غير مبنى بعد" قبل أول بناء.
- الاستمرارية: `.zscripts/dev.sh` يعيد إطلاق الخادم + بناء المعاينة + تثبيت Flutter (`flutter-env/keeper.sh`) بعد أي reboot — والملفات الملتزمة في git فقط تنجو، لذلك يُدفع العمل بعد كل مرحلة.

## CI

- `build-apk.yml`: checkout v7 + Temurin 21 + Flutter 3.47.7 → pub get → **analyze gate** → **test gate** → `flutter build apk --release` → artifact + إرفاق بالـ Release عند الوسوم `v*`. مثبّت على ubuntu-24.04 عمداً (نفس قرار finacc-flutter2 المرجعي لتفادي تحول ubuntu-latest).
- `build-web-pages.yml`: نفس البوابات ثم بناء ويب بـ base-href `/hs-ride/` ودفع orphan لفرع gh-pages.

## سجل القرارات

| القرار | البديل المرفوض | السبب |
|---|---|---|
| ChangeNotifier واحد | provider/bloc/riverpod | الحاجة حالةً مشتركةً بسيطة بين شاشتين — إضافة حزمة تعقيد بلا فائدة |
| flutter_map + OSM | google_maps_flutter | المتطلب الصريح: بلا مفاتيح API مدفوعة |
| haversine يدوي | حزمة geolocator | المسافات بين نقاط ثابتة معروفة — 20 سطراً تكفي |
| بناء APK في CI فقط | بناء محلي | قرص الـsandbox (9.9G) لا يستوعب Gradle + Android SDK مع Flutter SDK |
| dart2js O2 | O4 | O4 يُقتل بـ OOM على حد 4GB ذاكرة |

</div>
