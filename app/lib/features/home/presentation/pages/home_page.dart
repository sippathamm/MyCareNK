import 'package:flutter/material.dart';
import '../widgets/header_section.dart';
import '../widgets/monthly_free_card.dart';
import '../widgets/shortcut_menu.dart';
import '../widgets/knowledge_section.dart';
import '../widgets/campaign_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 24),
              const MonthlyFreeCard(),
              const SizedBox(height: 24),
              const ShortcutMenu(),
              const SizedBox(height: 24),
              const KnowledgeSection(),
              const SizedBox(height: 24),
              const CampaignBanner(),
              const SizedBox(height: 24), // Extra spacing at bottom
            ],
          ),
        ),
      ),
    );
  }
}
