import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:mm_store/features/home/domain/entities/product_color_variant.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_upload.dart';

import 'color_picker_dialog.dart';
import 'size_preset_picker.dart';

class AdminProductFormResult {
  const AdminProductFormResult({
    required this.name,
    required this.description,
    required this.price,
    required this.oldPrice,
    required this.categoryId,
    required this.sizes,
    required this.sizeMode,
    required this.colorVariants,
    required this.colorVariantImages,
  });

  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String categoryId;

  final List<String> sizes;
  final String sizeMode;

  /// الألوان الموجودة بالفعل ومعها الصور المحفوظة.
  final List<ProductColorVariant> colorVariants;

  /// الصور الجديدة المختارة من الجهاز.
  final Map<String, PickedImageData> colorVariantImages;
}

class _AdminColorVariantDraft {
  const _AdminColorVariantDraft({
    required this.color,
    this.image,
    this.imageUrl = '',
  });

  final String color;

  /// صورة جديدة من الجهاز.
  final PickedImageData? image;

  /// الصورة الموجودة بالفعل في Storage.
  final String imageUrl;
}

class AdminProductFormDialog extends StatefulWidget {
  const AdminProductFormDialog({
    super.key,
    required this.categories,
    required this.pickImage,
    this.initial,
  });

  final List<Map<String, dynamic>> categories;

  final Future<PickedImageData?> Function() pickImage;

  final AdminProductFormResult? initial;

  static Future<AdminProductFormResult?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> categories,
    required Future<PickedImageData?> Function() pickImage,
    AdminProductFormResult? initial,
  }) {
    return showDialog<AdminProductFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AdminProductFormDialog(
          categories: categories,
          pickImage: pickImage,
          initial: initial,
        );
      },
    );
  }

  @override
  State<AdminProductFormDialog> createState() => _AdminProductFormDialogState();
}

class _AdminProductFormDialogState extends State<AdminProductFormDialog> {
  late final TextEditingController _nameController;

  late final TextEditingController _descriptionController;

  late final TextEditingController _priceController;

  late final TextEditingController _oldPriceController;

  late String? _categoryId;

  late String _sizeMode;

  late List<String> _sizes;

  late List<_AdminColorVariantDraft> _colorVariants;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initial;

