import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../auth/presentation/pages/login_page.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Article {
  final String title;
  final String? coverImageUrl;
  final Map<String, dynamic>? contentJson;
  final String? publishAt;
  final String? createdByName;

  const _Article({
    required this.title,
    this.coverImageUrl,
    this.contentJson,
    this.publishAt,
    this.createdByName,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ArticleDetailPage extends StatefulWidget {
  final String articleId;

  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  _Article? _article;
  bool _loading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  bool _titleVisible = false;

  static const double _collapseThreshold = 260.0 - kToolbarHeight;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginRequired());
      return;
    }
    _scrollController.addListener(_onScroll);
    _fetchArticle();
  }

  void _showLoginRequired() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        elevation: 24,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'กรุณาเข้าสู่ระบบ',
          style: GoogleFonts.googleSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องเข้าสู่ระบบก่อนจึงจะอ่านบทความได้',
          style: GoogleFonts.googleSans(fontSize: 15, height: 1.6),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          GradientButton(
            height: 46,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final loggedIn = await Navigator.of(context, rootNavigator: true)
                  .push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()));
              if (!mounted) return;
              if (loggedIn == true) {
                _scrollController.addListener(_onScroll);
                _fetchArticle();
              } else {
                Navigator.of(context).pop();
              }
            },
            label: 'เข้าสู่ระบบ',
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.googleSans(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onScroll() {
    final visible = _scrollController.offset > _collapseThreshold;
    if (visible != _titleVisible) setState(() => _titleVisible = visible);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client.rpc(
        'get_article_detail',
        params: {'p_article_id': widget.articleId},
      );
      if (!mounted) return;
      if ((rows as List).isEmpty) throw Exception('not found');
      final data = rows.first as Map<String, dynamic>;
      setState(() {
        _article = _Article(
          title: data['title'] as String,
          coverImageUrl: data['cover_image_url'] as String?,
          contentJson: data['content_json'] as Map<String, dynamic>?,
          publishAt: data['publish_at'] as String?,
          createdByName: data['created_by_name'] as String?,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดบทความไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  static String _formatDateTime(String isoDate) {
    final dt = DateTime.parse(isoDate).add(const Duration(hours: 7));
    const months = [
      '',
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year + 543} $h:$m น.';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: const _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.grey.shade200),
            ),
          ),
          const SliverToBoxAdapter(child: _ShimmerContent()),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchArticle,
                child: Text('ลองใหม่', style: GoogleFonts.googleSans()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final article = _article!;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── SliverAppBar with cover ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: _BackButton(scrolled: _titleVisible),
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: _titleVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                article.title,
                style: GoogleFonts.googleSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  article.coverImageUrl != null
                      ? Image.network(
                          article.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _GradientCover(),
                        )
                      : const _GradientCover(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      child: Text(
                        article.title,
                        style: GoogleFonts.googleSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (article.createdByName != null &&
                      article.createdByName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          article.createdByName!,
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  if (article.publishAt != null) ...[
                    if (article.createdByName != null &&
                        article.createdByName!.isNotEmpty)
                      const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(article.publishAt!),
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (article.contentJson != null)
                    _TipTapRenderer(doc: article.contentJson!),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final bool scrolled;
  const _BackButton({this.scrolled = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 0 : 1,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0x4D000000),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 0 : 1,
            child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: scrolled ? 1 : 0,
            child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(18),
              child: const SizedBox(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient cover placeholder ───────────────────────────────────────────────

class _GradientCover extends StatelessWidget {
  const _GradientCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryCardStart, AppColors.primaryCardEnd],
        ),
      ),
    );
  }
}

// ─── TipTap JSON renderer ─────────────────────────────────────────────────────

class _TipTapRenderer extends StatelessWidget {
  final Map<String, dynamic> doc;

  const _TipTapRenderer({required this.doc});

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
                    'เปิดใน YouTube',
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

// ─── Shimmer loading ──────────────────────────────────────────────────────────

class _ShimmerContent extends StatefulWidget {
  const _ShimmerContent();

  @override
  State<_ShimmerContent> createState() => _ShimmerContentState();
}

class _ShimmerContentState extends State<_ShimmerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(12, double.infinity),
              const SizedBox(height: 20),
              _shimmerBox(14, double.infinity),
              const SizedBox(height: 8),
              _shimmerBox(14, double.infinity),
              const SizedBox(height: 8),
              _shimmerBox(14, 220),
              const SizedBox(height: 20),
              _shimmerBox(14, double.infinity),
              const SizedBox(height: 8),
              _shimmerBox(14, double.infinity),
              const SizedBox(height: 8),
              _shimmerBox(14, 180),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
