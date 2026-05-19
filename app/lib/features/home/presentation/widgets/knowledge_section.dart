import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../knowledge/presentation/pages/article_detail_page.dart';
import '../../../knowledge/presentation/pages/article_list_page.dart';

class _ArticleItem {
  final String id;
  final String title;
  final String? excerpt;
  final String? coverImageUrl;

  const _ArticleItem({
    required this.id,
    required this.title,
    this.excerpt,
    this.coverImageUrl,
  });

  factory _ArticleItem.fromMap(Map<String, dynamic> map) => _ArticleItem(
        id: map['id'] as String,
        title: map['title'] as String,
        excerpt: map['excerpt'] as String?,
        coverImageUrl: map['cover_image_url'] as String?,
      );
}

class KnowledgeSection extends StatefulWidget {
  final int refreshKey;

  const KnowledgeSection({super.key, this.refreshKey = 0});

  @override
  State<KnowledgeSection> createState() => _KnowledgeSectionState();
}

class _KnowledgeSectionState extends State<KnowledgeSection> {
  List<_ArticleItem> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void didUpdateWidget(KnowledgeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _fetchArticles();
    }
  }

  Future<void> _fetchArticles() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .rpc('get_published_articles', params: {'p_limit': 5, 'p_offset': 0});
      if (!mounted) return;
      final list = (data as List)
          .map((e) => _ArticleItem.fromMap(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _articles = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _articles = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'บทความ',
                style: GoogleFonts.googleSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArticleListPage()),
                ),
                child: Row(
                  children: [
                    Text(
                      'ดูทั้งหมด',
                      style: GoogleFonts.googleSans(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 192,
          child: _loading
              ? _ShimmerList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 8.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _articles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      _ArticleCard(article: _articles[index]),
                ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final _ArticleItem article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
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
                builder: (_) => ArticleDetailPage(articleId: article.id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: article.coverImageUrl != null
                      ? Image.network(
                          article.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _GradientPlaceholder(),
                        )
                      : const _GradientPlaceholder(),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (article.excerpt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            article.excerpt!,
                            style: GoogleFonts.googleSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
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

class _ShimmerList extends StatefulWidget {
  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
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
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
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
      builder: (context, child) => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
