import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotepadTab extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const NotepadTab({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Write freely here...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: AppColors.deepSlateNavy,
        ),
        onChanged: onChanged,
      ),
    );
  }
}