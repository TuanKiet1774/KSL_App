import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';

class KSLResourceLoading extends StatelessWidget {
  final String message;
  const KSLResourceLoading({super.key, this.message = 'Đang tải dữ liệu...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    backgroundColor: Color(0xFFE0F2F1),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KSLLoadingOverlay extends StatelessWidget {
  final String message;
  const KSLLoadingOverlay({super.key, this.message = 'Vui lòng đợi...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: KSLResourceLoading(message: message),
    );
  }
}
