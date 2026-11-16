import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/state/ride_store.dart';
import '../../../shared/widgets/hs_app_scope.dart';
import '../../../shared/widgets/hs_logo.dart';

/// شاشة البداية — التبديل السريع بين "وضع الراكب" و"وضع السائق"
/// لتجربة الدورتين داخل نفس التطبيق بدون خادم خارجي.
///
/// تعرض كذلك مؤشراً حياً بحالة الطلب المعلّق إن وُجد، ليدرك المستخدم أن
/// التبديل لوضع السائق سيُظهر الطلب لديه.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, this.onBack});

  /// رجوع اختياري — يظهر عند فتح الشاشة من داخل التطبيق (زر تبديل الوضع).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final store = HSAppScope.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HSColors.darkBg, Color(0xFF134E48)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                    ),
                  ),
                SizedBox(height: size.height * 0.05),
                const HSLogo(dark: true, size: 84),
                const SizedBox(height: 24),
                Text(
                  'أهلاً بك في HS للنقل البري',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تنقّل داخل مدن المملكة بأمان وراحة\nاختر وضعك للبدء',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const Spacer(),
                // مؤشر الطلب المعلّق — يظهر إن كان هناك طلب ينتظر كابتن.
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final pending = store.pendingRequest;
                    if (pending == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'لديك طلب رحلة معلّق (#${pending.id}) — التبديل لوضع السائق سيُظهره للقبول',
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _RoleCard(
                  icon: Icons.person,
                  title: 'وضع الراكب',
                  subtitle: 'اطلب رحلة وتتبعها لحظياً على الخريطة',
                  onTap: () {
                    store.switchRole(AppRole.passenger);
                    onBack?.call();
                  },
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.directions_car,
                  title: 'وضع السائق',
                  subtitle: 'سجّل واستقبل طلبات الركاب واكسب',
                  onTap: () {
                    store.switchRole(AppRole.driver);
                    onBack?.call();
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'بنسخة تجريبية — الأرقام والعروض تقديرية للعرض التوضيحي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: HSColors.brand.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
