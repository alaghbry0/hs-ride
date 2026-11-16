import 'package:flutter_test/flutter_test.dart';

import 'package:hs_ride/shared/models/app_models.dart';
import 'package:hs_ride/shared/services/fare_calculator.dart';
import 'package:hs_ride/shared/services/places_repository.dart';

void main() {
  const calc = FareCalculator();
  const places = PlacesRepository();

  group('FareCalculator.distanceKm — صيغة haversine', () {
    test('المسافة بين نفس النقطة = صفر', () {
      expect(calc.distanceKm(24.7136, 46.6753, 24.7136, 46.6753), 0);
    });

    test('المسافة الرياض -> مطار الملك خالد ≈ 27 كم (± 3)', () {
      final d = calc.distanceKm(24.7136, 46.6753, 24.9576, 46.6988);
      expect(d, greaterThan(24));
      expect(d, lessThan(30));
    });

    test('المسافة الرياض -> جدة ≈ 850 كم (± 80) — عبر مستودع المواقع', () {
      final riyadh = places.places.firstWhere((p) => p.id == 'ruh-1');
      final jeddah = places.places.firstWhere((p) => p.id == 'jed-1');
      final d = calc.distanceKm(
        riyadh.position.latitude,
        riyadh.position.longitude,
        jeddah.position.latitude,
        jeddah.position.longitude,
      );
      expect(d, greaterThan(780));
      expect(d, lessThan(950));
    });

    test('المسافة متماثلة (a→b = b→a)', () {
      final ab = calc.distanceKm(24.71, 46.67, 24.95, 46.70);
      final ba = calc.distanceKm(24.95, 46.70, 24.71, 46.67);
      expect(ab, closeTo(ba, 0.0001));
    });
  });

  group('FareCalculator.durationMinutes', () {
    test('مدة موجبة لأي مسافة', () {
      expect(calc.durationMinutes(5), greaterThan(0));
      expect(calc.durationMinutes(0.1), greaterThanOrEqualTo(1));
    });

    test('مدة 10 كم عند 32 كم/س ≈ 19 دقيقة', () {
      expect(calc.durationMinutes(10), closeTo(19, 1));
    });
  });

  group('FareCalculator.estimate — التسعير', () {
    final o = places.places.firstWhere((p) => p.id == 'ruh-1');
    final d = places.places.firstWhere((p) => p.id == 'ruh-2');

    FareEstimate est(VehicleClass vc) => calc.estimate(
          originLat: o.position.latitude,
          originLng: o.position.longitude,
          destLat: d.position.latitude,
          destLng: d.position.longitude,
          vehicleClass: vc,
        );

    test('الاقتصادي أرخص من العائلي وهو أرخص من VIP', () {
      final eco = est(VehicleClass.economy);
      final fam = est(VehicleClass.family);
      final vip = est(VehicleClass.vip);
      expect(eco.total, lessThan(fam.total));
      expect(fam.total, lessThan(vip.total));
    });

    test('الإجمالي = max(الأدنى, المجموع × مضاعف الفئة)', () {
      final eco = est(VehicleClass.economy);
      final expected = (8.0 + eco.distanceFare) * 1.0;
      expect(eco.total, closeTo(expected, 0.5));
    });

    test('لا يقل الإجمالي عن الأجرة الدنيا 12 ر.س', () {
      // مسافة قصيرة جداً (نفس الحي).
      final e = calc.estimate(
        originLat: 24.7115,
        originLng: 46.6745,
        destLat: 24.7130,
        destLng: 46.6760,
        vehicleClass: VehicleClass.economy,
      );
      expect(e.total, greaterThanOrEqualTo(12.0));
    });

    test('المسافة والمدة داخل العرض مطابقتان للحاسبة', () {
      final e = est(VehicleClass.family);
      final km = calc.distanceKm(
        o.position.latitude,
        o.position.longitude,
        d.position.latitude,
        d.position.longitude,
      );
      expect(e.distanceKm, closeTo(km, 0.001));
      expect(e.durationMin, calc.durationMinutes(km));
    });
  });

  group('VehicleClass — المضاعفات', () {
    test('المضاعفات تصاعدية ومعقولة', () {
      expect(VehicleClass.economy.priceMultiplier, 1.0);
      expect(VehicleClass.family.priceMultiplier, greaterThan(1.0));
      expect(VehicleClass.vip.priceMultiplier, greaterThan(VehicleClass.family.priceMultiplier));
    });
  });
}
