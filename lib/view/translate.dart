import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';

class TranslateView extends StatelessWidget {
  const TranslateView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Trang Dịch thuật', style: TextStyle(fontSize: 20, color: AppColors.primaryTeal)),
    );
  }
}
