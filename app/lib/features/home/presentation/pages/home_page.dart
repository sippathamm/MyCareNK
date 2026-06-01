import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/header_section.dart';
import '../widgets/monthly_free_card.dart';
import '../widgets/shortcut_menu.dart';
import '../widgets/knowledge_section.dart';
import '../widgets/campaign_banner.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<int>? visibilityNotifier;
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onGoToSettings;

  const HomePage({
    super.key,
    this.visibilityNotifier,
    this.onNavigateToHistory,
    this.onGoToSettings,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Tracks the combined refresh reason: pull-to-refresh OR tab switch
  int _cardRefreshKey = 0;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    widget.visibilityNotifier?.addListener(_onVisibilityChanged);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.signedIn) {
        setState(() => _cardRefreshKey++);
      }
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibilityNotifier != widget.visibilityNotifier) {
      oldWidget.visibilityNotifier?.removeListener(_onVisibilityChanged);
      widget.visibilityNotifier?.addListener(_onVisibilityChanged);
    }
  }

  @override
  void dispose() {
    widget.visibilityNotifier?.removeListener(_onVisibilityChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (mounted) setState(() => _cardRefreshKey++);
  }

  Future<void> _onRefresh() async {
    setState(() => _cardRefreshKey++);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFFF8A50),
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: HeaderSection(onGoToSettings: widget.onGoToSettings),
              ),
              const SizedBox(height: 8),
              MonthlyFreeCard(refreshKey: _cardRefreshKey),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ShortcutMenu(onNavigateToHistory: widget.onNavigateToHistory),
              ),
              const SizedBox(height: 24),
              KnowledgeSection(refreshKey: _cardRefreshKey),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: CampaignBanner(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
