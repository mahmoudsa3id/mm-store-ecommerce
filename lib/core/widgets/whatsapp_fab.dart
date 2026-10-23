import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../utils/whatsapp_launcher.dart';

class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    if (phone.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      heroTag: 'mm-store-whatsapp-fab',
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      elevation: 8,
      onPressed: () async {
        final opened = await const WhatsAppLauncher().open(phone);

        if (!opened && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب.')));
        }
      },
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
      label: const Text(
        'واتساب',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
