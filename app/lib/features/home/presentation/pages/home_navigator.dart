import 'package:flutter/material.dart';
import 'home_page.dart';

class HomeNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<int> visibilityNotifier;
  final VoidCallback? onNavigateToHistory;

  const HomeNavigator({
    super.key,
    required this.navigatorKey,
    required this.visibilityNotifier,
    this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => HomePage(
          visibilityNotifier: visibilityNotifier,
          onNavigateToHistory: onNavigateToHistory,
        ),
      ),
    );
  }
}
