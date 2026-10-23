import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/constants/app_constants.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, this.initialHex});

  final String? initialHex;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();

    _color = _parseColor(widget.initialHex ?? '#000000');

    _hexController = TextEditingController(text: _toHex(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color _parseColor(String value) {
    var hex = value.replaceAll('#', '').replaceAll('0x', '').trim();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return Colors.black;
    }

    final parsed = int.tryParse(hex, radix: 16);

    return parsed == null ? Colors.black : Color(parsed);
  }

  String _toHex(Color color) {
    return '#'
            '${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _changeColor(Color color) {
    setState(() {
      _color = color;
      _hexController.text = _toHex(color);
      _hexController.selection = TextSelection.fromPosition(
        TextPosition(offset: _hexController.text.length),
      );
    });
  }

  void _changeHex(String value) {
    var hex = value.replaceAll('#', '').trim();

    if (hex.length != 6) return;

    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return;
    }

    setState(() {
      _color = _parseColor('#$hex');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppConstants.surface,

      title: const Text(
        'اختيار اللون',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),

      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: _color,
                onColorChanged: _changeColor,
                enableAlpha: false,
                pickerAreaHeightPercent: .72,
                displayThumbColor: true,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(18),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      _toHex(_color),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _hexController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'HEX',
                  hintText: '#D4AF37',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                onChanged: _changeHex,
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),

        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context, _toHex(_color));
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('اختيار اللون'),
        ),
      ],
    );
  }
}
