import 'package:flutter/material.dart';
import 'package:ksl/component/app_colors.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Trang Cài đặt', style: TextStyle(fontSize: 20, color: AppColors.primaryTeal)),
    );
  }
}
