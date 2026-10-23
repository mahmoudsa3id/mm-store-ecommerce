import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/home_entity.dart';

class SocialContactSection extends StatelessWidget {
  const SocialContactSection({
    super.key,
    required this.socials,
    required this.contact,
  });

  final SocialEntity socials;
  final ContactEntity contact;

  // ============================================================
  // OPEN SOCIAL LINK
  // ============================================================

  Future<void> _openLink(BuildContext context, String value) async {
    final raw = value.trim();

    if (raw.isEmpty) {
      _showMessage(context, 'الرابط غير متاح حاليًا.');
      return;
    }

    final normalized = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'https://$raw';

    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      _showMessage(context, 'الرابط غير صحيح.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        _showMessage(context, 'تعذر فتح الرابط.');
      }
    } catch (_) {
      if (!context.mounted) return;

      _showMessage(context, 'تعذر فتح الرابط.');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        18,
        AppConstants.horizontalPadding,
        90,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConstants.surfaceElevated, AppConstants.black],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppConstants.gold.withValues(alpha: .16)),
          boxShadow: const [AppConstants.shadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            const Text(
              'تابع MM Store',
              style: TextStyle(
                color: AppConstants.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'خليك قريب من آخر التشكيلات والعروض.',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 20),

            // ======================================================
            // SOCIAL MEDIA
            // ======================================================
            Row(
              children: [
                // FACEBOOK
                Expanded(
                  child: _SocialButton(
                    icon: FontAwesomeIcons.facebookF,
                    url: socials.facebook,
                    onTap: () {
                      _openLink(context, socials.facebook);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // INSTAGRAM
                Expanded(
                  child: _SocialButton(
                    icon: FontAwesomeIcons.instagram,
                    url: socials.instagram,
                    onTap: () {
                      _openLink(context, socials.instagram);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // TIKTOK
                Expanded(
                  child: _SocialButton(
                    icon: FontAwesomeIcons.tiktok,
                    url: socials.tiktok,
                    onTap: () {
                      _openLink(context, socials.tiktok);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // TELEGRAM
                Expanded(
                  child: _SocialButton(
                    icon: FontAwesomeIcons.telegram,
                    url: socials.telegram,
                    onTap: () {
                      _openLink(context, socials.telegram);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ======================================================
            // CONTACT
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppConstants.black,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تواصل معنا',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (contact.phone.trim().isNotEmpty)
                    _Line(icon: Icons.phone_outlined, text: contact.phone),

                  if (contact.address.trim().isNotEmpty)
                    _Line(
                      icon: Icons.location_on_outlined,
                      text: contact.address,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ======================================================
            // BRAND
            // ======================================================
            const Center(
              child: Text(
                'MM Store',
                style: TextStyle(
                  color: AppConstants.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Center(
              child: Text(
                'جميع الحقوق محفوظة © MM Store',
                style: TextStyle(
                  color: AppConstants.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SOCIAL BUTTON
// ============================================================================

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.url,
    required this.onTap,
  });

  final FaIconData icon;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = url.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),

      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: enabled
                ? AppConstants.black
                : AppConstants.black.withValues(alpha: .45),
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? AppConstants.gold.withValues(alpha: .30)
                  : AppConstants.border,
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppConstants.gold.withValues(alpha: .08),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FaIcon(
              icon,
              size: 21,
              color: enabled ? AppConstants.gold : AppConstants.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CONTACT LINE
// ============================================================================

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.gold, size: 18),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
