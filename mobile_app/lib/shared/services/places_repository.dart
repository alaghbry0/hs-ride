import 'package:latlong2/latlong.dart';

import '../models/app_models.dart';

/// مواقع افتراضية حقيقية الإحداثيات في الرياض وجدة — بلا أي API.
///
/// الإحداثيات تقريبية لمعالم حقيقية معروفة، تكفي لخريطة OpenStreetMap
/// ولحساب المسافات بصيغة haversine داخل [FareCalculator].
class PlacesRepository {
  const PlacesRepository();

  /// مركز الخريطة الافتتاحي (وسط الرياض).
  LatLng get mapCenter => const LatLng(24.7136, 46.6753);

  /// مستوى التقريب الافتتاحي.
  double get initialZoom => 12.0;

  /// كل المواقع المتاحة للعرض على الخريطة والاختيار.
  List<Place> get places => [...riyadhPlaces, ...jeddahPlaces];

  /// مواقع الرياض.
  static const riyadhPlaces = <Place>[
    Place(
      id: 'ruh-1',
      name: 'برج المملكة',
      address: 'طريق الملك فهد، العليا',
      position: LatLng(24.7115, 46.6745),
      category: 'معالم',
    ),
    Place(
      id: 'ruh-2',
      name: 'مطار الملك خالد الدولي',
      address: 'طريق المطار، الرياض',
      position: LatLng(24.9576, 46.6988),
      category: 'مطارات',
    ),
    Place(
      id: 'ruh-3',
      name: 'جامعة الملك سعود',
      address: 'طريق الملك عبدالله، الدرعية',
      position: LatLng(24.7247, 46.6208),
      category: 'تعليم',
    ),
    Place(
      id: 'ruh-4',
      name: 'الدرعية التاريخية',
      address: 'حي الدرعية، الرياض',
      position: LatLng(24.7333, 46.5777),
      category: 'معالم',
    ),
    Place(
      id: 'ruh-5',
      name: 'مستشفى الملك فيصل التخصصي',
      address: 'طريق المكي الدهلوي، المحمدية',
      position: LatLng(24.6902, 46.7050),
      category: 'صحة',
    ),
    Place(
      id: 'ruh-6',
      name: 'بانوراما مول',
      address: 'طريق الملك عبدالله، الربوة',
      position: LatLng(24.7570, 46.6440),
      category: 'تسوق',
    ),
    Place(
      id: 'ruh-7',
      name: 'حي السفارات',
      address: 'طريق الملك فهد، العليا',
      position: LatLng(24.6980, 46.6280),
      category: 'معالم',
    ),
    Place(
      id: 'ruh-8',
      name: 'واجهة الرياض',
      address: 'حي السفارات، طريق الملك سلمان',
      position: LatLng(24.7640, 46.6220),
      category: 'معالم',
    ),
    Place(
      id: 'ruh-9',
      name: 'بوليفارد سيتي',
      address: 'طريق الأمير محمد بن سلمان، العليا',
      position: LatLng(24.7600, 46.6180),
      category: 'ترفيه',
    ),
    Place(
      id: 'ruh-10',
      name: 'قصر الحُكم',
      address: 'حي الديرة، الرياض',
      position: LatLng(24.6300, 46.7100),
      category: 'معالم',
    ),
    Place(
      id: 'ruh-11',
      name: 'مستشفى الملك خالد الجامعي',
      address: 'جامعة الملك سعود، الدرعية',
      position: LatLng(24.7180, 46.6150),
      category: 'صحة',
    ),
  ];

  /// مواقع جدة.
  static const jeddahPlaces = <Place>[
    Place(
      id: 'jed-1',
      name: 'نافورة الملك فهد',
      address: 'الكورنيش الشمالي، جدة',
      position: LatLng(21.5420, 39.1640),
      category: 'معالم',
    ),
    Place(
      id: 'jed-2',
      name: 'مطار الملك عبدالعزيز الدولي',
      address: 'طريق المطار، جدة',
      position: LatLng(21.6796, 39.1565),
      category: 'مطارات',
    ),
    Place(
      id: 'jed-3',
      name: 'البلد التاريخي',
      address: 'حي البلد، جدة',
      position: LatLng(21.4858, 39.1867),
      category: 'معالم',
    ),
    Place(
      id: 'jed-4',
      name: 'جامعة الملك عبدالعزيز',
      address: 'حي الحمراء، جدة',
      position: LatLng(21.4948, 39.1860),
      category: 'تعليم',
    ),
    Place(
      id: 'jed-5',
      name: 'مستشفى الملك عبدالعزيز',
      address: 'حي الرحاب، جدة',
      position: LatLng(21.5620, 39.1680),
      category: 'صحة',
    ),
    Place(
      id: 'jed-6',
      name: 'ريد سي مول',
      address: 'الكورنيش الشمالي، جدة',
      position: LatLng(21.6140, 39.1490),
      category: 'تسوق',
    ),
  ];

  /// بحث نصي بسيط بالاسم أو العنوان.
  List<Place> search(String query) {
    if (query.trim().isEmpty) return places;
    final q = query.trim();
    return places
        .where((p) => p.name.contains(q) || p.address.contains(q))
        .toList();
  }
}
