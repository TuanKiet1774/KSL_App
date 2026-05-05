import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/view/home.dart';
import 'package:ksl/view/account/login.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  final String _fullText = "Simply, Your Voice";
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _textAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Chờ animation hoàn tất + thêm 1 khoảng nghỉ
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final isLoggedIn = await AuthController.isLoggedIn();
    
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          isLoggedIn ? const HomePage() : const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoAnimation,
              child: FadeTransition(
                opacity: _logoAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textAnimation,
              child: Text(
                _fullText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
