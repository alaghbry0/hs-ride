import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/app_models.dart';
import '../../../../shared/state/ride_store.dart';
import '../../../../shared/widgets/hs_app_scope.dart';

/// لوحة تجهيز الطلب — اختيار نقطة الانطلاق والوجهة ثم فئة المركبة
/// مع السعر التقديري والمسافة، وزر تأكيد الطلب.
class BookingSheet extends StatelessWidget {
  const BookingSheet({super.key, this.mapController});

  final MapController? mapController;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    final estimates = store.origin != null && store.destination != null ? store.allEstimates : const <FareEstimate>[];

    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── حقلا الانطلاق والوجهة ────────────────────────────────
          Row(
            children: [
              const SizedBox(width: 10),
              Column(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: HSColors.brand, shape: BoxShape.circle)),
                  const SizedBox(height: 4),
                  Container(width: 2.5, height: 26, color: HSColors.brand.withValues(alpha: 0.4)),
                  const SizedBox(height: 4),
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF10312D), shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _PlaceField(
                      label: 'نقطة الانطلاق',
                      hint: 'من أين تنطلق؟',
                      place: store.origin,
                      excludeId: store.destination?.id,
                      onChanged: (p) {
                        store.setOrigin(p);
                        _fitMap();
                      },
                    ),
                    const SizedBox(height: 8),
                    _PlaceField(
                      label: 'الوجهة',
                      hint: 'إلى أين تذهب؟',
                      place: store.destination,
                      excludeId: store.origin?.id,
                      onChanged: (p) {
                        store.setDestination(p);
                        _fitMap();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── عروض فئات المركبات ──────────────────────────────────
          if (estimates.isNotEmpty) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: estimates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final e = estimates[i];
                  final selected = store.selectedClass == e.vehicleClass;
                  return _ClassCard(
                    estimate: e,
                    selected: selected,
                    onTap: () => store.selectClass(e.vehicleClass),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.route, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'المسافة: ${store.fareEstimate!.distanceKm.toStringAsFixed(1)} كم — المدة التقديرية: ${store.fareEstimate!.durationMin} دقيقة',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],

          // ── زر التأكيد ───────────────────────────────────────────
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: store.canRequest ? () => _confirm(context, store) : null,
            style: FilledButton.styleFrom(
              backgroundColor: HSColors.brand,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            icon: const Icon(Icons.check_circle),
            label: Text(store.canRequest
                ? 'تأكيد الطلب — ${store.fareEstimate!.total.toStringAsFixed(2)} ر.س'
                : 'اختر نقطة الانطلاق والوجهة'),
          ),
        ],
      ),
    );
  }

  void _fitMap() {
    final c = mapController;
    if (c == null) return;
    // يُحفظ للمستقبل عند إضافة auto-fit للخريطة على المسار.
  }

  void _confirm(BuildContext context, RideStore store) {
    store.requestRide();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلبك — نبحث الآن عن أقرب كابتن'),
        backgroundColor: HSColors.brandDark,
      ),
    );
  }
}

/// حقل اختيار موقع — يفتح BottomSheet للبحث والاختيار من المواقع.
class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.label,
    required this.hint,
    this.place,
    this.excludeId,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final Place? place;
  final String? excludeId;
  final ValueChanged<Place?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final selected = await showModalBottomSheet<Place>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PlacePickerSheet(excludeId: excludeId),
        );
        if (selected != null) onChanged(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: place?.name ?? hint,
          suffixIcon: const Icon(Icons.expand_more),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Text(
          place != null ? place!.name : hint,
          style: TextStyle(
            fontSize: 14,
            fontWeight: place != null ? FontWeight.w700 : FontWeight.w400,
            color: place != null ? const Color(0xFF10312D) : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// بطاقة فئة مركبة مع السعر التقديري.
class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.estimate, required this.selected, required this.onTap});

  final FareEstimate estimate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vc = estimate.vehicleClass;
    final icon = switch (vc) {
      VehicleClass.economy => Icons.directions_car,
      VehicleClass.family => Icons.airport_shuttle,
      VehicleClass.vip => Icons.stars,
    };
    final color = switch (vc) {
      VehicleClass.economy => HSColors.brand,
      VehicleClass.family => const Color(0xFF1565C0),
      VehicleClass.vip => HSColors.vip,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  vc.label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              vc.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Text(
              '${estimate.total.toStringAsFixed(2)} ر.س',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              '${estimate.distanceKm.toStringAsFixed(1)} كم • ${estimate.durationMin} د',
              style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    );
  }
}

/// لوحة اختيار الموقع (تُفتح من حقل الانطلاق/الوجهة).
class PlacePickerSheet extends StatelessWidget {
  const PlacePickerSheet({super.key, this.excludeId});

  final String? excludeId;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);
    final places = store.placesRepository.places
        .where((p) => p.id != excludeId)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 44, height: 4.5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن موقع…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: places.length,
                  itemBuilder: (context, i) {
                    final p = places[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HSColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_outlined, color: HSColors.brand),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      subtitle: Text('${p.category} • ${p.address}', style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
}

/// قاعدة موحدة للوحات السفلية — خلفية بيضاء بزوايا دائرية وظل.
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

/// لوحة اختيار الموقع مصدَّرة للاستخدام من اللوحات الأخرى.
class DestinationPickerSheet extends PlacePickerSheet {
  const DestinationPickerSheet({super.excludeId});
}
