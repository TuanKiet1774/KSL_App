import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/component/avatar.dart';
import 'package:ksl/connectDB/imgBB.dart';
import 'package:ksl/component/messDialog.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/user.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullnameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _avatarController;
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullnameController = TextEditingController(text: widget.user.fullname);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
    _avatarController = TextEditingController(text: widget.user.avatar);
    _selectedGender = widget.user.gender;
    if (widget.user.birthday.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.user.birthday);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPickOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Máy ảnh',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    _buildPickOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Thư viện',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    final String? uploadedUrl = await ImgBBService.uploadImage(File(image.path));

    if (mounted) {
      setState(() {
        _isUploading = false;
        if (uploadedUrl != null) {
          _avatarController.text = uploadedUrl;
          MessDialog.showSuccessDialog(
            context,
            'Thành công',
            'Tải ảnh lên thành công!',
          );
        } else {
          MessDialog.showErrorDialog(
            context,
            'Lỗi',
            'Không thể tải ảnh lên ImgBB. Vui lòng thử lại.',
          );
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AuthController.updateProfile(
      fullname: _fullnameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender,
      birthday: _selectedDate?.toIso8601String(),
      address: _addressController.text.trim(),
      avatar: _avatarController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        MessDialog.showSuccessDialog(
          context,
          'Thành công',
          'Cập nhật thông tin thành công!',
          onConfirm: () {
            Navigator.pop(context, true);
          },
        );
      } else {
        MessDialog.showErrorDialog(
          context,
          'Lỗi',
          result['message'] ?? 'Có lỗi xảy ra',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatarPicker(),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Link ảnh đại diện'),
                  _buildTextField(
                    controller: _avatarController,
                    hintText: 'Nhập link ảnh hoặc tải lên bằng nút máy ảnh',
                    icon: Icons.link_rounded,
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Họ và tên'),
                  _buildTextField(
                    controller: _fullnameController,
                    hintText: 'Nhập họ và tên',
                    icon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập họ và tên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Số điện thoại'),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Nhập số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Giới tính'),
                  _buildGenderRadioButtons(),
                  const SizedBox(height: 20),
                  _buildInputLabel('Ngày sinh'),
                  _buildDatePicker(),
                  const SizedBox(height: 20),
                  _buildInputLabel('Địa chỉ'),
                  _buildTextField(
                    controller: _addressController,
                    hintText: 'Nhập địa chỉ',
                    icon: Icons.location_on_outlined,
                    maxLines: 1,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.primaryBlue, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: UserAvatar(
            imageUrl: _avatarController.text,
            fullname: _fullnameController.text.isEmpty ? 'K' : _fullnameController.text,
            radius: 60,
            fontSize: 40,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRadioButtons() {
    return Row(
      children: [
        Expanded(child: _buildRadioItem('Nam', Icons.male_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildRadioItem('Nữ', Icons.female_rounded)),
      ],
    );
  }

  Widget _buildRadioItem(String value, IconData icon) {
    bool isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryTeal : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.primaryTeal, size: 22),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null ? 'Chọn ngày sinh' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey.shade400 : AppColors.primaryBlue,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_month_rounded, color: AppColors.primaryTeal, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
