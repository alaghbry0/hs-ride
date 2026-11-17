import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/fare_calculator.dart';
import '../services/places_repository.dart';

/// الحالة المشتركة المركزية لدورتي الراكب والسائق — "الخادم الوهمي".
///
/// كائن واحد يعيش في أعلى شجرة الواجهة (ChangeNotifier) تستهلكه شاشات
/// الراكب وشاشات السائق معاً، لذا أي طلب ينشئه الراكب يظهر فوراً لدى
/// السائق عند التبديل بين الوضعين — بلا خادم خارجي وبلا اتصال شبكة.
///
/// محاكاة "الشبكة": عندما يطلب الراكب رحلة يبقى الطلب في حالة
/// [RidePhase.searching] حتى يقبل السائق (الحقيقي في وضع السائق) الطلب.
/// إذا لم يكن هناك سائق بشري، يمكن تمكين [autoAcceptEnabled] فيظهر
/// كابتن وهمي بعد مهلة قصيرة — لتجربة دورة الراكب وحدها.
class RideStore extends ChangeNotifier {
  RideStore({
    FareCalculator? fareCalculator,
    PlacesRepository? placesRepository,
  })  : fareCalculator = fareCalculator ?? const FareCalculator(),
        placesRepository = placesRepository ?? const PlacesRepository();

  final FareCalculator fareCalculator;
  final PlacesRepository placesRepository;

  // ── الوضع والهوية ──────────────────────────────────────────────────────

  AppRole _role = AppRole.passenger;
  AppRole get role => _role;

  DriverProfile? _driverProfile;
  DriverProfile? get driverProfile => _driverProfile;
  bool get isDriverRegistered => _driverProfile != null;

  /// إنشاؤه مرة واحدة عند تسجيل السائق — يستمر طوال عمر التطبيق.
  void registerDriver(DriverProfile profile) {
    _driverProfile = profile;
    notifyListeners();
  }

  /// الانتقال بين وضع الراكب ووضع السائق (شاشة البداية أو زر التبديل).
  void switchRole(AppRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  // ── حالة السائق ────────────────────────────────────────────────────────

  DriverStatus _driverStatus = DriverStatus.offline;
  DriverStatus get driverStatus => _driverStatus;

  bool _autoAcceptEnabled = false;
  bool get autoAcceptEnabled => _autoAcceptEnabled;

  void toggleDriverStatus() {
    _driverStatus =
        _driverStatus == DriverStatus.online ? DriverStatus.offline : DriverStatus.online;
    notifyListeners();
  }

  void setDriverStatus(DriverStatus status) {
    _driverStatus = status;
    notifyListeners();
  }

  void toggleAutoAccept() {
    _autoAcceptEnabled = !_autoAcceptEnabled;
    if (_autoAcceptEnabled) _maybeScheduleAutoAccept();
    notifyListeners();
  }

  // ── تجهيز طلب الراكب ───────────────────────────────────────────────────

  Place? _origin;
  Place? get origin => _origin;

  Place? _destination;
  Place? get destination => _destination;

  VehicleClass _selectedClass = VehicleClass.economy;
  VehicleClass get selectedClass => _selectedClass;

  bool get canRequest =>
      _origin != null && _destination != null && _origin!.id != _destination!.id;

  void setOrigin(Place? place) {
    if (_activeRide != null && !_activeRide!.status.isTerminal) return;
    _origin = place;
    if (place != null && _destination?.id == place.id) _destination = null;
    notifyListeners();
  }

  void setDestination(Place? place) {
    if (_activeRide != null && !_activeRide!.status.isTerminal) return;
    // رفض الوجهة إن طابقت نقطة الانطلاق — يجب اختيار موقعين مختلفين.
    if (place != null && _origin?.id == place.id) return;
    _destination = place;
    notifyListeners();
  }

  void selectClass(VehicleClass vehicleClass) {
    _selectedClass = vehicleClass;
    notifyListeners();
  }

  /// عرض السعر للفئة المختارة — null إن لم يكتمل المسار.
  FareEstimate? get fareEstimate {
    if (_origin == null || _destination == null) return null;
    return fareCalculator.estimate(
      originLat: _origin!.position.latitude,
      originLng: _origin!.position.longitude,
      destLat: _destination!.position.latitude,
      destLng: _destination!.position.longitude,
      vehicleClass: _selectedClass,
    );
  }

  /// عروض الأسعار للفئات الثلاث دفعة واحدة (شاشة اختيار الفئة).
  List<FareEstimate> get allEstimates => VehicleClass.values
      .map((vc) => fareCalculator.estimate(
            originLat: _origin!.position.latitude,
            originLng: _origin!.position.longitude,
            destLat: _destination!.position.latitude,
            destLng: _destination!.position.longitude,
            vehicleClass: vc,
          ))
      .toList();

  // ── الرحلة النشطة ──────────────────────────────────────────────────────

  Ride? _activeRide;
  Ride? get activeRide => _activeRide;

  /// الطلب المعلّق الذي ينتظر قرار السائق (ظهر لدى السائق عند التبديل).
  Ride? get pendingRequest => _activeRide?.status == RidePhase.searching ? _activeRide : null;

  /// الرحلة التي يديرها السائق حالياً (بعد القبول).
  Ride? get driverActiveRide {
    final ride = _activeRide;
    if (ride == null) return null;
    switch (ride.status) {
      case RidePhase.driverOnTheWay:
      case RidePhase.driverArrived:
      case RidePhase.inProgress:
        return ride;
      default:
        return null;
    }
  }

  int _requestCounter = 0;

  /// الراكب يؤكد الطلب → يدخل الطلب قائمة البحث ويظهر فوراً لدى السائق.
  void requestRide() {
    if (!canRequest) return;
    _requestCounter++;
    _activeRide = Ride(
      id: 'HS-$_requestCounter',
      createdAt: DateTime.now(),
      passengerName: 'أحمد',
      passengerPhone: '05xxxxxxxx',
      origin: _origin!,
      destination: _destination!,
      vehicleClass: _selectedClass,
      distanceKm: fareEstimate!.distanceKm,
      durationMin: fareEstimate!.durationMin,
      fare: fareEstimate!.total,
      status: RidePhase.searching,
    );
    if (_autoAcceptEnabled) _maybeScheduleAutoAccept();
    notifyListeners();
  }

  /// الراكب يلغي طلبه قبل بدء الرحلة.
  void cancelRideByPassenger({String reason = 'أُلغي من قبل الراكب'}) {
    final ride = _activeRide;
    if (ride == null || ride.status.isTerminal) return;
    _activeRide = ride.copyWith(status: RidePhase.cancelled, cancellationReason: reason);
    notifyListeners();
  }

  // ── قرارات السائق ──────────────────────────────────────────────────────

  /// السائق يقبل الطلب → يصبح "في الطريق إلى الراكب" فوراً.
  void acceptRequest() {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.searching) return;
    final captain = _captainFromProfile();
    _activeRide = ride.copyWith(
      status: RidePhase.driverOnTheWay,
      captain: captain,
      acceptedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// السائق يرفض الطلب → يعود الراكب لشاشة الطلب مع رسالة.
  void rejectRequest({String reason = 'لم يتم العثور على كابتن'}) {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.searching) return;
    _activeRide = ride.copyWith(
      status: RidePhase.cancelled,
      cancellationReason: reason,
    );
    notifyListeners();
  }

  /// السائق يعلن وصوله لنقطة الانطلاق.
  void markDriverArrived() {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.driverOnTheWay) return;
    _activeRide = ride.copyWith(status: RidePhase.driverArrived);
    notifyListeners();
  }

