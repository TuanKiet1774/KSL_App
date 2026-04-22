import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';

class FavoriteView extends StatelessWidget {
  const FavoriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Trang Yêu thích', style: TextStyle(fontSize: 20, color: AppColors.primaryTeal)),
    );
  }
}
