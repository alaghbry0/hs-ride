import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/driver/views/driver_home_screen.dart';
import 'features/driver/views/driver_login_screen.dart';
import 'features/passenger/views/passenger_home_screen.dart';
import 'features/role_selection/views/role_selection_screen.dart';
import 'shared/models/app_models.dart';
import 'shared/state/ride_store.dart';
import 'shared/widgets/hs_app_scope.dart';

/// هيكل التطبيق — يقرر الشاشة الحالية من وضع الاستخدام وحالة التسجيل:
///
/// - وضع الراكب → شاشة الراكب الرئيسية (الخريطة + الطلب + التتبع).
/// - وضع السائق:
///   - غير مسجل → شاشة تسجيل السائق.
///   - مسجل → لوحة تحكم السائق.
/// - شاشة اختيار الدور تُفتح كطبقة فوق الشاشة الحالية (بدون فقدانها).
class HSAppShell extends StatelessWidget {
  const HSAppShell({super.key, required this.store});

  final RideStore store;

  @override
  Widget build(BuildContext context) {
    return HSAppScope(
      store: store,
      child: MaterialApp(
        title: 'HS للنقل البري',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const _HomeSelector(),
      ),
    );
  }
}

/// يختار الشاشة الأولى حسب الدور وحالة تسجيل السائق، ويبقيها عند التبديل.
class _HomeSelector extends StatefulWidget {
  const _HomeSelector();

  @override
  State<_HomeSelector> createState() => _HomeSelectorState();
}

class _HomeSelectorState extends State<_HomeSelector> {
  /// عرض شاشة اختيار الدور كطبقة عرض فوق الشاشة الحالية.
  bool _showRoleSelection = true;

  @override
  Widget build(BuildContext context) {
    final store = HSAppScope.of(context);

    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              if (store.role == AppRole.passenger) {
                return PassengerHomeScreen(
                  onSwitchRole: () => setState(() => _showRoleSelection = true),
                );
              }
              if (!store.isDriverRegistered) {
                return DriverLoginScreen(
                  onSwitchRole: () => setState(() => _showRoleSelection = true),
                );
              }
              return DriverHomeScreen(
                store: store,
                onSwitchRole: () => setState(() => _showRoleSelection = true),
              );
            },
          ),
          // طبقة شاشة اختيار الدور — تُغلق عند الاختيار.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showRoleSelection
                ? RoleSelectionLayer(
                    onClose: () => setState(() => _showRoleSelection = false),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// غلاف شاشة اختيار الدور مع إغلاق عند الاختيار.
class RoleSelectionLayer extends StatelessWidget {
  const RoleSelectionLayer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return RoleSelectionScreen(onBack: onClose);
  }
}
