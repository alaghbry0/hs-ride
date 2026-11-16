import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// وضع استخدام التطبيق: راكب أو سائق — الدورتان في نفس التطبيق.
enum AppRole { passenger, driver }

/// فئة المركبة المعروضة للراكب عند طلب الرحلة.
enum VehicleClass {
  economy('اقتصادي', 'سيارة مريحة بأفضل سعر', 1.0, 4),
  family('عائلي', 'سيارة عائلية واسعة تتسع لسبعة مقاعد', 1.35, 7),
  vip('VIP', 'سيارات فاخرة مع سائق محترف', 1.9, 4);

  const VehicleClass(this.label, this.description, this.priceMultiplier, this.seats);
  final String label;
  final String description;
  final double priceMultiplier;
  final int seats;
}

/// مراحل دورة حياة الرحلة من طلب الراكب حتى التقييم.
enum RidePhase {
  /// الراكب يجهّز الطلب (اختيار المسار والفئة) ولم يؤكد بعد.
  idle,

  /// تم تأكيد الطلب والنظام يبحث عن كابتن متاح.
  searching,

  /// الكابتن قبل الطلب وهو في الطريق لاستلام الراكب.
  driverOnTheWay,

  /// الكابتن وصل نقطة الانطلاق.
  driverArrived,

  /// الرحلة بدأت فعلياً (الراكب على متن المركبة).
  inProgress,

  /// الرحلة انتهت والراكب يقوّم الكابتن.
  rating,

  /// الرحلة اكتملت بالكامل.
  completed,

  /// الراكب ألغى الطلب قبل بدء الرحلة.
  cancelled;

  bool get isTerminal => this == completed || this == cancelled;
}

/// حالة السائق أثناء العمل: متاح لاستقبال الطلبات أو خارج الخدمة.
enum DriverStatus { offline, online }

/// موقع جغرافي مسمّى (نقطة انطلاق أو وجهة).
@immutable
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    this.category,
  });

  final String id;
  final String name;
  final String address;
  final LatLng position;
  final String? category;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': position.latitude,
        'lng': position.longitude,
        'category': category,
      };
}

/// بيانات الكابتن التي يسجّلها عند إنشاء حساب سائق جديد.
@immutable
class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.plateNumber,
    required this.joinedAt,
    this.rating = 4.9,
    this.totalTrips = 0,
  });

  final String name;
  final String phone;
  final String vehicleType;
  final String plateNumber;
  final DateTime joinedAt;
  final double rating;
  final int totalTrips;

  DriverProfile copyWith({int? totalTrips}) => DriverProfile(
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        joinedAt: joinedAt,
        rating: rating,
        totalTrips: totalTrips ?? this.totalTrips,
      );
}

/// كابتن وهمي يعرضه النظام عند البحث عن سائق (دورة الراكب).
@immutable
class Captain {
  const Captain({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    required this.totalTrips,
  });

  final String id;
  final String name;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final int totalTrips;
}

/// عرض السعر التقديري عند تجهيز الطلب.
@immutable
class FareEstimate {
  const FareEstimate({
    required this.vehicleClass,
    required this.distanceKm,
    required this.durationMin,
    required this.baseFare,
    required this.distanceFare,
    required this.total,
  });

  final VehicleClass vehicleClass;

  /// المسافة بالكيلومترات.
  final double distanceKm;

  /// مدة الرحلة التقديرية بالدقائق.
  final int durationMin;

  /// أجرة أساسية ثابتة لكل فئة.
  final double baseFare;

  /// أجرة المسافة المحسوبة.
  final double distanceFare;

  /// الإجمالي بعد ضرب الفئة في المضاعف.
  final double total;
}

/// الرحلة — الكائن المركزي المشترك بين دورتي الراكب والسائق.
@immutable
class Ride {
  const Ride({
    required this.id,
    required this.createdAt,
    required this.passengerName,
    required this.passengerPhone,
    required this.origin,
    required this.destination,
    required this.vehicleClass,
    required this.distanceKm,
    required this.durationMin,
    required this.fare,
    this.status = RidePhase.idle,
    this.captain,
    this.acceptedAt,
    this.startedAt,
    this.endedAt,
    this.rating,
    this.review,
    this.cancellationReason,
  });

  final String id;
  final DateTime createdAt;
  final String passengerName;
  final String passengerPhone;
  final Place origin;
  final Place destination;
  final VehicleClass vehicleClass;

  /// المسافة بالكيلومترات بين نقطتي الرحلة.
  final double distanceKm;
  final int durationMin;

  /// الأجرة النهائية بالريال السعودي.
  final double fare;
  final RidePhase status;

  /// الكابتن المقبِل للرحلة (null أثناء البحث).
  final Captain? captain;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? rating;
  final String? review;
  final String? cancellationReason;

  Ride copyWith({
    RidePhase? status,
    Captain? captain,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? rating,
    String? review,
    String? cancellationReason,
  }) =>
      Ride(
        id: id,
        createdAt: createdAt,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        origin: origin,
        destination: destination,
        vehicleClass: vehicleClass,
        distanceKm: distanceKm,
        durationMin: durationMin,
        fare: fare,
        status: status ?? this.status,
        captain: captain ?? this.captain,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        rating: rating ?? this.rating,
        review: review ?? this.review,
        cancellationReason: cancellationReason ?? this.cancellationReason,
      );

  /// عنوان مرحلة الرحلة الظاهر للراكب.
  String get statusTitle {
    switch (status) {
      case RidePhase.idle:
        return 'جهّز رحلتك';
      case RidePhase.searching:
        return 'جاري البحث عن كابتن';
      case RidePhase.driverOnTheWay:
        return 'الكابتن في الطريق إليك';
      case RidePhase.driverArrived:
        return 'وصل الكابتن';
      case RidePhase.inProgress:
        return 'الرحلة بدأت';
      case RidePhase.rating:
        return 'وصلت إلى وجهتك';
      case RidePhase.completed:
        return 'انتهت الرحلة';
      case RidePhase.cancelled:
        return 'أُلغيت الرحلة';
    }
  }

  /// وصف مرحلة الرحلة الظاهر للراكب.
  String statusSubtitle(String captainName) {
    switch (status) {
      case RidePhase.idle:
        return 'اختر نقطة الانطلاق والوجهة';
      case RidePhase.searching:
        return 'نبحث عن أقرب كابتن متاح في محيطك';
      case RidePhase.driverOnTheWay:
        return '$captainName في الطريق — تصله خلال دقائق';
      case RidePhase.driverArrived:
        return 'الكابتن بانتظارك في نقطة الانطلاق';
      case RidePhase.inProgress:
        return 'استمتع بالرحلة، نتمنى لك يوماً سعيداً';
      case RidePhase.rating:
        return 'كيف كانت تجربتك مع الكابتن؟';
      case RidePhase.completed:
        return 'شكراً لاستخدامك HS للنقل البري';
      case RidePhase.cancelled:
        return 'يمكنك طلب رحلة جديدة في أي وقت';
    }
  }
}

/// رحلة مكتملة داخل سجل الأرباح اليومية للكابتن.
@immutable
class TripRecord {
  const TripRecord({
    required this.id,
    required this.passengerName,
    required this.destinationName,
    required this.fare,
    required this.endedAt,
    required this.vehicleClass,
    required this.rating,
  });

  final String id;
  final String passengerName;
  final String destinationName;
  final double fare;
  final DateTime endedAt;
  final VehicleClass vehicleClass;
  final int? rating;
}
