import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/state/ride_store.dart';
import '../../../shared/widgets/hs_app_scope.dart';
import '../../../shared/widgets/hs_logo.dart';
import '../../passenger/widgets/ride_map.dart';

/// لوحة تحكم السائق (الكابتن) — أربعة أوضاع عرض:
///
/// 1. غير متاح: بطاقة تفعيل "ابدأ العمل".
/// 2. متاح بلا طلب: خريطة + زر تعليق الاستقبال + ملخص أرباح اليوم.
/// 3. طلب وارد: بطاقة تفاعلية (موقع الراكب، الوجهة، السعر) قبول/رفض.
/// 4. رحلة نشطة: التوجه للعميل → بدء → إنهاء وتحصيل + الأرباح اليومية.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key, required this.store, this.onSwitchRole});

  final RideStore store;
  final VoidCallback? onSwitchRole;

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
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
          final isOnline = store.driverStatus == DriverStatus.online;
          final pending = store.pendingRequest;
          final activeManaged = store.driverActiveRide;
          final profile = store.driverProfile!;

          return Stack(
            children: [
              // ── الخريطة ─────────────────────────────────────────────
              RideMap(
                controller: _mapController,
                center: ride?.origin.position ?? store.placesRepository.mapCenter,
                zoom: store.placesRepository.initialZoom,
                origin: pending?.origin.position ?? activeManaged?.origin.position,
                destination: pending?.destination.position ?? activeManaged?.destination.position,
                showRoute: (pending ?? activeManaged) != null,
                driverPosition: activeManaged != null
                    ? _driverPos(activeManaged)
                    : const LatLng(24.7247, 46.6600),
              ),

              // ── الشريط العلوي ──────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // زر التبديل للراكب.
                      _TopIconButton(
                        icon: Icons.swap_horiz,
                        tooltip: 'تبديل الوضع',
                        onTap: widget.onSwitchRole ?? () {},
                      ),
                      const SizedBox(width: 8),
                      // بطاقة حالة الكابتن.
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isOnline ? HSColors.success : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${profile.name} • ${isOnline ? 'متاح' : 'غير متاح'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TopIconButton(
                        icon: Icons.payments_outlined,
                        tooltip: 'أرباح اليوم',
                        onTap: () => _showEarningsSheet(context, store),
                      ),
                    ],
                  ),
                ),
              ),

              // ── المحتوى السفلي ──────────────────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomContent(context, store, isOnline, pending, activeManaged),
              ),
            ],
          );
        },
      ),
    );
  }

  LatLng _driverPos(Ride ride) {
    // موضع أيقونة الكابتن — قرب الانطلاق أثناء التوجه، وقرب الوجهة أثناء الرحلة.
    final o = ride.origin.position;
    final d = ride.destination.position;
    switch (ride.status) {
      case RidePhase.driverOnTheWay:
      case RidePhase.driverArrived:
        return LatLng(o.latitude + 0.006, o.longitude - 0.004);
      case RidePhase.inProgress:
        return LatLng((o.latitude + d.latitude) / 2, (o.longitude + d.longitude) / 2);
      default:
        return o;
    }
  }

  Widget _bottomContent(
    BuildContext context,
    RideStore store,
    bool isOnline,
    Ride? pending,
    Ride? activeManaged,
  ) {
    // 1) رحلة نشطة يديرها السائق — الأولوية القصوى.
    if (activeManaged != null) {
      return ActiveRideManagement(ride: activeManaged);
    }

    // 2) طلب وارد بانتظار القرار — يظهر فقط عندما يكون الكابتن متاحاً.
    if (pending != null && isOnline) {
      return IncomingRequestCard(ride: pending);
    }

    // 3) متاح بلا طلبات — زر تعليق الاستقبال.
    if (isOnline) {
      return _WaitingCard(store: store);
    }

    // 4) غير متاح — بطاقة بدء العمل.
    return _OfflineCard(store: store);
  }

  void _showEarningsSheet(BuildContext context, RideStore store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final trips = store.tripRecords;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'أرباح اليوم',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [HSColors.brand, HSColors.brandDark]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${store.todayEarnings.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${store.todayTripCount} رحلة مكتملة اليوم',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'لا رحلات بعد — فعّل استقبال الطلبات لتبدأ الربح',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  ...trips.map(
                    (t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: HSColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.passengerName} → ${t.destinationName}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  '${t.vehicleClass.label} • ${t.endedAt.hour}:${t.endedAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${t.fare.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: HSColors.brandDark),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// البطاقات السفلية للسائق
// ─────────────────────────────────────────────────────────────────────────

/// بطاقة "غير متاح" — زر بدء العمل.
class _OfflineCard extends StatelessWidget {
  const _OfflineCard({required this.store});

  final RideStore store;

  @override
  Widget build(BuildContext context) {
    return _DriverSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.power_settings_new, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text('أنت خارج الخدمة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'فعّل زر المتاح لاستقبال طلبات الركاب القريبة',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => store.setDriverStatus(DriverStatus.online),
              style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
              icon: const Icon(Icons.toggle_on_outlined),
              label: const Text('التوفر لاستقبال الطلبات'),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة "متاح بانتظار طلبات".
class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.store});

  final RideStore store;

  @override
  Widget build(BuildContext context) {
    return _DriverSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HSColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.wifi_tethering, color: HSColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('متاح لاستقبال الطلبات', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    Text('أنت ظاهر للركاب في محيط المدينة', style: TextStyle(fontSize: 12.5, color: Color(0xFF616161))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.setDriverStatus(DriverStatus.offline),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade300)),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('إيقاف مؤقت'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text('${store.todayEarnings.toStringAsFixed(0)} ر.س اليوم'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة الطلب الوارد — موقع الراكب والوجهة والسعر + قبول/رفض.
class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);

    return _DriverSheet(
      highlight: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.deepOrange, size: 26),
              const SizedBox(width: 10),
              const Text(
                'طلب جديد!',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.vehicleClass.label,
                  style: const TextStyle(fontSize: 11.5, color: Colors.deepOrange, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RequestRoute(ride: ride),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPill(icon: Icons.social_distance, label: '${ride.distanceKm.toStringAsFixed(1)} كم'),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.schedule, label: '${ride.durationMin} دقيقة'),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.airline_seat_recline_normal, label: '${ride.vehicleClass.seats} مقاعد'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.rejectRequest(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HSColors.danger,
                    side: const BorderSide(color: HSColors.danger),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => store.acceptRequest(),
                  style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
                  icon: const Icon(Icons.check),
                  label: Text('قبول — ${ride.fare.toStringAsFixed(2)} ر.س'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// إدارة الرحلة النشطة (للسائق) — التوجه للعميل → بدء → إنهاء وتحصيل.
class ActiveRideManagement extends StatelessWidget {
  const ActiveRideManagement({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);

    return _DriverSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DriverPhaseStepper(phase: ride.status),
          const SizedBox(height: 14),
          _RequestRoute(ride: ride),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPill(icon: Icons.person, label: ride.passengerName),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.payments_outlined, label: '${ride.fare.toStringAsFixed(2)} ر.س'),
            ],
          ),
          const SizedBox(height: 14),
          switch (ride.status) {
            RidePhase.driverOnTheWay => FilledButton.icon(
                onPressed: () => store.markDriverArrived(),
                style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
                icon: const Icon(Icons.where_to_vote_outlined),
                label: const Text('وصلت إلى العميل'),
              ),
            RidePhase.driverArrived => FilledButton.icon(
                onPressed: () => store.startRide(),
                style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
                icon: const Icon(Icons.play_arrow),
                label: const Text('بدء الرحلة'),
              ),
            RidePhase.inProgress => FilledButton.icon(
                onPressed: () => store.endRide(),
                style: FilledButton.styleFrom(backgroundColor: HSColors.success),
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text('إنهاء الرحلة وتحصيل ${ride.fare.toStringAsFixed(2)} ر.س'),
              ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// عناصر مساعدة
// ─────────────────────────────────────────────────────────────────────────

/// شريط مراحل السائق (توجه → وصل → رحلة → تحصيل).
class _DriverPhaseStepper extends StatelessWidget {
  const _DriverPhaseStepper({required this.phase});

  final RidePhase phase;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('توجهت للعميل', Icons.directions_car),
      ('وصلت للعميل', Icons.where_to_vote),
      ('الرحلة جارية', Icons.play_arrow),
      ('تحصيل الأجرة', Icons.payments),
    ];
    final active = switch (phase) {
      RidePhase.driverOnTheWay => 0,
      RidePhase.driverArrived => 1,
      RidePhase.inProgress => 2,
      _ => 0,
    };

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: i <= active ? HSColors.brand : Colors.grey.shade300,
              ),
            ),
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: i < active
                      ? HSColors.brand
                      : i == active
                          ? HSColors.brand.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: i == active ? Border.all(color: HSColors.brand, width: 2) : null,
                ),
                child: Icon(
                  steps[i].$2,
                  size: 15,
                  color: i <= active ? (i == active ? HSColors.brand : Colors.white) : Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                steps[i].$1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: i == active ? FontWeight.w800 : FontWeight.w500,
                  color: i <= active ? HSColors.brandDark : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// ملخص مسار الطلب (للسائق).
class _RequestRoute extends StatelessWidget {
  const _RequestRoute({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle, size: 18, color: HSColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.origin.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(width: 2, height: 10, color: Colors.grey.shade400),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF10312D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.destination.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شارة معلومات صغيرة.
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HSColors.brandDark),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// زر أيقونة علوية.
class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
          child: Tooltip(message: tooltip, child: Icon(icon, size: 22, color: HSColors.brandDark)),
        ),
      ),
    );
  }
}

/// قاعدة بطاقات السائق السفلية.
class _DriverSheet extends StatelessWidget {
  const _DriverSheet({required this.child, this.highlight = false});

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: highlight ? Border.all(color: Colors.deepOrange, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
