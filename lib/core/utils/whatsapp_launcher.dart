import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  const WhatsAppLauncher();

  Future<bool> open(String rawPhone) async {
    final phone = _normalizeEgyptianPhone(rawPhone);
    if (phone.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$phone');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _normalizeEgyptianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('+')) return digits.substring(1);
    if (digits.startsWith('20')) return digits;
    if (digits.startsWith('0')) return '20${digits.substring(1)}';
    return digits;
  }
}
