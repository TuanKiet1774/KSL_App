import 'package:flutter/material.dart';
import 'package:ksl/view/home.dart';
import 'package:ksl/component/app_colors.dart';

void main() {
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
      home: const HomeView(),
    );
  }
}
