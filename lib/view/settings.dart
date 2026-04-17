import 'package:flutter/material.dart';
import 'package:ksl/component/app_colors.dart';
import 'package:ksl/controller/auth_controller.dart';
import 'package:ksl/model/user.dart';
import 'package:ksl/view/account/login.dart';
import 'package:ksl/component/confirmDialog.dart';
import 'package:ksl/view/profile.dart';
import 'package:ksl/component/user_avatar.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthController.getSavedUser();
    setState(() {
      _user = user;
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog before logout
    ConfirmDialog.show(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất không?',
      icon: Icons.logout_rounded,
      color: AppColors.primaryTeal,
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      onConfirm: () async {
        await AuthController.logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildMenuSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2), width: 2),
            ),
            child: UserAvatar(
              imageUrl: _user?.avatar,
              fullname: _user?.fullname ?? "K",
              radius: 60,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 16),
          // Fullname
          Text(
            _user?.fullname ?? 'Người dùng KSL',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          // Username
          Text(
            '@${_user?.username ?? 'username'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Level Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _user?.level ?? 'Beginner',
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) => _loadUserData()); // Làm mới dữ liệu khi quay lại
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.history_rounded,
            title: 'Lịch sử bài thi',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.book_outlined,
            title: 'Từ vựng đã học',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.bar_chart_rounded,
            title: 'Thống kê',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            color: Colors.red.shade600,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryTeal).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primaryTeal, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.primaryBlue,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey.shade400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}
