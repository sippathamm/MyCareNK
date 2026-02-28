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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: HeaderSection(),
            ),
            SizedBox(height: 8),
            MonthlyFreeCard(),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: ShortcutMenu(),
            ),
            SizedBox(height: 24),
            KnowledgeSection(),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: CampaignBanner(),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
