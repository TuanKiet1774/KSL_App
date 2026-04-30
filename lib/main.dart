import 'package:flutter/material.dart';
import 'package:ksl/view/account/login.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/controller/progressController.dart';
import 'package:ksl/view/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150;
  final isLoggedIn = await AuthController.isLoggedIn();
  if (isLoggedIn) {
    ProgressController.startSession();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final status = await AuthController.isLoggedIn();
    setState(() {
      _isLoggedIn = status;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App đi vào background hoặc bị đóng -> Lưu thời gian
      ProgressController.endSession();
    } else if (state == AppLifecycleState.resumed) {
      // App quay lại -> Bắt đầu phiên mới
      AuthController.isLoggedIn().then((isLoggedIn) {
        if (isLoggedIn) {
          ProgressController.startSession();
        }
      });
    }
  }

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
      home: _isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
