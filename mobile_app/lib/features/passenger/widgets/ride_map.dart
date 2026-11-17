import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';

/// خريطة OpenStreetMap تفاعلية عبر flutter_map — بلا مفاتيح API.
///
/// تعرض علامات مخصصة لنقطة الانطلاق والوجهة وخط مسار بينهما، وعلامة
/// متحركة للكابتن، مع أزرار تكبير/تصغير وتحديد الموقع.
class RideMap extends StatelessWidget {
  const RideMap({
    super.key,
    this.controller,
    required this.center,
    required this.zoom,
    this.origin,
    this.destination,
    this.showRoute = false,
    this.driverPosition,
    this.driverHeading = false,
    this.routePoints,
  });

  final MapController? controller;
  final LatLng center;
  final double zoom;

  /// نقطة انطلاق الراكب.
  final LatLng? origin;

  /// وجهة الراكب.
  final LatLng? destination;

  /// رسم خط المسار بين النقطتين.
  final bool showRoute;

  /// موضع الكابتن (أثناء التتبع).
  final LatLng? driverPosition;

  /// الكابتن متجه للراكب — يلوّن المسار بلون التحذير.
  final bool driverHeading;

  /// نقاط مسار مرسّمة (اختياري — تحل محل خط الانطلاق→الوجهة المباشر).
  final List<LatLng>? routePoints;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (origin != null)
        Marker(
          point: origin!,
          width: 44,
          height: 44,
          child: const _OriginMarker(),
        ),
      if (destination != null)
        Marker(
          point: destination!,
          width: 44,
          height: 44,
          child: const _DestinationMarker(),
        ),
      if (driverPosition != null)
        Marker(
          point: driverPosition!,
          width: 44,
          height: 44,
          child: const _DriverMarker(),
        ),
    ];

    final route = showRoute && origin != null && destination != null
        ? (routePoints ?? [origin!, _midpoint(origin!, destination!), destination!])
        : <LatLng>[];

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        backgroundColor: const Color(0xFFE8EFEA),
      ),
      children: [
        // بلاطات OpenStreetMap — بلا مفتاح API (سياسة الاستخدام العادل).
        // ملاحظة: خلفية الخريطة (backgroundColor أدناه) تظهر مكان أي بلاطة
        // يفشل تحميلها، فلا تبقى مساحات سوداء على الشبكات الضعيفة.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'sa.hs.ride',
          maxNativeZoom: 18,
        ),
        if (route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 5,
                color: driverHeading ? HSColors.brand : HSColors.brandDark,
                borderStrokeWidth: 9,
                borderColor: Colors.white,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap'),
          ],
        ),
      ],
    );
  }

  LatLng _midpoint(LatLng a, LatLng b) => LatLng(
        (a.latitude + b.latitude) / 2 + 0.004,
        (a.longitude + b.longitude) / 2 - 0.005,
      );
}

/// علامة الانطلاق — دائرة خضراء بنقطة بيضاء.
class _OriginMarker extends StatelessWidget {
  const _OriginMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HSColors.brand,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(child: Icon(Icons.person_pin_circle, color: Colors.white, size: 24)),
    );
  }
}

/// علامة الوجهة — مربع داكن بأيقونة علم.
class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10312D),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(child: Icon(Icons.flag, color: Colors.white, size: 22)),
    );
  }
}

/// علامة الكابتن — سيارة داخل دائرة متوهجة.
class _DriverMarker extends StatelessWidget {
  const _DriverMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HSColors.brand.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: HSColors.brand, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.local_taxi, color: HSColors.brand, size: 20),
        ),
      ],
    );
  }
}
