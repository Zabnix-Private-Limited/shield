import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSearchBar extends StatefulWidget {
  const AdminSearchBar({
    super.key,
    this.hintText = 'Search',
    this.value = '',
    this.onChanged,
    this.onClear,
  });

  final String hintText;
  final String value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AdminSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AdminColors.caption, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged == null
                  ? null
                  : (value) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 350),
                        () => widget.onChanged?.call(value.trim()),
                      );
                    },
              style: AdminTypography.small.copyWith(color: AdminColors.text),
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: AdminTypography.small.copyWith(
                  color: AdminColors.caption,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty && widget.onClear != null)
            IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                _debounce?.cancel();
                _controller.clear();
                widget.onClear?.call();
              },
              icon: const Icon(
                Icons.close,
                color: AdminColors.caption,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
