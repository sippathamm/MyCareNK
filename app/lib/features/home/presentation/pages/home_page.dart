import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/header_section.dart';
import '../widgets/monthly_free_card.dart';
import '../widgets/shortcut_menu.dart';
import '../widgets/knowledge_section.dart';
import '../widgets/campaign_banner.dart';

class HomePage extends StatefulWidget {
  /// Increments each time the home tab becomes active, used to replay animations.
  final int visibilityKey;
  final VoidCallback? onNavigateToHistory;

  const HomePage({super.key, this.visibilityKey = 0, this.onNavigateToHistory});

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
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent (MainScreen) incremented visibilityKey => user switched to home tab
    if (oldWidget.visibilityKey != widget.visibilityKey) {
      setState(() => _cardRefreshKey++);
    }
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: HeaderSection(),
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
