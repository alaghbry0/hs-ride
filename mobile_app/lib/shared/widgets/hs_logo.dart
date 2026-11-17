import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// شعار HS — دائرة متدرجة بحرفَي "HS" وأسلوب عصري.
class HSLogo extends StatelessWidget {
  const HSLogo({super.key, this.size = 64, this.dark = false});

  final double size;

  /// خلفية داكنة (شاشة البداية) — نص أبيض بدل الأخضر.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HSColors.brand, HSColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: HSColors.brand.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'HS',
          style: TextStyle(
            color: dark ? Colors.white : Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// اسم العلامة بجانب الشعار.
class HSBrandRow extends StatelessWidget {
  const HSBrandRow({super.key, this.dark = false, this.logoSize = 40});

  final bool dark;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HSLogo(size: logoSize, dark: dark),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HS للنقل البري',
              style: TextStyle(
                fontSize: logoSize * 0.38,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : const Color(0xFF10312D),
                height: 1.1,
              ),
            ),
            Text(
              'تنقّل أذكى داخل المملكة',
              style: TextStyle(
                fontSize: logoSize * 0.22,
                color: dark ? Colors.white60 : HSColors.subtleText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
