import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/state/ride_store.dart';
import '../../../shared/widgets/hs_app_scope.dart';
import '../../../shared/widgets/hs_logo.dart';

/// شاشة تسجيل دخول/تسجيل سائق جديد — الاسم، الجوال، نوع المركبة، اللوحة.
///
/// النموذج أولي بالكامل (بلا خادم): عند الحفظ يُنشأ [DriverProfile] في
/// المتجر المشترك وينتقل السائق مباشرة إلى لوحة التحكم.
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key, this.onSwitchRole});

  final VoidCallback? onSwitchRole;

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _vehicleType = 'تويوتا كامري';
  bool _acceptedTerms = false;

  static const _vehicleTypes = [
    'تويوتا كامري',
    'تويوتا هايلكس',
    'هيونداي إلنترا',
    'شيفروليه ماليبو',
    'تويوتا هاييس (عائلي)',
    'مرسيدس E200 (VIP)',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // ── الترويسة ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onSwitchRole,
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'تبديل الوضع',
                  ),
                  const HSBrandRow(logoSize: 38),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3EBE9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'انضم ككابتن في HS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'سجّل بياناتك وابدأ باستقبال طلبات الركاب والربح اليومي',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6),
                    ),
                    const SizedBox(height: 20),

                    // ── الحقول ──────────────────────────────────────
                    _Field(
                      controller: _nameCtrl,
                      label: 'الاسم الكامل',
                      hint: 'مثال: خالد الحربي',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().length < 3) ? 'أدخل اسماً صحيحاً (3 أحرف فأكثر)' : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _phoneCtrl,
                      label: 'رقم الجوال',
                      hint: '05XXXXXXXX',
                      icon: Icons.phone_android_outlined,
                      keyboard: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: _decoration('نوع المركبة', Icons.directions_car_outlined),
                      items: _vehicleTypes
                          .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _vehicleType = v!),
                      validator: (v) => (v == null || v.isEmpty) ? 'اختر نوع المركبة' : null,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _plateCtrl,
                      label: 'رقم اللوحة',
                      hint: 'مثال: أ ب ج 1234',
                      icon: Icons.pin_outlined,
                      validator: (v) => (v == null || v.trim().length < 4) ? 'أدخل رقم لوحة صحيحاً' : null,
                    ),
                    const SizedBox(height: 10),

                    // ── الشروط ──────────────────────────────────────
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                            activeColor: HSColors.brand,
                          ),
                          Expanded(
                            child: Text(
                              'أوافق على شروط الاستخدام وسياسة الخصوصية الخاصة بمنصة HS للنقل البري',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: (!_acceptedTerms) ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: HSColors.brand),
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('إنشاء حساب الكابتن'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'التسجيل تجريبي — البيانات تُحفظ محلياً داخل الجلسة الحالية فقط',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'أدخل رقم الجوال';
    if (!RegExp(r'^05\d{8}$').hasMatch(v)) return 'الرقم يجب أن يبدأ بـ 05 ويتكون من 10 أرقام';
    return null;
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    HSAppScope.of(context).registerDriver(
      DriverProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        vehicleType: _vehicleType,
        plateNumber: _plateCtrl.text.trim(),
        joinedAt: DateTime.now(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('مرحباً ${_nameCtrl.text.trim()} — حسابك جاهز!'),
        backgroundColor: HSColors.brandDark,
      ),
    );
  }
}

/// حقل نموذج موحد.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboard,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
