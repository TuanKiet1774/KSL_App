import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/view/splash.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/controller/progressController.dart';
import 'package:ksl/component/navigator_key.dart';
import 'package:ksl/provider/authProvider.dart';
import 'package:ksl/provider/topicProvider.dart';
import 'package:ksl/provider/wordProvider.dart';
import 'package:ksl/provider/examProvider.dart';
import 'package:ksl/provider/favoriteWordProvider.dart';
import 'package:ksl/provider/learnedWordProvider.dart';
import 'package:ksl/provider/progressProvider.dart';
import 'package:ksl/provider/feedbackProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 150;
  
  // Kiểm tra đăng nhập và bắt đầu session ngay từ đầu nếu đã login
  final isLoggedIn = await AuthController.isLoggedIn();
  if (isLoggedIn) {
    ProgressController.startSession();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedUser()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteWordProvider()),
        ChangeNotifierProvider(create: (_) => LearnedWordProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          // Kiểm tra session còn hiệu lực hay không (đăng nhập ở thiết bị khác?)
          AuthController.checkSessionValidity();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'KSL App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryTeal),
        scaffoldBackgroundColor: AppColors.backgroundCream,
        useMaterial3: true,
      ),
      home: const SplashView(),
    );
  }
}
