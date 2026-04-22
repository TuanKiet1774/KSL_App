import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';

class MessDialog {
  /// Hiển thị thông báo thành công
  static void showSuccessDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    _buildDialog(
      context,
      title,
      message,
      Icons.check_circle,
      Colors.green.shade600,
      onConfirm: onConfirm,
    );
  }

  /// Hiển thị thông báo lỗi
  static void showErrorDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    _buildDialog(
      context,
      title,
      message,
      Icons.error,
      Colors.red.shade600,
      onConfirm: onConfirm,
    );
  }

  /// Hiển thị thông báo thông tin chung
  static void showInfoDialog(BuildContext context, String title, String message, {VoidCallback? onConfirm}) {
    _buildDialog(
      context,
      title,
      message,
      Icons.info,
      Colors.blue.shade600,
      onConfirm: onConfirm,
    );
  }

  /// Lõi xây dựng giao diện chung cho Dialog modal
  static void _buildDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color, {
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Yêu cầu người dùng nhấn nút Đóng để thoát
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: _contentBox(context, title, message, icon, color, onConfirm),
        );
      },
    );
  }

  static Widget _contentBox(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
    VoidCallback? onConfirm,
  ) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            top: 60, // Chừa không gian cho icon đè lên trên
            right: 20,
            bottom: 20,
          ),
          margin: const EdgeInsets.only(top: 45), // Lệch xuống để chừa không gian cho icon
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content theo nội dung chữ
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Đóng",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: color,
            radius: 45,
            child: Icon(
              icon,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
