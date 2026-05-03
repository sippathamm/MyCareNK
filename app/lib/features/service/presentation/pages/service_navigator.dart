import 'package:flutter/material.dart';
import 'service_page.dart';

class ServiceNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const ServiceNavigator({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          builder: (BuildContext context) => const ServicePage(),
        );
      },
    );
  }
}