  /// السائق يبدأ الرحلة بعد ركوب الراكب.
  void startRide() {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.driverArrived) return;
    _activeRide = ride.copyWith(status: RidePhase.inProgress, startedAt: DateTime.now());
    notifyListeners();
  }

  /// السائق ينتهي الرحلة وتحصيل المبلغ → ينتقل الراكب لمرحلة التقييم.
  void endRide() {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.inProgress) return;
    _activeRide = ride.copyWith(status: RidePhase.rating, endedAt: DateTime.now());
    _tripRecords.insert(0, _recordFromRide(ride));
    if (_driverProfile != null) {
      _driverProfile = _driverProfile!.copyWith(totalTrips: _driverProfile!.totalTrips + 1);
    }
    notifyListeners();
  }

  /// الراكب يقيّم الكابتن بعد الوصول.
  void rateRide(int stars, {String? review}) {
    final ride = _activeRide;
    if (ride == null || ride.status != RidePhase.rating) return;
    _activeRide = ride.copyWith(status: RidePhase.completed, rating: stars, review: review);
    notifyListeners();
  }

  /// بدء دورة جديدة — تمسح الرحلة النهائية وتعيد الراكب لشاشة الطلب.
  void resetRide() {
    _activeRide = null;
    notifyListeners();
  }

  // ── سجل الأرباح (دورة السائق) ─────────────────────────────────────────

  final List<TripRecord> _tripRecords = [];
  List<TripRecord> get tripRecords => List.unmodifiable(_tripRecords);

  /// أرباح اليوم الميلادي الحالي.
  double get todayEarnings =>
      _tripRecords.where((t) => _isToday(t.endedAt)).fold(0.0, (sum, t) => sum + t.fare);

  int get todayTripCount => _tripRecords.where((t) => _isToday(t.endedAt)).length;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  TripRecord _recordFromRide(Ride ride) => TripRecord(
        id: ride.id,
        passengerName: ride.passengerName,
        destinationName: ride.destination.name,
        fare: ride.fare,
        endedAt: DateTime.now(),
        vehicleClass: ride.vehicleClass,
        rating: null,
      );

  // ── محاكاة القبول التلقائي (تجربة دورة الراكب منفردة) ──────────────────

  Timer? _autoAcceptTimer;

  void _maybeScheduleAutoAccept() {
    if (!_autoAcceptEnabled) return;
    _autoAcceptTimer?.cancel();
    _autoAcceptTimer = Timer(const Duration(seconds: 4), () {
      final ride = _activeRide;
      if (ride == null || ride.status != RidePhase.searching) return;
      _activeRide = ride.copyWith(
        status: RidePhase.driverOnTheWay,
        captain: _captainFromProfile(),
        acceptedAt: DateTime.now(),
      );
      notifyListeners();
    });
  }

  Captain _captainFromProfile() {
    final p = _driverProfile;
    if (p == null) return _fallbackCaptain;
    return Captain(
      id: 'me',
      name: p.name,
      vehicle: p.vehicleType,
      plateNumber: p.plateNumber,
      rating: p.rating,
      totalTrips: p.totalTrips,
    );
  }

  Captain get _fallbackCaptain => const Captain(
        id: 'demo',
        name: 'خالد الحربي',
        vehicle: 'تويوتا كامري 2024',
        plateNumber: 'ب ط ح 4821',
        rating: 4.8,
        totalTrips: 1250,
      );

  @override
  void dispose() {
    _autoAcceptTimer?.cancel();
    super.dispose();
  }
}
