import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../widgets/html_body_renderer.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Article {
  final String title;
  final String? thumbnailUrl;
  final String? body;
  final String? category;
  final String? publishedAt;
  final String? createdByName;

  const _Article({
    required this.title,
    this.thumbnailUrl,
    this.body,
    this.category,
    this.publishedAt,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).pleaseLogin,
          style: GoogleFonts.googleSans(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context).loginToReadArticle,
          style: GoogleFonts.googleSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).cancel,
                style: GoogleFonts.googleSans(color: AppColors.textSecondary)),
          ),
          TextButton(
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
            child: Text(AppLocalizations.of(context).loginBtn,
                style: GoogleFonts.googleSans(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          thumbnailUrl: data['thumbnail_url'] as String?,
          body: data['body'] as String?,
          category: data['category'] as String?,
          publishedAt: data['published_at'] as String?,
          createdByName: data['created_by_name'] as String?,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.current.loadArticleError;
        _loading = false;
      });
    }
  }

  static String _formatDateTime(String isoDate) {
    final dt = DateTime.parse(isoDate).add(const Duration(hours: 7));
    final l10n = AppLocalizations.current;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${l10n.monthsShort[dt.month - 1]} ${dt.year + 543} $h:$m ${l10n.timeWithUnit}';
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
                child: Text(AppLocalizations.of(context).tryAgain, style: GoogleFonts.googleSans()),
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
                  article.thumbnailUrl != null
                      ? Image.network(
                          article.thumbnailUrl!,
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
                  if (article.category != null && article.category!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category!,
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
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
                  if (article.publishedAt != null) ...[
                    if (article.createdByName != null &&
                        article.createdByName!.isNotEmpty)
                      const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(article.publishedAt!),
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (article.body != null && article.body!.isNotEmpty)
                    HtmlBodyRenderer(body: article.body!),
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
