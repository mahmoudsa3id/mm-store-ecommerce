import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class ContentFieldSpec {
  const ContentFieldSpec(
    this.key,
    this.label, {
    this.multiline = false,
    this.image = false,
  });

  final String key;
  final String label;
  final bool multiline;
  final bool image;
}

class ContentEditCard extends StatelessWidget {
  const ContentEditCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.edit_rounded),
        onTap: onTap,
      ),
    );
  }
}

class ContentManageList extends StatelessWidget {
  const ContentManageList({
    super.key,
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  final VoidCallback? onAdd;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          title: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          trailing: onAdd == null
              ? null
              : FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة'),
                ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد بيانات حاليًا',
                    style: TextStyle(color: AppConstants.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          titleOf(item),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(subtitleOf(item)),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: () => onEdit(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: () => onDelete(item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFB42318),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
