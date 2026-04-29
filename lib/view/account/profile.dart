import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/user.dart';
import 'package:ksl/component/avatar.dart';
import 'package:ksl/view/account/editProfile.dart';
import 'package:ksl/component/messDialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fetchProfile();
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_person_rounded, color: Colors.white, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Xác minh danh tính',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vui lòng nhập mật khẩu để tiếp tục.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Mật khẩu',
                          filled: true,
                          fillColor: AppColors.backgroundCream.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isVerifying ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isVerifying
                                  ? null
                                  : () async {
                                      if (passwordController.text.isEmpty) return;
                                      setDialogState(() => isVerifying = true);
                                      
                                      final result = await AuthController.login(_user!.username, passwordController.text);
                                      
                                      if (mounted) {
                                        setDialogState(() => isVerifying = false);
                                        if (result['success'] == true) {
                                          Navigator.pop(context); 
                                          final editResult = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProfilePage(user: _user!),
                                            ),
                                          );
                                          if (editResult == true) {
                                            _fetchProfile();
                                          }
                                        } else {
                                          MessDialog.showErrorDialog(context, 'Lỗi xác minh', 'Mật khẩu không chính xác.');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isVerifying
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthController.getProfile();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _user = result['user'];
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Chưa cập nhật';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () {
              if (AuthController.userNotifier.value != null) {
                _showPasswordDialog();
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _errorMessage != null
              ? _buildErrorView()
              : ValueListenableBuilder<UserModel?>(
                  valueListenable: AuthController.userNotifier,
                  builder: (context, user, _) {
                    return MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: _buildProfileContent(user),
                    );
                  },
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchProfile,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserModel? user) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(user),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildInfoSection('Thông tin cơ bản', [
                  _infoItem(Icons.email_outlined, 'Email', user?.email),
                  _infoItem(Icons.phone_outlined, 'Số điện thoại', user?.phone),
                  _infoItem(Icons.wc_rounded, 'Giới tính', user?.gender),
                  _infoItem(Icons.cake_outlined, 'Ngày sinh', _formatDate(user?.birthday)),
                  _infoItem(Icons.location_on_outlined, 'Địa chỉ', user?.address),
                ]),
                const SizedBox(height: 24),
                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_reset_rounded, size: 20),
                    label: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    int currentStep = 1;
    final currentPasswordController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      currentStep == 1 ? Icons.lock_outline_rounded : currentStep == 2 ? Icons.person_search_rounded : Icons.vpn_key_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        currentStep == 1 ? 'Xác thực' : currentStep == 2 ? 'Thông tin tài khoản' : 'Đổi mật khẩu mới',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: currentStep / 3,
                        backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 160),
                        child: Column(
                          children: [
                            if (currentStep == 1) ...[
                              const Text('Nhập mật khẩu hiện tại để tiếp tục.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: currentPasswordController,
                                obscureText: true,
                                decoration: _buildDialogInputDecoration('Mật khẩu hiện tại', Icons.lock_rounded),
                              ),
                            ] else if (currentStep == 2) ...[
                              const Text('Xác nhận thông tin tài khoản của bạn.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: usernameController,
                                decoration: _buildDialogInputDecoration('Username', Icons.person_rounded),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                decoration: _buildDialogInputDecoration('Email', Icons.email_rounded),
                              ),
                            ] else ...[
                              const Text('Thiết lập mật khẩu mới cho tài khoản.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: newPasswordController,
                                obscureText: true,
                                decoration: _buildDialogInputDecoration('Mật khẩu mới', Icons.new_releases_rounded),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                decoration: _buildDialogInputDecoration('Xác nhận mật khẩu mới', Icons.check_circle_rounded),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (currentStep > 1) {
                                        setDialogState(() => currentStep--);
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                currentStep > 1 ? 'Quay lại' : 'Hủy',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (currentStep < 3) {
                                        if (currentStep == 1) {
                                          if (currentPasswordController.text.isEmpty) return;
                                          
                                          setDialogState(() => isLoading = true);
                                          final result = await AuthController.login(_user!.username, currentPasswordController.text);
                                          
                                          if (mounted) {
                                            setDialogState(() => isLoading = false);
                                            if (result['success'] == true) {
                                              setDialogState(() => currentStep++);
                                            } else {
                                              MessDialog.showErrorDialog(context, 'Lỗi xác minh', 'Mật khẩu hiện tại không chính xác.');
                                            }
                                          }
                                        } else if (currentStep == 2) {
                                          if (usernameController.text.isEmpty || emailController.text.isEmpty) return;
                                          
                                          if (usernameController.text.trim() != _user!.username || 
                                              emailController.text.trim() != _user!.email) {
                                            MessDialog.showErrorDialog(context, 'Thông tin không khớp', 'Username hoặc Email không chính xác.');
                                            return;
                                          }
                                          setDialogState(() => currentStep++);
                                        }
                                      } else {
                                        if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) return;
                                        if (newPasswordController.text != confirmPasswordController.text) {
                                          MessDialog.showErrorDialog(context, 'Lỗi', 'Mật khẩu không khớp.');
                                          return;
                                        }

                                        setDialogState(() => isLoading = true);
                                        final result = await AuthController.changePassword(
                                          currentPassword: currentPasswordController.text,
                                          username: usernameController.text.trim(),
                                          email: emailController.text.trim(),
                                          newPassword: newPasswordController.text,
                                        );

                                        if (mounted) {
                                          setDialogState(() => isLoading = false);
                                          if (result['success'] == true) {
                                            Navigator.pop(context);
                                            MessDialog.showSuccessDialog(context, 'Thành công', 'Mật khẩu đã được thay đổi.');
                                          } else {
                                            MessDialog.showErrorDialog(context, 'Lỗi', result['message'] ?? 'Thất bại.');
                                          }
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(currentStep < 3 ? 'Tiếp tục' : 'Hoàn tất', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildDialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.backgroundCream.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 20),
    );
  }

  Widget _buildHeader(UserModel? user) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 320, 
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        // Decorative Circles
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        // Profile Info
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 30), // Thêm padding top để đẩy avatar xuống
          child: Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: UserAvatar(
                  imageUrl: user?.avatar,
                  fullname: user?.fullname ?? 'K',
                  radius: 60,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullname ?? 'Người dùng KSL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user?.username ?? 'username'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryTeal.withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String? value) {
    bool isLast = false; // logic simplified for demo
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade50,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value == null || value.isEmpty ? 'Chưa cập nhật' : value,
                style: const TextStyle(color: AppColors.primaryBlue, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
