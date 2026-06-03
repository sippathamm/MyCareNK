import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class HtmlBodyRenderer extends StatelessWidget {
  final String body;

  const HtmlBodyRenderer({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return HtmlWidget(
      body,
      textStyle: GoogleFonts.googleSans(
        fontSize: 15,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      customStylesBuilder: (element) {
        if (element.localName == 'a') {
          return {'color': '#FF9F6B', 'text-decoration': 'underline'};
        }
        if (element.localName == 'blockquote') {
          return {'border-left': '4px solid #FF9F6B', 'padding-left': '12px', 'color': '#666666'};
        }
        return null;
      },
      customWidgetBuilder: (element) {
        if (element.localName == 'iframe') {
          final src = element.attributes['src'] ?? '';
          final videoId = _youTubeId(src);
          if (videoId != null) return _YouTubeThumbnail(videoId: videoId);
        }
        return null;
      },
    );
  }

  static String? _youTubeId(String src) {
    final m = RegExp(r'youtube(?:-nocookie)?\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(src);
    return m?.group(1);
  }
}

class _YouTubeThumbnail extends StatelessWidget {
  final String videoId;

  const _YouTubeThumbnail({required this.videoId});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
    final watchUrl = 'https://www.youtube.com/watch?v=$videoId';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: const Color(0x33000000)),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xCCFF0000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
            Positioned(
              bottom: 12,
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(watchUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFF0000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.of(context).openInYouTube,
                    style: GoogleFonts.googleSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
