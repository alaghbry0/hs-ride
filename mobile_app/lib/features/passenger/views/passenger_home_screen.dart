import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/app_models.dart';
import '../../../../shared/state/ride_store.dart';
import '../../../../shared/widgets/hs_app_scope.dart';
import '../../widgets/ride_map.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/vehicle_class_sheet.dart';
import '../widgets/ride_tracking_sheet.dart';

/// شاشة الراكب الرئيسية — خريطة تفاعلية + لوحة سفلية تتغير حسب مرحلة الرحلة:
///
/// 1. تجهيز الطلب (اختيار الانطلاق/الوجهة والفئة والسعر التقديري).
/// 2. البحث عن كابتن.
/// 3. الكابتن في الطريق / وصل / الرحلة بدأت (تتبع لحظي).
/// 4. الوصول والتقييم.
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key, required this.onSwitchRole});

  final VoidCallback onSwitchRole;

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);

    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final ride = store.activeRide;
          final phase = ride?.status ?? RidePhase.idle;

          // العناصر المعروضة على الخريطة: نقاط الانطلاق/الوجهة + مسار.
          final originPos = ride?.origin.position ?? store.origin?.position;
          final destPos = ride?.destination.position ?? store.destination?.position;
          final showRoute = originPos != null && destPos != null;

          return Stack(
            children: [
              // ── الخريطة ─────────────────────────────────────────────
              RideMap(
                controller: _mapController,
                center: store.placesRepository.mapCenter,
                zoom: store.placesRepository.initialZoom,
                origin: originPos,
                destination: destPos,
                showRoute: showRoute,
                driverPosition: _driverMarkerPosition(store),
                driverHeading: phase == RidePhase.driverOnTheWay,
              ),

              // ── الشريط العلوي ──────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _TopChip(
                        icon: Icons.swap_horiz,
                        label: phase == RidePhase.idle ? 'تبديل الوضع' : store.role == AppRole.driver ? 'وضع السائق' : 'وضع الراكب',
                        onTap: widget.onSwitchRole,
                      ),
                      const Spacer(),
                      _TopChip(
                        icon: Icons.person_outline,
                        label: 'أحمد',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // ── اللوحة السفلية حسب المرحلة ─────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomSheetFor(context, store, phase),
              ),
            ],
          );
        },
      ),
    );
  }

  /// موضع أيقونة الكابتن على الخريطة أثناء "في الطريق".
  LatLng? _driverMarkerPosition(RideStore store) {
    final ride = store.activeRide;
    if (ride == null) return null;
    switch (ride.status) {
      case RidePhase.searching:
      case RidePhase.idle:
        return null;
      default:
        // نقطة بين المنتصف ونقطة الانطلاق — محاكاة تقدم الكابتن.
        final o = ride.origin.position;
        final midLat = (o.latitude + 0.008);
        final midLng = (o.longitude - 0.006);
        return LatLng(midLat, midLng);
    }
  }

  Widget _bottomSheetFor(BuildContext context, RideStore store, RidePhase phase) {
    switch (phase) {
      case RidePhase.idle:
        return BookingSheet(mapController: _mapController);
      case RidePhase.searching:
        return SearchingSheet(ride: store.activeRide!);
      case RidePhase.driverOnTheWay:
      case RidePhase.driverArrived:
        return RideTrackingSheet(ride: store.activeRide!);
      case RidePhase.inProgress:
        return RideTrackingSheet(ride: store.activeRide!);
      case RidePhase.rating:
        return RatingSheet(ride: store.activeRide!);
      case RidePhase.completed:
        return CompletedSheet(ride: store.activeRide!);
      case RidePhase.cancelled:
        return CancelledSheet(ride: store.activeRide!);
    }
  }
}

/// شارة علوية صغيرة (تبديل الوضع / اسم المستخدم).
class _TopChip extends StatelessWidget {
  const _TopChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: HSColors.brandDark),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10312D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
