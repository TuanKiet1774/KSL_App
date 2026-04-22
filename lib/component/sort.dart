import 'package:flutter/material.dart';

enum SortOrder { none, ascending, descending }

class SortAlphabetical extends StatelessWidget {
  final SortOrder currentOrder;
  final Function(SortOrder) onSortChanged;
  final Color? iconColor;

  const SortAlphabetical({
    super.key,
    required this.currentOrder,
    required this.onSortChanged,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      icon: Icon(
        _getIcon(),
        color: iconColor,
      ),
      tooltip: 'Sắp xếp theo tên',
      onSelected: onSortChanged,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOrder>>[
        // const PopupMenuItem<SortOrder>(
        //   value: SortOrder.none,
        //   child: Row(
        //     children: [
        //       Icon(Icons.sort_rounded, color: Colors.grey),
        //       SizedBox(width: 12),
        //       Text('Mặc định (Server)'),
        //     ],
        //   ),
        // ),
        const PopupMenuItem<SortOrder>(
          value: SortOrder.ascending,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded, color: Colors.blue),
              SizedBox(width: 12),
              Text('Tên (A-Z)'),
            ],
          ),
        ),
        const PopupMenuItem<SortOrder>(
          value: SortOrder.descending,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Tên (Z-A)'),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (currentOrder) {
      case SortOrder.ascending:
        return Icons.arrow_upward_rounded;
      case SortOrder.descending:
        return Icons.arrow_downward_rounded;
      case SortOrder.none:
      default:
        return Icons.sort_by_alpha_rounded;
    }
  }
}
