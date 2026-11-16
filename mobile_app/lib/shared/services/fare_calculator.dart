import 'dart:math' as math;

import '../models/app_models.dart';

/// حاسبة الأجرة والمسافة — منطق نقي بلا واجهة، قابل للاختبار الآلي.
///
/// التعرفة مستوحاة من تسعيرة أجرة سيارات الأجرة المحلية في السعودية
/// (أجرة افتتاحية + سعر لكل كيلومتر) وهي قيم تقديرية لنموذج أولي.
class FareCalculator {
  const FareCalculator({
    this.baseFare = 8.0,
    this.perKm = 1.85,
    this.perMinute = 0.35,
    this.minimumFare = 12.0,
    this.avgSpeedKmh = 32.0,
  });

  /// الأجرة الافتتاحية الثابتة (ر.س).
  final double baseFare;

  /// أجرة الكيلومتر الواحد (ر.س).
  final double perKm;

  /// أجرة الدقيقة الواحدة (ر.س) — تُحتسب على المدة التقديرية.
  final double perMinute;

  /// أدنى أجرة مقبولة (ر.س).
  final double minimumFare;

  /// متوسط سرعة المركبة داخل المدينة (كم/س) لتقدير المدة.
  final double avgSpeedKmh;

  /// صيغة haversine — المسافة بالكيلومترات بين نقطتين جغرافيتين.
  double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  /// المدة التقديرية بالدقائق بناء على المسافة ومتوسط السرعة.
  int durationMinutes(double km) => (km / avgSpeedKmh * 60).round().clamp(1, 240);

  /// عرض سعر تقديري لفئة مركبة معينة بين نقطتين.
  FareEstimate estimate({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required VehicleClass vehicleClass,
  }) {
    final km = distanceKm(originLat, originLng, destLat, destLng);
    final minutes = durationMinutes(km);
    final distanceFare = km * perKm;
    final timeFare = minutes * perMinute;
    final subtotal = baseFare + distanceFare + timeFare;
    final total = math.max(minimumFare, subtotal * vehicleClass.priceMultiplier);
    return FareEstimate(
      vehicleClass: vehicleClass,
      distanceKm: km,
      durationMin: minutes,
      baseFare: baseFare,
      distanceFare: distanceFare + timeFare,
      total: total,
    );
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;
}
