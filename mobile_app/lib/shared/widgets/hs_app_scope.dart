import 'package:flutter/material.dart';

import '../state/ride_store.dart';

/// نطاق موروث يمرّر [RideStore] المشترك لأسفل شجرة الواجهة.
///
/// بديل مبسّط عن حزمة provider: أي ويدجت تستدعي [HSAppScope.of] تُبنى
/// من جديد عند كل notifyListeners من المتجر.
class HSAppScope extends InheritedNotifier<RideStore> {
  const HSAppScope({super.key, required RideStore store, required super.child})
      : super(notifier: store);

  /// أقرب متجر في الشجرة.
  static RideStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HSAppScope>();
    assert(scope != null, 'HSAppScope not found in widget tree');
    return scope!.notifier!;
  }
}
