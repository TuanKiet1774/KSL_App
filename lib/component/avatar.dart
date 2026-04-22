import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullname;
  final double radius;
  final double fontSize;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.fullname,
    this.radius = 30,
    this.fontSize = 20,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return "K";
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  Color _getBackgroundColor(String name) {
    final List<Color> colors = [
      const Color(0xFFFF4081), // Pink
      const Color(0xFF8BC34A), // Lime Green
      const Color(0xFF66BB6A), // Light Green
      const Color(0xFF81D4FA), // Light Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFFBA68C8), // Purple
    ];
    // Chọn màu dựa trên mã hash của tên để giữ màu cố định cho mỗi user
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: hasImage ? Colors.grey.shade200 : _getBackgroundColor(fullname),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: !hasImage
          ? Text(
              _getInitials(fullname),
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            )
          : null,
    );
  }
}
