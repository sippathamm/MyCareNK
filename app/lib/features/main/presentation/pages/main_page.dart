import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/services/app_version_service.dart';
import '../../../home/presentation/pages/home_navigator.dart';
import '../../../messages/presentation/pages/messages_page.dart';
import '../../../scan/presentation/pages/scan_page.dart';
import '../../../service/presentation/pages/service_navigator.dart';
import '../../../service/presentation/pages/request_history_page.dart';
import '../../widgets/update_dialog.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _homeVisibilityNotifier = ValueNotifier(0);
  int _messagesRefreshKey = 0;
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _serviceNavigatorKey =
      GlobalKey<NavigatorState>();

  // Unread count จาก MessagesPage — ใช้แสดง badge บน nav bar
  final ValueNotifier<int> _messagesUnreadNotifier = ValueNotifier(0);

  StreamSubscription<AuthState>? _authSubscription;
  bool _versionCheckDone = false;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.signedOut) {
        _messagesUnreadNotifier.value = 0;
        setState(() {
          _currentIndex = 0;
          _messagesRefreshKey++;
        });
      } else if (state.event == AuthChangeEvent.signedIn) {
        setState(() => _messagesRefreshKey++);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_versionCheckDone || !mounted) return;
    _versionCheckDone = true;
    final service = AppVersionService();
    final remote = await service.getLatestVersion();
    if (remote == null || !mounted) return;
    final hasUpdate = await service.isUpdateAvailable();
    if (hasUpdate && mounted) {
      await UpdateDialog.show(context, remote);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _homeVisibilityNotifier.dispose();
    _messagesUnreadNotifier.dispose();
    super.dispose();
  }

  void _navigateToHistory() {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
      );
    });
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) {
        _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (index == 1) {
        _serviceNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      setState(() {
        if (index == 0) _homeVisibilityNotifier.value++;
        if (index == 3) _messagesRefreshKey++;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeNavigator(navigatorKey: _homeNavigatorKey, visibilityNotifier: _homeVisibilityNotifier, onNavigateToHistory: _navigateToHistory, onGoToSettings: () => _onItemTapped(4)),
          ServiceNavigator(navigatorKey: _serviceNavigatorKey),
          const ScanPage(),
          MessagesPage(unreadNotifier: _messagesUnreadNotifier, refreshKey: _messagesRefreshKey),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context).navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view),
            activeIcon: const Icon(Icons.grid_view, color: AppColors.primary),
            label: AppLocalizations.of(context).navService,
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryButtonShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.white),
            ),
            label: AppLocalizations.of(context).navScan,
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<int>(
              valueListenable: _messagesUnreadNotifier,
              builder: (context, count, child) => Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppColors.error,
                label: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            activeIcon: ValueListenableBuilder<int>(
              valueListenable: _messagesUnreadNotifier,
              builder: (context, count, child) => Badge(
                isLabelVisible: count > 0,
                backgroundColor: AppColors.error,
                label: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                child: const Icon(Icons.chat_bubble),
              ),
            ),
            label: AppLocalizations.of(context).navMessages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: AppLocalizations.of(context).navSettings,
          ),
        ],
      ),
    );
  }
}