    _nameController = TextEditingController(text: initial?.name ?? '');

    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );

    _priceController = TextEditingController(
      text: initial == null ? '' : initial.price.toStringAsFixed(0),
    );

    _oldPriceController = TextEditingController(
      text: initial?.oldPrice?.toStringAsFixed(0) ?? '',
    );

    _categoryId =
        initial?.categoryId ??
        (widget.categories.isEmpty
            ? null
            : widget.categories.first['id'].toString());

    _sizeMode = initial?.sizeMode ?? 'clothing';

    _sizes = [...initial?.sizes ?? const <String>[]];

    _colorVariants = [
      ...(initial?.colorVariants ?? const <ProductColorVariant>[]).map(
        (variant) => _AdminColorVariantDraft(
          color: variant.color,
          imageUrl: variant.imageUrl,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();

    super.dispose();
  }

  // ============================================================
  // COLOR PICKER
  // ============================================================

  Future<String?> _showColorPicker({String? initialColor}) async {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return ColorPickerDialog(initialHex: initialColor ?? '#000000');
      },
    );
  }

  // ============================================================
  // ADD COLOR
  // ============================================================

  Future<void> _addColor() async {
    final color = await _showColorPicker();

    if (color == null || !mounted) {
      return;
    }

    final normalized = color.toUpperCase();

    final exists = _colorVariants.any(
      (variant) => variant.color.toUpperCase() == normalized,
    );

    if (exists) {
      _message('اللون ده مضاف بالفعل.');

      return;
    }

    final image = await widget.pickImage();

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _colorVariants.add(
        _AdminColorVariantDraft(color: normalized, image: image),
      );
    });
  }

  // ============================================================
  // EDIT COLOR
  // ============================================================

  Future<void> _editColor(int index) async {
    if (index < 0 || index >= _colorVariants.length) {
      return;
    }

    final old = _colorVariants[index];

    final color = await _showColorPicker(initialColor: old.color);

    if (color == null || !mounted) {
      return;
    }

    final normalized = color.toUpperCase();

    final duplicate = _colorVariants.asMap().entries.any(
      (entry) =>
          entry.key != index && entry.value.color.toUpperCase() == normalized,
    );

    if (duplicate) {
      _message('اللون ده مضاف بالفعل.');

      return;
    }

    setState(() {
      _colorVariants[index] = _AdminColorVariantDraft(
        color: normalized,
        image: old.image,
        imageUrl: old.imageUrl,
      );
    });
  }

  // ============================================================
  // CHANGE COLOR IMAGE
  // ============================================================

  Future<void> _changeColorImage(int index) async {
    if (index < 0 || index >= _colorVariants.length) {
      return;
    }

    final image = await widget.pickImage();

    if (image == null || !mounted) {
      return;
    }

    final old = _colorVariants[index];

    setState(() {
      _colorVariants[index] = _AdminColorVariantDraft(
        color: old.color,
        image: image,
        imageUrl: old.imageUrl,
      );
    });
  }

  // ============================================================
  // DELETE COLOR
  // ============================================================

  void _deleteColor(int index) {
    if (index < 0 || index >= _colorVariants.length) {
      return;
    }

    setState(() {
      _colorVariants.removeAt(index);
    });
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  bool _categoryLooksLikePants(String? categoryId) {
    if (categoryId == null) {
      return false;
    }

    final matches = widget.categories.where(
      (item) => item['id']?.toString() == categoryId,
    );

    if (matches.isEmpty) {
      return false;
    }

    final name = matches.first['name']?.toString().toLowerCase() ?? '';

    return name.contains('بنطل') ||
        name.contains('pants') ||
        name.contains('jeans');
  }

  void _onCategoryChanged(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _categoryId = value;

      if (_categoryLooksLikePants(value)) {
        _sizeMode = 'pants';
      }
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    final description = _descriptionController.text.trim();

    final price = double.tryParse(_priceController.text.trim());

    final oldPriceText = _oldPriceController.text.trim();

    final oldPrice = oldPriceText.isEmpty
        ? null
        : double.tryParse(oldPriceText);

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (name.length < 2 || price == null || price < 0 || _categoryId == null) {
      _message('راجع اسم المنتج والسعر والقسم.');

      return;
    }

    if (oldPriceText.isNotEmpty && oldPrice == null) {
      _message('السعر القديم غير صحيح.');

      return;
    }

    if (_sizes.isEmpty) {
      _message('اختار مقاس واحد على الأقل.');

      return;
    }

    if (_colorVariants.isEmpty) {
      _message('اختار لون واحد على الأقل.');

      return;
    }

    // ==========================================================
    // EVERY COLOR MUST HAVE IMAGE
    // ==========================================================

    for (final variant in _colorVariants) {
      if (variant.image == null && variant.imageUrl.trim().isEmpty) {
        _message('لازم تختار صورة للون ${variant.color}.');

        return;
      }
    }

    // ==========================================================
    // PREVENT DUPLICATE COLORS
    // ==========================================================

    final colors = <String>{};

    for (final variant in _colorVariants) {
      final color = variant.color.trim().toUpperCase();

      if (!colors.add(color)) {
        _message('مينفعش تضيف نفس اللون مرتين.');

        return;
      }
    }

    setState(() {
      _saving = true;
    });

    // ==========================================================
    // EXISTING VARIANTS
    // ==========================================================

    final existingVariants = <ProductColorVariant>[];

    // ==========================================================
    // NEW IMAGES
    // ==========================================================

    final newImages = <String, PickedImageData>{};

    for (final variant in _colorVariants) {
      final color = variant.color.trim().toUpperCase();

      // صورة جديدة
      if (variant.image != null) {
        newImages[color] = variant.image!;
      }

      // صورة موجودة
      if (variant.imageUrl.trim().isNotEmpty) {
        existingVariants.add(
          ProductColorVariant(color: color, imageUrl: variant.imageUrl.trim()),
        );
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      AdminProductFormResult(
        name: name,
        description: description,
        price: price,
        oldPrice: oldPrice,
        categoryId: _categoryId!,

        sizes: List.unmodifiable(_sizes),

        sizeMode: _sizeMode,

        colorVariants: List.unmodifiable(existingVariants),

        colorVariantImages: Map.unmodifiable(newImages),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    final screenWidth = MediaQuery.sizeOf(context).width;

    final dialogWidth = screenWidth >= 760 ? 600.0 : screenWidth * .90;

    return AlertDialog(
      title: Text(
        isEdit ? 'تعديل المنتج' : 'إضافة منتج',

        style: const TextStyle(fontWeight: FontWeight.w900),
      ),

      content: SizedBox(
        width: dialogWidth,

        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // ==================================================
              // NAME
              // ==================================================
              TextField(
                controller: _nameController,

                decoration: const InputDecoration(labelText: 'اسم المنتج'),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              TextField(
                controller: _descriptionController,

                maxLines: 3,

                decoration: const InputDecoration(labelText: 'الوصف'),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // PRICE
              // ==================================================
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    return Column(
                      children: [
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'السعر'),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _oldPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'السعر القديم',
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'السعر'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: TextField(
                          controller: _oldPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'السعر القديم',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CATEGORY
              // ==================================================
              DropdownButtonFormField<String>(
                value: _categoryId,

                decoration: const InputDecoration(labelText: 'القسم'),

                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category['id'].toString(),
                        child: Text(
                          category['name'].toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),

                onChanged: _saving ? null : _onCategoryChanged,
              ),

              const SizedBox(height: 22),

              // ==================================================
              // COLORS HEADER
              // ==================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  const Expanded(
                    child: Text(
                      'ألوان المنتج',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  FilledButton.icon(
                    onPressed: _saving ? null : _addColor,

                    icon: const Icon(Icons.palette_outlined, size: 18),

                    label: const Text('إضافة لون'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // EMPTY COLORS
              // ==================================================
              if (_colorVariants.isEmpty)
                _buildEmptyColors()
              // ==================================================
              // COLORS
              // ==================================================
              else
                Column(
                  children: [
                    for (int i = 0; i < _colorVariants.length; i++)
                      _buildColorCard(_colorVariants[i], i),
                  ],
                ),

              const SizedBox(height: 22),

              // ==================================================
              // SIZES
              // ==================================================
              SizePresetPicker(
                mode: _sizeMode,

                selected: _sizes,

                onModeChanged: _saving
                    ? null
                    : (mode) {
                        setState(() {
                          _sizeMode = mode;

                          _sizes.clear();
                        });
                      },

                onToggle: _saving
                    ? null
                    : (size) {
                        setState(() {
                          if (_sizes.contains(size)) {
                            _sizes.remove(size);
                          } else {
                            _sizes.add(size);
                          }
                        });
                      },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),

          child: const Text('إلغاء'),
        ),

        FilledButton.icon(
          onPressed: _saving ? null : _submit,

          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),

          label: Text(isEdit ? 'حفظ التعديلات' : 'إضافة المنتج'),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY COLORS
  // ============================================================

  Widget _buildEmptyColors() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppConstants.surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppConstants.border),
      ),

      child: const Column(
        children: [
          Icon(Icons.palette_outlined, size: 32, color: AppConstants.gold),

          SizedBox(height: 8),

          Text(
            'مفيش ألوان مضافة',

            style: TextStyle(fontWeight: FontWeight.w800),
          ),

          SizedBox(height: 4),

          Text(
            'أضف لون واختار صورة خاصة به.',
            textAlign: TextAlign.center,

            style: TextStyle(color: AppConstants.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLOR CARD
  // ============================================================

  Widget _buildColorCard(_AdminColorVariantDraft variant, int index) {
    final color = _colorFromHex(variant.color);

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: AppConstants.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppConstants.border),
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          // ====================================================
          // SMALL WIDTH
          // ====================================================

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Row(
                  children: [
                    _buildColorCircle(color),

                    const SizedBox(width: 10),

                    _buildColorImage(variant),

                    const SizedBox(width: 10),

                    Expanded(child: _buildColorInfo(variant)),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    _buildColorAction(
                      tooltip: 'تعديل اللون',

                      icon: Icons.palette_outlined,

                      color: AppConstants.gold,

                      onPressed: _saving ? null : () => _editColor(index),
                    ),

                    _buildColorAction(
                      tooltip: 'تغيير الصورة',

                      icon: Icons.image_outlined,

                      onPressed: _saving
                          ? null
                          : () => _changeColorImage(index),
                    ),

                    _buildColorAction(
                      tooltip: 'حذف اللون',

                      icon: Icons.delete_outline,

                      color: Colors.redAccent,

                      onPressed: _saving ? null : () => _deleteColor(index),
                    ),
                  ],
                ),
              ],
            );
          }

          // ====================================================
          // LARGE WIDTH
          // ====================================================

          return Row(
            children: [
              _buildColorCircle(color),

              const SizedBox(width: 10),

              _buildColorImage(variant),

              const SizedBox(width: 12),

              Expanded(child: _buildColorInfo(variant)),

              _buildColorAction(
                tooltip: 'تعديل اللون',

                icon: Icons.palette_outlined,

                color: AppConstants.gold,

                onPressed: _saving ? null : () => _editColor(index),
              ),

              _buildColorAction(
                tooltip: 'تغيير الصورة',

                icon: Icons.image_outlined,

                onPressed: _saving ? null : () => _changeColorImage(index),
              ),

              _buildColorAction(
                tooltip: 'حذف اللون',

                icon: Icons.delete_outline,

                color: Colors.redAccent,

                onPressed: _saving ? null : () => _deleteColor(index),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // COLOR CIRCLE
  // ============================================================

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 46,
      height: 46,

      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,

        border: Border.all(color: Colors.white24, width: 2),
      ),
    );
  }

  // ============================================================
  // COLOR INFO
  // ============================================================

  Widget _buildColorInfo(_AdminColorVariantDraft variant) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          variant.color,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 4),

        Text(
          variant.image != null ? 'صورة جديدة' : 'الصورة محفوظة',

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(color: AppConstants.muted, fontSize: 11),
        ),
      ],
    );
  }

  // ============================================================
  // COLOR ACTION
  // ============================================================

  Widget _buildColorAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,

      onPressed: onPressed,

      padding: const EdgeInsets.all(7),

      constraints: const BoxConstraints(
        minWidth: 38,
        minHeight: 38,
        maxWidth: 42,
        maxHeight: 42,
      ),

      visualDensity: VisualDensity.compact,

      icon: Icon(icon, size: 20, color: color),
    );
  }

  // ============================================================
  // COLOR IMAGE
  // ============================================================

  Widget _buildColorImage(_AdminColorVariantDraft variant) {
    // ==========================================================
    // NEW IMAGE
    // ==========================================================

    if (variant.image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),

        child: Image.memory(
          variant.image!.bytes,

          width: 58,
          height: 58,

          fit: BoxFit.cover,

          errorBuilder: (_, __, ___) => _emptyImage(),
        ),
      );
    }

    // ==========================================================
    // EXISTING IMAGE
    // ==========================================================

    if (variant.imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),

        child: CachedNetworkImage(
          imageUrl: variant.imageUrl,

          width: 58,
          height: 58,

          fit: BoxFit.cover,

          placeholder: (_, __) => _imageLoading(),

          errorWidget: (_, __, ___) => _emptyImage(),
        ),
      );
    }

    return _emptyImage();
  }

  // ============================================================
  // IMAGE LOADING
  // ============================================================

  Widget _imageLoading() {
    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(
        color: AppConstants.black,

        borderRadius: BorderRadius.circular(12),
      ),

      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,

          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY IMAGE
  // ============================================================

  Widget _emptyImage() {
    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(
        color: AppConstants.black,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppConstants.border),
      ),

      child: const Icon(
        Icons.image_outlined,
        color: AppConstants.muted,
        size: 22,
      ),
    );
  }

  // ============================================================
  // HEX → COLOR
  // ============================================================

  Color _colorFromHex(String hex) {
    var clean = hex.replaceAll('#', '');

    if (clean.length == 6) {
      clean = 'FF$clean';
    }

    final value = int.tryParse(clean, radix: 16);

    return value == null ? AppConstants.gold : Color(value);
  }
}
