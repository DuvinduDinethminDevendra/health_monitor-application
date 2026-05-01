import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class DescendersFooter extends StatelessWidget {
  /// When true, shows a subtle "Created by" label above the pill.
  /// Use on Profile, Login, and Register screens only.
  final bool showCreatedBy;

  const DescendersFooter({super.key, this.showCreatedBy = false});

  Future<void> _launchUrl() async {
    final Uri url =
        Uri.parse('https://lakidev.me/#/projects/healthapp/devteam');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.scooter : AppTheme.blueLagoon;

    const String svgPath =
        'M12 2a1 1 0 0 1 1 1v5.5a1 1 0 0 1-1 1H5.5a1 1 0 0 1 0-2H10V3a1 1 0 0 1 1-1zm1 18a1 1 0 0 1-1 1 1 1 0 0 1-1-1v-5.5a1 1 0 0 1 1-1h6.5a1 1 0 0 1 0 2H14V19a1 1 0 0 1-1 1z';

    final svgWidget = SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <path fill="currentColor" d="$svgPath" />
        </svg>''',
      width: 11,
      height: 11,
      colorFilter:
          ColorFilter.mode(primaryColor.withOpacity(0.8), BlendMode.srcIn),
    );

    final pill = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launchUrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: primaryColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              svgWidget
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 4.seconds, curve: Curves.linear),
              const SizedBox(width: 10),
              Text(
                'DESCENDERS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2.2,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 10),
              svgWidget
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(
                      duration: 4.seconds,
                      curve: Curves.linear,
                      begin: 1,
                      end: 0),
            ],
          ),
        ),
      ),
    );

    if (!showCreatedBy) return pill;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Created by',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color:
                (isDark ? Colors.white : AppTheme.sapphire).withOpacity(0.35),
            letterSpacing: 0.5,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 6),
        pill,
      ],
    );
  }
}
