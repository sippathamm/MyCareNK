import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Article {
  final String title;
  final String? coverImageUrl;
  final String? contentHtml;
  final String? publishAt;
  final String? createdByName;

  const _Article({
    required this.title,
    this.coverImageUrl,
    this.contentHtml,
    this.publishAt,
    this.createdByName,
  });
}

// ─── Content chunk models (for YouTube parsing) ───────────────────────────────

abstract class _Chunk {}

class _HtmlChunk extends _Chunk {
  final String html;
  _HtmlChunk(this.html);
}

class _YouTubeChunk extends _Chunk {
  final String videoId;
  _YouTubeChunk(this.videoId);
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

  // SliverAppBar collapses after scrolling past expandedHeight - toolbar height.
  static const double _collapseThreshold = 260.0 - kToolbarHeight;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchArticle();
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
          contentHtml: data['content_html'] as String?,
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

  // Extract YouTube video ID from any common URL format.
  static String? _youTubeId(String src) {
    // youtube.com/embed/ID or youtube-nocookie.com/embed/ID
    var m = RegExp(r'youtube(?:-nocookie)?\.com/embed/([a-zA-Z0-9_-]+)')
        .firstMatch(src);
    if (m != null) return m.group(1);
    // youtube.com/watch?v=ID
    m = RegExp(r'youtube\.com/watch\?[^"]*[?&]v=([a-zA-Z0-9_-]+)')
        .firstMatch(src);
    if (m != null) return m.group(1);
    // youtu.be/ID
    m = RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)').firstMatch(src);
    if (m != null) return m.group(1);
    return null;
  }

  // Split html into Html chunks and YouTube chunks.
  // Also captures the optional <div data-youtube-video> wrapper.
  static List<_Chunk> _parseChunks(String html) {
    final chunks = <_Chunk>[];
    // Match optional wrapper div + iframe with any YouTube src + optional closing tags
    final re = RegExp(
      r'(?:<div[^>]*data-youtube-video[^>]*>\s*)?'
      r'<iframe[^>]+\bsrc="([^"]*(?:youtube(?:-nocookie)?\.com|youtu\.be)[^"]*)"[^>]*>'
      r'(?:.*?</iframe>)?'
      r'(?:\s*</div>)?',
      caseSensitive: false,
      dotAll: true,
    );
    int lastEnd = 0;
    for (final m in re.allMatches(html)) {
      final src = m.group(1) ?? '';
      final videoId = _youTubeId(src);
      if (videoId == null) continue; // not a YouTube iframe — leave in HTML
      if (m.start > lastEnd) {
        chunks.add(_HtmlChunk(html.substring(lastEnd, m.start)));
      }
      chunks.add(_YouTubeChunk(videoId));
      lastEnd = m.end;
    }
    if (lastEnd < html.length) {
      chunks.add(_HtmlChunk(html.substring(lastEnd)));
    }
    return chunks;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading(context);
    if (_error != null) return _buildError(context);
    return _buildContent(context);
  }

  Widget _buildLoading(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.white,
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

  Widget _buildError(BuildContext context) {
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

  Widget _buildContent(BuildContext context) {
    final article = _article!;
    final chunks =
        article.contentHtml != null ? _parseChunks(article.contentHtml!) : <_Chunk>[];

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
            automaticallyImplyLeading: false,
            leading: const _BackButton(),
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
                  // Bottom gradient overlay + title
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
                  if (article.createdByName != null)
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
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
                    if (article.createdByName != null) const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
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
                  ...chunks.map((chunk) {
                    if (chunk is _YouTubeChunk) {
                      return _YouTubeThumbnail(videoId: chunk.videoId);
                    }
                    return _HtmlBody(html: (chunk as _HtmlChunk).html);
                  }),
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
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0x4D000000),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
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

// ─── Html content ─────────────────────────────────────────────────────────────

class _HtmlBody extends StatelessWidget {
  final String html;

  const _HtmlBody({required this.html});

  @override
  Widget build(BuildContext context) {
    return Html(
      data: html,
      onLinkTap: (url, _, _) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      style: {
        'body': Style(
          fontFamily: 'GoogleSans',
          fontSize: FontSize(15),
          lineHeight: LineHeight(1.6),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(
          margin: Margins.only(top: 0, bottom: 8),
          padding: HtmlPaddings.zero,
        ),
        'div': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'hr': Style(
          margin: Margins.symmetric(vertical: 8),
        ),
        'h1': Style(
          fontSize: FontSize(22),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 16, bottom: 8),
        ),
        'h2': Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 14, bottom: 6),
        ),
        'h3': Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          margin: Margins.only(top: 12, bottom: 4),
        ),
        'a': Style(color: AppColors.primary),
        'blockquote': Style(
          padding: HtmlPaddings.only(left: 16),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 4),
          ),
          color: AppColors.textSecondary,
        ),
        'img': Style(width: Width(100, Unit.percent)),
      },
    );
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
            // Thumbnail
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
            // Dark overlay
            Positioned.fill(
              child: Container(color: const Color(0x33000000)),
            ),
            // Play icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xCCFF0000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
            // "เปิดใน YouTube" button at bottom
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
