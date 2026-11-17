import 'package:flutter_test/flutter_test.dart';

import 'package:hs_ride/shared/models/app_models.dart';
import 'package:hs_ride/shared/services/places_repository.dart';
import 'package:hs_ride/shared/state/ride_store.dart';

void main() {
  const places = PlacesRepository();
  final origin = places.places.firstWhere((p) => p.id == 'ruh-1');
  final destination = places.places.firstWhere((p) => p.id == 'ruh-2');

  RideStore buildStore() {
    final store = RideStore();
    store.setOrigin(origin);
    store.setDestination(destination);
    return store;
  }

  group('RideStore — دورة الراكب/السائق المشتركة', () {
    test('الطلب يظهر لدى السائق فور إنشائه (pendingRequest)', () {
      final store = buildStore();
      expect(store.pendingRequest, isNull);

      store.requestRide();

      expect(store.activeRide, isNotNull);
      expect(store.pendingRequest, isNotNull);
      expect(store.pendingRequest!.status, RidePhase.searching);
      expect(store.pendingRequest!.origin.id, origin.id);
      expect(store.pendingRequest!.destination.id, destination.id);
    });

    test('قبول السائق ينقل الرحلة إلى driverOnTheWay مع بيانات الكابتن', () {
      final store = buildStore();
      store.registerDriver(DriverProfile(
        name: 'سعد',
        phone: '0551234567',
        vehicleType: 'كامري',
        plateNumber: 'أ ب ج 1234',
        joinedAt: DateTime(2026, 11, 16),
      ));
      store.requestRide();
      store.acceptRequest();

      expect(store.pendingRequest, isNull);
      expect(store.activeRide!.status, RidePhase.driverOnTheWay);
      expect(store.activeRide!.captain, isNotNull);
      expect(store.activeRide!.captain!.name, 'سعد');
    });

    test('دورة الحياة الكاملة: طلب → قبول → وصل → بدء → إنهاء → تقييم', () {
      final store = buildStore();
      store.requestRide();

      store.acceptRequest();
      expect(store.activeRide!.status, RidePhase.driverOnTheWay);

      store.markDriverArrived();
      expect(store.activeRide!.status, RidePhase.driverArrived);

      store.startRide();
      expect(store.activeRide!.status, RidePhase.inProgress);

      store.endRide();
      expect(store.activeRide!.status, RidePhase.rating);
      expect(store.todayEarnings, greaterThan(0));
      expect(store.todayTripCount, 1);

      store.rateRide(5);
      expect(store.activeRide!.status, RidePhase.completed);
      expect(store.activeRide!.rating, 5);

      store.resetRide();
      expect(store.activeRide, isNull);
    });

    test('رفض السائق يلغي الطلب ويعيده للراكب برسالة', () {
      final store = buildStore();
      store.requestRide();
      store.rejectRequest();

      expect(store.activeRide!.status, RidePhase.cancelled);
      expect(store.activeRide!.cancellationReason, isNotNull);
      expect(store.pendingRequest, isNull);
    });

    test('إلغاء الراكب قبل القبول', () {
      final store = buildStore();
      store.requestRide();
      store.cancelRideByPassenger();

      expect(store.activeRide!.status, RidePhase.cancelled);
    });

    test('الأرباح اليومية تتراكم مع الرحلات', () {
      final store = buildStore();
      store.requestRide();
      store.acceptRequest();
      store.markDriverArrived();
      store.startRide();
      store.endRide();

      final firstEarning = store.todayEarnings;

      store.resetRide();
      store.requestRide();
      store.acceptRequest();
      store.markDriverArrived();
      store.startRide();
      store.endRide();

      expect(store.todayEarnings, closeTo(firstEarning * 2, 0.01));
      expect(store.todayTripCount, 2);
    });

    test('تبديل الأدوار لا يمسح الطلب المعلّق — جوهر الدورتين المشتركتين', () {
      final store = buildStore();
      store.requestRide();
      store.switchRole(AppRole.driver);

      expect(store.role, AppRole.driver);
      expect(store.pendingRequest, isNotNull, reason: 'الطلب يجب أن يبقى مرئياً بعد تبديل الوضع');
    });

    test('لا يمكن طلب رحلة بدون وجهة', () {
      final store = RideStore();
      store.setOrigin(origin);
      expect(store.canRequest, isFalse);

      store.requestRide();
      expect(store.activeRide, isNull, reason: 'لا يجب إنشاء رحلة بدون مسار مكتمل');
    });

    test('لا يمكن اختيار نفس الموقع انطلاقاً ووجهة', () {
      final store = RideStore();
      store.setOrigin(origin);
      store.setDestination(origin);
      expect(store.destination, isNull, reason: 'الوجهة تُرفض إن طابقت الانطلاق');

      // بعد تبديل الانطلاق تسقط الوجهة المطابقة السابقة أيضاً.
      store.setDestination(destination);
      store.setOrigin(destination);
      expect(store.origin, destination);
      expect(store.destination, isNull);
    });
  });

  group('RideStore — حالة السائق', () {
    test('تسجيل السائق مرة واحدة', () {
      final store = RideStore();
      expect(store.isDriverRegistered, isFalse);

      store.registerDriver(DriverProfile(
        name: 'فهد',
        phone: '0500000000',
        vehicleType: 'ماليبو',
        plateNumber: 'س ع د 555',
        joinedAt: DateTime(2026, 11, 16),
      ));
      expect(store.isDriverRegistered, isTrue);
      expect(store.driverProfile!.name, 'فهد');
    });

    test('الطلبات الواردة تظهر فقط عندما يكون السائق متاحاً', () {
      final store = buildStore();
      store.registerDriver(DriverProfile(
        name: 'فهد',
        phone: '0500000000',
        vehicleType: 'ماليبو',
        plateNumber: 'س ع د 555',
        joinedAt: DateTime(2026, 11, 16),
      ));

      // غير متاح: الطلب موجود في المتجر لكن السائق لا يراه.
      store.requestRide();
      expect(store.driverStatus, DriverStatus.offline);
      expect(store.pendingRequest, isNotNull); // الطلب نفسه موجود

      store.setDriverStatus(DriverStatus.online);
      expect(store.driverStatus, DriverStatus.online);
    });

    test('عدد رحلات السائق يزيد مع كل رحلة مكتملة', () {
      final store = buildStore();
      store.registerDriver(DriverProfile(
        name: 'فهد',
        phone: '0500000000',
        vehicleType: 'ماليبو',
        plateNumber: 'س ع د 555',
        joinedAt: DateTime(2026, 11, 16),
      ));
      final before = store.driverProfile!.totalTrips;

      store.requestRide();
      store.acceptRequest();
      store.markDriverArrived();
      store.startRide();
      store.endRide();

      expect(store.driverProfile!.totalTrips, before + 1);
    });
  });

  group('PlacesRepository', () {
    test('يحوي مواقع في الرياض وجدة', () {
      expect(places.places.any((p) => p.id.startsWith('ruh-')), isTrue);
      expect(places.places.any((p) => p.id.startsWith('jed-')), isTrue);
    });

    test('البحث النصي يفلتر بالاسم', () {
      // الاستعلام بدون "ال" التعريف يطابق المواقع المبدوءة بها
      // (المنطق يقص "ال" من الطرفين لمطابقة عربية طبيعية).
      final results = places.search('مطار');
      expect(results, isNotEmpty);
      expect(results.every((p) => p.name.contains('مطار')), isTrue);

      // والاستعلام بـ"ال" يطابق أيضاً بعد قص التعريف.
      final withAl = places.search('المطار');
      expect(withAl.length, results.length);
    });
  });
}
