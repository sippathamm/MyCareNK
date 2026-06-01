import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Renders a native ProseMirror/TipTap document (the JSON shape stored in
/// `articles.content_json`) into Flutter widgets. Supports headings,
/// paragraphs, lists, blockquotes, code blocks, images, YouTube embeds and
/// horizontal rules, plus inline bold/italic/strike/code/link marks.
class TipTapRenderer extends StatelessWidget {
  final Map<String, dynamic> doc;

  const TipTapRenderer({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final nodes =
        (doc['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final node in nodes) _buildNode(node)],
    );
  }

  // ─── Block node dispatcher ─────────────────────────────────────────────────

  Widget _buildNode(Map<String, dynamic> node) {
    return switch (node['type'] as String?) {
      'heading'        => _buildHeading(node),
      'paragraph'      => _buildParagraph(node),
      'bulletList'     => _buildList(node, ordered: false),
      'orderedList'    => _buildList(node, ordered: true),
      'blockquote'     => _buildBlockquote(node),
      'codeBlock'      => _buildCodeBlock(node),
      'image'          => _buildImage(node),
      'youtube'        => _buildYouTube(node),
      'horizontalRule' => _buildHorizontalRule(),
      _                => const SizedBox.shrink(),
    };
  }

  // ─── Block builders ────────────────────────────────────────────────────────

  Widget _buildHeading(Map<String, dynamic> node) {
    final level =
        ((node['attrs'] as Map?)?['level'] as num?)?.toInt() ?? 1;
    final idx = (level - 1).clamp(0, 2);
    const fontSizes  = [22.0, 18.0, 16.0];
    const topPads    = [16.0, 14.0, 12.0];
    const bottomPads = [ 8.0,  6.0,  4.0];
    return Padding(
      padding: EdgeInsets.only(top: topPads[idx], bottom: bottomPads[idx]),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.googleSans(
            fontSize: fontSizes[idx],
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
          children: _inlineSpans(node),
        ),
      ),
    );
  }

  Widget _buildParagraph(Map<String, dynamic> node, {Color? textColor}) {
    final content =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (content.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.googleSans(
            fontSize: 15,
            color: textColor ?? AppColors.textPrimary,
            height: 1.6,
          ),
          children: _inlineSpans(node, textColor: textColor),
        ),
      ),
    );
  }

  Widget _buildList(Map<String, dynamic> node, {required bool ordered}) {
    final items =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final start =
        ordered ? (((node['attrs'] as Map?)?['start'] as num?)?.toInt() ?? 1) : 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            _buildListItem(
              items[i],
              bullet: ordered ? '${start + i}.' : '•',
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> node, {required String bullet}) {
    final content =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              bullet,
              style: GoogleFonts.googleSans(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (final child in content) _buildNode(child)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockquote(Map<String, dynamic> node) {
    final content =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in content)
              child['type'] == 'paragraph'
                  ? _buildParagraph(child, textColor: AppColors.textSecondary)
                  : _buildNode(child),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBlock(Map<String, dynamic> node) {
    final content =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final text = content.map((n) => n['text'] as String? ?? '').join('');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildImage(Map<String, dynamic> node) {
    final attrs =
        (node['attrs'] as Map?)?.cast<String, dynamic>() ?? {};
    final src = attrs['src'] as String?;
    if (src == null || src.isEmpty) return const SizedBox.shrink();

    final widthStr = attrs['imgWidth'] as String? ?? '100%';
    final align    = attrs['imgAlign'] as String? ?? 'left';
    final match    = RegExp(r'([\d.]+)%').firstMatch(widthStr);
    final fraction = match != null ? double.parse(match.group(1)!) / 100.0 : 1.0;
    final alignment = switch (align) {
      'center' => Alignment.center,
      'right'  => Alignment.centerRight,
      _        => Alignment.centerLeft,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (_, constraints) => Align(
          alignment: alignment,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              src,
              width: constraints.maxWidth * fraction,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouTube(Map<String, dynamic> node) {
    final attrs = (node['attrs'] as Map?)?.cast<String, dynamic>() ?? {};
    final src    = attrs['src'] as String? ?? '';
    final videoId = _youTubeId(src);
    if (videoId == null) return const SizedBox.shrink();
    return _YouTubeThumbnail(videoId: videoId);
  }

  Widget _buildHorizontalRule() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(),
    );
  }

  // ─── Inline span builders ──────────────────────────────────────────────────

  List<InlineSpan> _inlineSpans(
    Map<String, dynamic> node, {
    Color? textColor,
  }) {
    final content =
        (node['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return content
        .map((n) => _buildInlineSpan(n, textColor: textColor))
        .toList();
  }

  InlineSpan _buildInlineSpan(
    Map<String, dynamic> node, {
    Color? textColor,
  }) {
    if (node['type'] == 'hardBreak') return const TextSpan(text: '\n');
    if (node['type'] != 'text') return const TextSpan(text: '');

    final text  = node['text'] as String? ?? '';
    final marks =
        (node['marks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    var style = TextStyle(color: textColor ?? AppColors.textPrimary);
    String? linkHref;

    for (final mark in marks) {
      switch (mark['type'] as String?) {
        case 'bold':
          style = style.copyWith(fontWeight: FontWeight.bold);
        case 'italic':
          style = style.copyWith(fontStyle: FontStyle.italic);
        case 'strike':
          style = style.copyWith(decoration: TextDecoration.lineThrough);
        case 'code':
          style = style.copyWith(
            fontFamily: 'monospace',
            fontSize: 13,
            backgroundColor: Colors.grey.shade200,
          );
        case 'link':
          linkHref = (mark['attrs'] as Map?)?['href'] as String?;
      }
    }

    if (linkHref != null) {
      final href = linkHref;
      return TextSpan(
        text: text,
        style: style.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () =>
              launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication),
      );
    }

    return TextSpan(text: text, style: style);
  }

  // ─── YouTube ID helper ─────────────────────────────────────────────────────

  static String? _youTubeId(String src) {
    var m = RegExp(r'youtube(?:-nocookie)?\.com/embed/([a-zA-Z0-9_-]+)')
        .firstMatch(src);
    if (m != null) return m.group(1);
    m = RegExp(r'youtube\.com/watch\?[^"]*[?&]v=([a-zA-Z0-9_-]+)')
        .firstMatch(src);
    if (m != null) return m.group(1);
    m = RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)').firstMatch(src);
    return m?.group(1);
  }
}

// ─── YouTube thumbnail ────────────────────────────────────────────────────────

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
                  child: const Icon(Icons.videocam_off,
                      color: Colors.grey, size: 48),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
