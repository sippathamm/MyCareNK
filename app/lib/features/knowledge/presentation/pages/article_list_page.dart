import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'article_detail_page.dart';
import '../../../../../core/l10n/app_localizations.dart';

class ArticleListPage extends StatefulWidget {
  const ArticleListPage({super.key});

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  static const int _pageSize = 10;

  final List<Map<String, dynamic>> _articles = [];
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLoginRequired());
      return;
    }
    _fetchArticles();
    _scrollController.addListener(_onScroll);
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
          AppLocalizations.of(context).loginToViewArticles,
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
                _fetchArticles();
                _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 200 && !_loadingMore && _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _loading = true;
      _error = null;
      _articles.clear();
      _offset = 0;
      _hasMore = true;
    });
    try {
      final data = await Supabase.instance.client.rpc(
        'get_published_articles',
        params: {'p_limit': _pageSize, 'p_offset': 0},
      );
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data as List);
      setState(() {
        _articles.addAll(list);
        _offset = list.length;
        _hasMore = list.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _loadingMore = true);
    try {
      final data = await Supabase.instance.client.rpc(
        'get_published_articles',
        params: {'p_limit': _pageSize, 'p_offset': _offset},
      );
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data as List);
      setState(() {
        _articles.addAll(list);
        _offset += list.length;
        _hasMore = list.length == _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  static String _formatDateTime(String isoDate) {
    final dt = DateTime.parse(isoDate).add(const Duration(hours: 7));
    final l10n = AppLocalizations.current;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${l10n.monthsShort[dt.month - 1]} ${dt.year + 543} $h:$m ${l10n.timeWithUnit}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).articlesTitle,
          style: GoogleFonts.googleSans(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => const _SkeletonArticleCard(),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).errorOccurredTitle,
              style: GoogleFonts.googleSans(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _fetchArticles,
              child: Text(AppLocalizations.of(context).tryAgain, style: GoogleFonts.googleSans()),
            ),
          ],
        ),
      );
    }
    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noArticles,
              style: GoogleFonts.googleSans(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _articles.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == _articles.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        final a = _articles[index];
        return _ArticleCard(
          id: a['id'] as String,
          title: a['title'] as String,
          excerpt: a['excerpt'] as String?,
          coverImageUrl: a['cover_image_url'] as String?,
          publishAt: a['publish_at'] as String?,
          createdByName: a['created_by_name'] as String?,
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String id;
  final String title;
  final String? excerpt;
  final String? coverImageUrl;
  final String? publishAt;
  final String? createdByName;

  const _ArticleCard({
    required this.id,
    required this.title,
    this.excerpt,
    this.coverImageUrl,
    this.publishAt,
    this.createdByName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: AppColors.white,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleDetailPage(articleId: id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: coverImageUrl != null
                      ? Image.network(
                          coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _GradientPlaceholder(),
                        )
                      : const _GradientPlaceholder(),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.googleSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (excerpt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          excerpt!,
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (createdByName != null && createdByName!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              createdByName!,
                              style: GoogleFonts.googleSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      if (publishAt != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              _ArticleListPageState._formatDateTime(publishAt!),
                              style: GoogleFonts.googleSans(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonArticleCard extends StatelessWidget {
  const _SkeletonArticleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(height: 180, color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 14, width: 200, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(height: 12, width: 100, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

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
