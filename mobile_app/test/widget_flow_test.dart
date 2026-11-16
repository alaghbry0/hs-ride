import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hs_ride/app.dart';
import 'package:hs_ride/shared/models/app_models.dart';
import 'package:hs_ride/shared/services/places_repository.dart';
import 'package:hs_ride/shared/state/ride_store.dart';

void main() {
  const places = PlacesRepository();
  final origin = places.places.firstWhere((p) => p.id == 'ruh-1');
  final destination = places.places.firstWhere((p) => p.id == 'ruh-2');

  Widget wrapApp(RideStore store) =>
      MaterialApp(home: HSAppShell(store: store), debugShowCheckedModeBanner: false);

  testWidgets('شاشة البداية تعرض خيارَي الراكب والسائق وتتيح التبديل', (tester) async {
    final store = RideStore();
    await tester.pumpWidget(wrapApp(store));
    await tester.pumpAndSettle();

    expect(find.text('وضع الراكب'), findsOneWidget);
    expect(find.text('وضع السائق'), findsOneWidget);
    expect(find.textContaining('HS للنقل البري'), findsWidgets);

    // اختيار وضع الراكب يفتح شاشة الطلب.
    await tester.tap(find.text('وضع الراكب'));
    await tester.pumpAndSettle();
    expect(find.textContaining('نقطة الانطلاق'), findsWidgets);
  });

  testWidgets('دورة الراكب الكاملة عبر الواجهة: طلب → قبول (وضع السائق) → تقييم', (tester) async {
    final store = RideStore();
    await tester.pumpWidget(wrapApp(store));
    await tester.pumpAndSettle();

    // 1) وضع الراكب.
    await tester.tap(find.text('وضع الراكب'));
    await tester.pumpAndSettle();

    // 2) اختيار الانطلاق والوجهة.
    await tester.tap(find.textContaining('من أين تنطلق؟'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(origin.name).last);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('إلى أين تذهب؟'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(destination.name).last);
    await tester.pumpAndSettle();

    // 3) تأكيد الطلب.
    await tester.tap(find.textContaining('تأكيد الطلب'));
    await tester.pumpAndSettle();
    expect(find.textContaining('جاري البحث عن كابتن'), findsOneWidget);

    // 4) التبديل لوضع السائق — يجب أن يظهر الطلب المعلّق في شاشة البداية.
    await tester.tap(find.textContaining('تبديل الوضع'));
    await tester.pumpAndSettle();
    expect(find.textContaining('طلب رحلة معلّق'), findsOneWidget);

    // 5) دخول وضع السائق: شاشة تسجيل السائق.
    await tester.tap(find.text('وضع السائق'));
    await tester.pumpAndSettle();

    // 6) تسجيل سائق جديد.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'الاسم الكامل'),
      'خالد الحربي',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'رقم الجوال'),
      '0551234567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'رقم اللوحة'),
      'ر س ط 1001',
    );
    await tester.tap(find.textContaining('أوافق على شروط'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء حساب الكابتن'));
    await tester.pumpAndSettle();

    // 7) لوحة التحكم: خارج الخدمة أولاً ثم تفعيل الاستقبال.
    expect(find.textContaining('خارج الخدمة'), findsOneWidget);
    await tester.tap(find.textContaining('التوفر لاستقبال الطلبات'));
    await tester.pumpAndSettle();

    // 8) بطاقة الطلب الوارد تظهر الطلب الذي أنشأه الراكب قبل التبديل.
    expect(find.text('طلب جديد!'), findsOneWidget);
    expect(find.textContaining(destination.name), findsWidgets);
    await tester.tap(find.textContaining('قبول'));
    await tester.pumpAndSettle();

    // 9) إدارة الرحلة النشطة: وصلت → بدء → إنهاء.
    await tester.tap(find.text('وصلت إلى العميل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدء الرحلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('إنهاء الرحلة وتحصيل'));
    await tester.pumpAndSettle();

    // 10) العودة لوضع الراكب — يجب أن يجد شاشة التقييم.
    await tester.tap(find.textContaining('تبديل الوضع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وضع الراكب'));
    await tester.pumpAndSettle();

    expect(find.textContaining('وصلت إلى وجهتك'), findsOneWidget);
  });

  testWidgets('أسماء المراحل تعرض نصوصاً عربية صحيحة', (tester) async {
    final ride = Ride(
      id: 'HS-1',
      createdAt: DateTime(2026, 11, 16),
      passengerName: 'أحمد',
      passengerPhone: '0500000000',
      origin: origin,
      destination: destination,
      vehicleClass: VehicleClass.economy,
      distanceKm: 12.5,
      durationMin: 25,
      fare: 33.5,
    );
    expect(ride.statusTitle, 'جهّز رحلتك');
    expect(
      ride.copyWith(status: RidePhase.inProgress).statusTitle,
      'الرحلة بدأت',
    );
  });
}
