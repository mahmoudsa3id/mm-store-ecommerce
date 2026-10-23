import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class SizePresetPicker extends StatelessWidget {
  const SizePresetPicker({
    super.key,
    required this.mode,
    required this.selected,
    required this.onModeChanged,
    required this.onToggle,
  });

  final String mode;
  final List<String> selected;
  final Function(String)? onModeChanged;
  final Function(String)? onToggle;

  static const pants = <String>['30', '32', '34', '36', '38', '40', '42'];
  static const clothing = <String>['M', 'L', 'XL', '2XL', '3XL'];

  @override
  Widget build(BuildContext context) {
    final options = mode == 'pants' ? pants : clothing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع المقاسات',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'pants', label: Text('بنطلون')),
            ButtonSegment(value: 'clothing', label: Text('ملابس أخرى')),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onModeChanged!(value.first),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((size) {
                final isSelected = selected.contains(size);
                return FilterChip(
                  label: Text(size),
                  selected: isSelected,
                  selectedColor: AppConstants.gold.withValues(alpha: .18),
                  checkmarkColor: AppConstants.gold,
                  side: BorderSide(
                    color: isSelected ? AppConstants.gold : AppConstants.border,
                  ),
                  onSelected: (_) => onToggle!(size),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
