import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/premium_panel.dart';
import 'admin_content_cubit.dart';
import 'widgets/admin_content_widgets.dart';

class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AdminContentCubit>().load();
    });
  }

  // ============================================================
  // IMAGE UPLOAD
  // ============================================================

  Future<String?> _pickUpload() async {
    final repo = context.read<AdminContentCubit>().repo;

    final picked = await repo.uploads.pickImage();

    if (picked == null) return null;

    return repo.uploadPublicImage(picked);
  }

  // ============================================================
  // EDIT MAP
  // ============================================================

  Future<void> _editMap(
    String title,
    Map<String, dynamic> current,
    List<ContentFieldSpec> fields,
  ) async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        final controllers = <String, TextEditingController>{
          for (final field in fields)
            field.key: TextEditingController(
              text: '${current[field.key] ?? ''}',
            ),
        };

        return _MapEditDialog(
          title: title,
          fields: fields,
          controllers: controllers,
          onUpload: _pickUpload,
        );
      },
    );

    if (!mounted || values == null) return;

    try {
      await context.read<AdminContentCubit>().saveContent(
        title.toLowerCase(),
        values,
      );

      if (!mounted) return;

      _snack('تم الحفظ');
    } catch (error) {
      if (!mounted) return;

      _snack(error.toString(), error: true);
    }
  }

  // ============================================================
  // EDIT CATEGORY
  // ============================================================

  Future<void> _editCategory([Map<String, dynamic>? item]) async {
    final result = await showDialog<_CategoryResult>(
      context: context,
      builder: (dialogContext) {
        return _CategoryDialog(item: item, onUpload: _pickUpload);
      },
    );

    if (!mounted || result == null) return;

    try {
      await context.read<AdminContentCubit>().saveCategory(
        id: item?['id']?.toString(),
        name: result.name,
        imageUrl: result.image,
        sortOrder: int.tryParse(result.sort) ?? 0,
        isActive: result.active,
      );

      if (!mounted) return;

      _snack('تم حفظ القسم');
    } catch (error) {
      if (!mounted) return;

      _snack(error.toString(), error: true);
    }
  }

  // ============================================================
  // EDIT BANNER
  // ============================================================

  Future<void> _editBanner([Map<String, dynamic>? item]) async {
    final result = await showDialog<_BannerResult>(
      context: context,
      builder: (dialogContext) {
        return _BannerDialog(item: item, onUpload: _pickUpload);
      },
    );

    if (!mounted || result == null) return;

    try {
      await context.read<AdminContentCubit>().saveBanner(
        id: item?['id']?.toString(),
        imageUrl: result.image,
        title: result.title,
        buttonText: result.button,
        target: result.target,
        sortOrder: int.tryParse(result.sort) ?? 0,
        isActive: result.active,
      );

      if (!mounted) return;

      _snack('تم حفظ البانر');
    } catch (error) {
      if (!mounted) return;

      _snack(error.toString(), error: true);
    }
  }

  // ============================================================
  // EDIT SERVICE
  // ============================================================

  Future<void> _editService([Map<String, dynamic>? item]) async {
    final result = await showDialog<_ServiceResult>(
      context: context,
      builder: (dialogContext) {
        return _ServiceDialog(item: item);
      },
    );

    if (!mounted || result == null) return;

    try {
      await context.read<AdminContentCubit>().saveService(
        id: item?['id']?.toString(),
        title: result.title,
        subtitle: result.subtitle,
        icon: result.icon,
        sortOrder: int.tryParse(result.sort) ?? 0,
        isActive: result.active,
      );

      if (!mounted) return;

      _snack('تم حفظ الخدمة');
    } catch (error) {
      if (!mounted) return;

      _snack(error.toString(), error: true);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _delete(
    Map<String, dynamic> item,
    String label,
    Future<void> Function(String id) action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('حذف $label؟'),
          content: const Text('هذا الإجراء سيحذف العنصر من المتجر.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await action(item['id'].toString());

      if (!mounted) return;

      _snack('تم الحذف');
    } catch (error) {
      if (!mounted) return;

      _snack(error.toString(), error: true);
    }
  }

  // ============================================================
  // SNACK
  // ============================================================

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? const Color(0xFFB42318) : AppConstants.black,
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محتوى المتجر',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),

          BlocBuilder<AdminContentCubit, AdminContentState>(
            builder: (context, state) {
              if (state.loading &&
                  state.categories.isEmpty &&
                  state.banners.isEmpty &&
                  state.services.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'الهوية'),
                        Tab(text: 'الأقسام'),
                        Tab(text: 'البانرات'),
                        Tab(text: 'الخدمات'),
                      ],
                    ),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // ==================================================
                          // IDENTITY
                          // ==================================================
                          ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              PremiumPanel(
                                child: Column(
                                  children: [
                                    ContentEditCard(
                                      title: 'Hero',
                                      subtitle:
                                          'العنوان والوصف والصورة الرئيسية',
                                      onTap: () => _editMap(
                                        'Hero',
                                        state.hero,
                                        const [
                                          ContentFieldSpec('title', 'العنوان'),
                                          ContentFieldSpec('subtitle', 'الوصف'),
                                          ContentFieldSpec('button', 'نص الزر'),
                                          ContentFieldSpec(
                                            'image',
                                            'رابط الصورة',
                                            image: true,
                                          ),
                                        ],
                                      ),
                                    ),

                                    ContentEditCard(
                                      title: 'About',
                                      subtitle: 'قسم من نحن وصورته',
                                      onTap: () =>
                                          _editMap('About', state.about, const [
                                            ContentFieldSpec(
                                              'title',
                                              'العنوان',
                                            ),
                                            ContentFieldSpec(
                                              'description',
                                              'الوصف',
                                              multiline: true,
                                            ),
                                            ContentFieldSpec(
                                              'image_url',
                                              'رابط الصورة',
                                              image: true,
                                            ),
                                          ]),
                                    ),

                                    ContentEditCard(
                                      title: 'Socials',
                                      subtitle: 'روابط السوشيال ميديا',
                                      onTap: () => _editMap(
                                        'Socials',
                                        state.socials,
                                        const [
                                          ContentFieldSpec(
                                            'instagram',
                                            'Instagram',
                                          ),
                                          ContentFieldSpec(
                                            'facebook',
                                            'Facebook',
                                          ),
                                          ContentFieldSpec('tiktok', 'TikTok'),
                                          ContentFieldSpec(
                                            'telegram',
                                            'Telegram',
                                          ),
                                        ],
                                      ),
                                    ),

                                    ContentEditCard(
                                      title: 'Contact',
                                        subtitle: 'بيانات الهاتف والعنوان',
                                      onTap: () => _editMap(
                                        'Contact',
                                        state.contact,
                                        const [
                                          ContentFieldSpec('phone', 'الهاتف'),
                                          ContentFieldSpec(
                                            'address',
                                            'العنوان',
                                            multiline: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // ==================================================
                          // CATEGORIES
                          // ==================================================
                          ContentManageList(
                            title: 'الأقسام',
                            items: state.categories,
                            titleOf: (item) => '${item['name']}',
                            subtitleOf: (item) =>
                                'الترتيب ${item['sort_order'] ?? 0} • ${item['is_active'] == true ? 'نشط' : 'متوقف'}',
                            onAdd: () => _editCategory(),
                            onEdit: _editCategory,
                            onDelete: (item) => _delete(
                              item,
                              'القسم',
                              context.read<AdminContentCubit>().deleteCategory,
                            ),
                          ),

                          // ==================================================
                          // BANNERS
                          // ==================================================
                          ContentManageList(
                            title: 'البانرات',
                            items: state.banners,
                            titleOf: (item) => '${item['title']}',
                            subtitleOf: (item) =>
                                'الترتيب ${item['sort_order'] ?? 0} • ${item['is_active'] == true ? 'نشط' : 'متوقف'}',
                            onEdit: _editBanner,
                            onDelete: (item) => _delete(
                              item,
                              'البانر',
                              context.read<AdminContentCubit>().deleteBanner,
                            ),
                          ),

                          // ==================================================
                          // SERVICES
                          // ==================================================
                          ContentManageList(
                            title: 'الخدمات',
                            items: state.services,
                            titleOf: (item) => '${item['title']}',
                            subtitleOf: (item) => '${item['subtitle']}',
                            onEdit: _editService,
                            onDelete: (item) => _delete(
                              item,
                              'الخدمة',
                              context.read<AdminContentCubit>().deleteService,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MAP EDIT DIALOG
// ============================================================================

class _MapEditDialog extends StatefulWidget {
  const _MapEditDialog({
    required this.title,
    required this.fields,
    required this.controllers,
    required this.onUpload,
  });

  final String title;
  final List<ContentFieldSpec> fields;
  final Map<String, TextEditingController> controllers;
  final Future<String?> Function() onUpload;

  @override
  State<_MapEditDialog> createState() => _MapEditDialogState();
}

class _MapEditDialogState extends State<_MapEditDialog> {
  @override
  void dispose() {
    for (final controller in widget.controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل ${widget.title}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: widget.fields.map((field) {
              final controller = widget.controllers[field.key]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: field.multiline ? 3 : 1,
                        maxLines: field.multiline ? 6 : 1,
                        decoration: InputDecoration(labelText: field.label),
                      ),
                    ),

                    if (field.image) ...[
                      const SizedBox(width: 8),

                      IconButton.filledTonal(
                        tooltip: 'رفع صورة',
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          final url = await widget.onUpload();

                          if (!mounted) return;

                          if (url != null) {
                            controller.text = url;
                          }
                        },
                        icon: const Icon(Icons.cloud_upload_outlined),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),

        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            final values = <String, String>{
              for (final field in widget.fields)
                field.key: widget.controllers[field.key]!.text.trim(),
            };

            Navigator.of(context).pop(values);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ============================================================================
// CATEGORY DIALOG
// ============================================================================

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.item, required this.onUpload});

  final Map<String, dynamic>? item;
  final Future<String?> Function() onUpload;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController name;
  late final TextEditingController image;
  late final TextEditingController sort;

  bool active = true;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    name = TextEditingController(text: '${item?['name'] ?? ''}');

    image = TextEditingController(text: '${item?['image_url'] ?? ''}');

    sort = TextEditingController(text: '${item?['sort_order'] ?? 0}');

    active = item?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    name.dispose();
    image.dispose();
    sort.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'إضافة قسم' : 'تعديل القسم'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: image,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();

                      final url = await widget.onUpload();

                      if (!mounted) return;

                      if (url != null) {
                        image.text = url;
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الترتيب'),
              ),

              const SizedBox(height: 8),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (value) {
                  setState(() {
                    active = value;
                  });
                },
                title: const Text('ظاهر للعميل'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),

        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop(
              _CategoryResult(
                name: name.text.trim(),
                image: image.text.trim(),
                sort: sort.text.trim(),
                active: active,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ============================================================================
// BANNER DIALOG
// ============================================================================

class _BannerDialog extends StatefulWidget {
  const _BannerDialog({required this.item, required this.onUpload});

  final Map<String, dynamic>? item;
  final Future<String?> Function() onUpload;

  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  late final TextEditingController title;
  late final TextEditingController image;
  late final TextEditingController button;
  late final TextEditingController target;
  late final TextEditingController sort;

  bool active = true;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    title = TextEditingController(text: '${item?['title'] ?? ''}');

    image = TextEditingController(text: '${item?['image_url'] ?? ''}');

    button = TextEditingController(
      text: '${item?['button_text'] ?? 'تسوق الآن'}',
    );

    target = TextEditingController(text: '${item?['target'] ?? 'new'}');

    sort = TextEditingController(text: '${item?['sort_order'] ?? 0}');

    active = item?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    image.dispose();
    button.dispose();
    target.dispose();
    sort.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'إضافة بانر' : 'تعديل البانر'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: button,
                decoration: const InputDecoration(labelText: 'نص الزر'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: target,
                decoration: const InputDecoration(labelText: 'Target'),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: image,
                      decoration: const InputDecoration(
                        labelText: 'رابط الصورة',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();

                      final url = await widget.onUpload();

                      if (!mounted) return;

                      if (url != null) {
                        image.text = url;
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الترتيب'),
              ),

              const SizedBox(height: 8),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (value) {
                  setState(() {
                    active = value;
                  });
                },
                title: const Text('ظاهر للعميل'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),

        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop(
              _BannerResult(
                title: title.text.trim(),
                image: image.text.trim(),
                button: button.text.trim(),
                target: target.text.trim(),
                sort: sort.text.trim(),
                active: active,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ============================================================================
// SERVICE DIALOG
// ============================================================================

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({required this.item});

  final Map<String, dynamic>? item;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController title;
  late final TextEditingController subtitle;
  late final TextEditingController icon;
  late final TextEditingController sort;

  bool active = true;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    title = TextEditingController(text: '${item?['title'] ?? ''}');

    subtitle = TextEditingController(text: '${item?['subtitle'] ?? ''}');

    icon = TextEditingController(text: '${item?['icon'] ?? 'verified'}');

    sort = TextEditingController(text: '${item?['sort_order'] ?? 0}');

    active = item?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    icon.dispose();
    sort.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'إضافة خدمة' : 'تعديل الخدمة'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: subtitle,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: icon,
                decoration: const InputDecoration(labelText: 'اسم الأيقونة'),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: sort,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الترتيب'),
              ),

              const SizedBox(height: 8),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (value) {
                  setState(() {
                    active = value;
                  });
                },
                title: const Text('ظاهر للعميل'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop();
          },
          child: const Text('إلغاء'),
        ),

        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();

            Navigator.of(context).pop(
              _ServiceResult(
                title: title.text.trim(),
                subtitle: subtitle.text.trim(),
                icon: icon.text.trim(),
                sort: sort.text.trim(),
                active: active,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT CLASSES
// ============================================================================

class _CategoryResult {
  const _CategoryResult({
    required this.name,
    required this.image,
    required this.sort,
    required this.active,
  });

  final String name;
  final String image;
  final String sort;
  final bool active;
}

class _BannerResult {
  const _BannerResult({
    required this.title,
    required this.image,
    required this.button,
    required this.target,
    required this.sort,
    required this.active,
  });

  final String title;
  final String image;
  final String button;
  final String target;
  final String sort;
  final bool active;
}

class _ServiceResult {
  const _ServiceResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sort,
    required this.active,
  });

  final String title;
  final String subtitle;
  final String icon;
  final String sort;
  final bool active;
}
