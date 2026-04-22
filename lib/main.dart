import 'package:flutter/material.dart';
import 'package:ksl/view/account/login.dart';
import 'package:ksl/component/appColors.dart';

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
      home: const LoginPage(),
    );
  }
}
