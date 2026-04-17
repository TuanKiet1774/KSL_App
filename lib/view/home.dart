import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksl/component/app_colors.dart';
import 'package:ksl/component/navigation.dart';
import 'package:ksl/view/favorite.dart';
import 'package:ksl/view/translate.dart';
import 'package:ksl/view/settings.dart';
import 'package:ksl/view/infomation.dart';

import 'package:ksl/component/confirmDialog.dart';
import 'package:ksl/component/user_avatar.dart';
import 'package:ksl/model/user.dart';
import 'package:ksl/controller/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? _user;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthController.getSavedUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeMainContent(user: _user),
      const FavoriteView(),
      const TranslateView(),
      const SettingsView(),
    ];
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }

        // Hiện modal ngay lập tức và luôn chặn phím Back bằng cách trả về false
        ConfirmDialog.show(
          context,
          title: 'Xác nhận thoát',
          message: 'Bạn có chắc chắn muốn thoát ứng dụng không?',
          icon: Icons.exit_to_app_rounded,
          color: AppColors.primaryTeal,
          confirmText: 'Thoát',
          cancelText: 'Hủy',
          onConfirm: () => SystemNavigator.pop(),
        );
        
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundCream,
      bottomNavigationBar: KslNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0), // Lướt nhẹ từ phải sang
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: pages[_selectedIndex],
      ),
    ));
  }
}

class HomeMainContent extends StatelessWidget {
  final UserModel? user;
  const HomeMainContent({super.key, this.user});

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buổi sáng vui vẻ';
    } else if (hour < 18) {
      return 'Buổi trưa vui vẻ';
    } else {
      return 'Buổi tối vui vẻ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/Logo.png',
                    height: 50,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        UserAvatar(
                          imageUrl: user?.avatar,
                          fullname: user?.fullname ?? "K",
                          radius: 25,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        'Chào mừng bạn trở lại với KSL',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Stack(
                children: [
                  Container(
                    height: 450,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage('assets/SignLanguage.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.95),
                            AppColors.primaryBlue.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiếng nói của người Điếc\nNgôn ngữ ký hiệu là gì ?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InformationView()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Xem thêm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Categories Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Danh mục',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildCategoryButton(
                    title: 'Chủ đề',
                    assetPath: 'assets/ChuDe.png',
                    onTap: () {},
                  ),
                  const SizedBox(width: 15),
                  _buildCategoryButton(
                    title: 'Bài thi',
                    assetPath: 'assets/BaiThi.png',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required String title,
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset(
                assetPath,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.category_rounded, size: 60, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
