import 'package:flutter/material.dart';

class LazyLoadingList extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final ScrollController? controller;

  const LazyLoadingList({
    super.key,
    required this.child,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
    this.controller,
  });

  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Một widget hiển thị trạng thái đang tải ở cuối danh sách
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A4D49)),
        ),
      ),
    );
  }
}
