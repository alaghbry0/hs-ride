import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/app_models.dart';
import '../../../../shared/state/ride_store.dart';
import '../../../../shared/widgets/hs_app_scope.dart';

/// لوحة "جاري البحث عن كابتن" — مؤشر نبض + ملخص الطلب + إلغاء.
class SearchingSheet extends StatelessWidget {
  const SearchingSheet({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PulseDot(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جاري البحث عن كابتن…',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'طلبك #${ride.id} مُرسل — سيظهر فوراً لدى الكباتن المتاحين',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteSummary(ride: ride),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => HSAppScope.of(context).cancelRideByPassenger(),
            style: OutlinedButton.styleFrom(
              foregroundColor: HSColors.danger,
              side: const BorderSide(color: HSColors.danger),
            ),
            icon: const Icon(Icons.close),
            label: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
  }
}

/// لوحة تتبع الرحلة النشطة — الكابتن في الطريق / وصل / الرحلة بدأت.
class RideTrackingSheet extends StatelessWidget {
  const RideTrackingSheet({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    final captain = ride.captain;
    final phase = ride.status;

    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // مؤشر المراحل الأربع.
          _PhaseStepper(phase: phase),
          const SizedBox(height: 16),

          // بطاقة الكابتن.
          if (captain != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: HSColors.brand,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          captain.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                        ),
                        Text(
                          '${captain.vehicle} • ${captain.plateNumber}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${captain.rating} (${captain.totalTrips} رحلة)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.phone_outlined),
                        color: HSColors.brandDark,
                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _RouteSummary(ride: ride),
          const SizedBox(height: 16),

          // شريط الحالة والتقدم حسب المرحلة.
          _statusBanner(phase, ride),
          if (phase == RidePhase.driverArrived) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
              icon: const Icon(Icons.door_front_door_outlined),
              label: const Text('الكابتن ينتظرك — تفضّل بالركوب'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(RidePhase phase, Ride ride) {
    switch (phase) {
      case RidePhase.driverOnTheWay:
        return const _StatusTile(
          icon: Icons.directions_car,
          color: HSColors.brand,
          title: 'الكابتن في الطريق إليك',
          subtitle: 'تصله خلال دقائق — تابع تحركه على الخريطة',
        );
      case RidePhase.driverArrived:
        return const _StatusTile(
          icon: Icons.where_to_vote,
          color: HSColors.success,
          title: 'وصل الكابتن',
          subtitle: 'الكابتن بانتظارك في نقطة الانطلاق',
        );
      case RidePhase.inProgress:
        return const _StatusTile(
          icon: Icons.route,
          color: Color(0xFF1565C0),
          title: 'الرحلة بدأت',
          subtitle: 'في الطريق إلى وجهتك — نتمنى لك رحلة سعيدة',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// لوحة التقييم — نجوم + تعليق اختياري بعد الوصول.
class RatingSheet extends StatelessWidget {
  const RatingSheet({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'وصلت إلى وجهتك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'كيف كانت تجربتك مع ${ride.captain?.name ?? 'الكابتن'}؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          const _StarRating(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'الأجرة النهائية', value: '${ride.fare.toStringAsFixed(2)} ر.س', bold: true),
                const SizedBox(height: 6),
                _SummaryRow(label: 'المسافة', value: '${ride.distanceKm.toStringAsFixed(1)} كم'),
                const SizedBox(height: 6),
                _SummaryRow(label: 'المدة', value: '${ride.durationMin} دقيقة'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => store.rateRide(5),
            style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
            child: const Text('إرسال التقييم'),
          ),
        ],
      ),
    );
  }
}

/// لوحة الرحلة المكتملة.
class CompletedSheet extends StatelessWidget {
  const CompletedSheet({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HSColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: HSColors.success, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'انتهت الرحلة بنجاح — شكراً لاستخدامك HS للنقل البري',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (ride.rating != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('تقييمك: ', style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5)),
                ...List.generate(5, (i) {
                  return Icon(
                    i < ride.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ],
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => store.resetRide(),
            style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
            child: const Text('طلب رحلة جديدة'),
          ),
        ],
      ),
    );
  }
}

/// لوحة الرحلة الملغاة.
class CancelledSheet extends StatelessWidget {
  const CancelledSheet({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HSColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel, color: HSColors.danger, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ride.cancellationReason ?? 'أُلغيت الرحلة',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => store.resetRide(),
            style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
            child: const Text('طلب رحلة جديدة'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// عناصر مساعدة
// ─────────────────────────────────────────────────────────────────────────

/// نقطة نابضة (مؤشر البحث).
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 18 + _controller.value * 10,
          height: 18 + _controller.value * 10,
          decoration: BoxDecoration(
            color: HSColors.brand.withValues(alpha: 0.9 - _controller.value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// شريط مراحل الرحلة (بحث → في الطريق → بدأت → وصول).
class _PhaseStepper extends StatelessWidget {
  const _PhaseStepper({required this.phase});

  final RidePhase phase;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('بحث', Icons.search),
      ('في الطريق', Icons.directions_car),
      ('بدأت', Icons.play_arrow),
      ('وصول', Icons.flag),
    ];
    int active;
    switch (phase) {
      case RidePhase.searching:
        active = 0;
      case RidePhase.driverOnTheWay:
        active = 1;
      case RidePhase.driverArrived:
        active = 1;
      case RidePhase.inProgress:
        active = 2;
      case RidePhase.rating:
      case RidePhase.completed:
        active = 3;
      default:
        active = 0;
    }

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
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
                  size: 17,
                  color: i <= active ? (i == active ? HSColors.brand : Colors.white) : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[i].$1,
                style: TextStyle(
                  fontSize: 11,
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

/// ملخص المسار (انطلاق → وجهة + السعر).
class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.trip_origin, size: 14, color: HSColors.brand),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              ride.origin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          const Icon(Icons.location_on, size: 14, color: Color(0xFF10312D)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              ride.destination.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${ride.fare.toStringAsFixed(2)} ر.س',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: HSColors.brandDark),
          ),
        ],
      ),
    );
  }
}

/// بلاطة حالة ملوّنة.
class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صف ملخص (تسمية/قيمة).
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? HSColors.brandDark : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// نجوم تفاعلية للتقييم.
class _StarRating extends StatefulWidget {
  const _StarRating();

  @override
  State<_StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<_StarRating> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return IconButton(
          iconSize: 38,
          onPressed: () {
            setState(() => _rating = starValue);
            store.rateRide(starValue);
          },
          icon: Icon(
            starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: starValue <= _rating ? Colors.amber : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}

/// قاعدة موحدة للوحات السفلية.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
