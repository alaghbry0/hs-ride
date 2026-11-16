import 'package:flutter/material.dart';

import 'app.dart';
import 'shared/state/ride_store.dart';

void main() {
  runApp(const HSApp());
}

/// الجذر — يبني [HSApp] مع المتجر المشترك الوحيد لدورتي الراكب والسائق.
class HSApp extends StatelessWidget {
  const HSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return HSAppShell(store: _store);
      },
    );
  }
}

/// المتجر المشترك — singleton على مستوى العملية ليصمد عبر التبديل بين الوضعين.
final RideStore _store = RideStore();
