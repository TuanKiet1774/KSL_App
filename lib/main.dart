import 'package:flutter/material.dart';
import 'package:ksl/view/account/login.dart';
import 'package:ksl/component/appColors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Tăng kích thước bộ nhớ đệm ảnh (150MB) để lưu trữ các tệp GIF nặng tốt hơn
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KSL App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
        scaffoldBackgroundColor: AppColors.backgroundCream,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
