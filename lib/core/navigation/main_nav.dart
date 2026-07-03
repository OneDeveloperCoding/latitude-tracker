import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/notification_service.dart';
import 'package:latitude_tracker/core/services/shared_prefs_cache.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/repairs_store.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/features/buyers/screens/buyers_list_screen.dart';
import 'package:latitude_tracker/features/dashboard/screens/dashboard_screen.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/demo/demo_tutorial_sheet.dart';
import 'package:latitude_tracker/features/repairs/screens/sales_repairs_tab_screen.dart';
import 'package:latitude_tracker/features/settings/screens/settings_screen.dart';
import 'package:latitude_tracker/features/settings/services/update_service.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    SalesRepairsTabScreen(),
    BuyersListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SalesStore.init();
    BuyersStore.init();
    RepairsStore.init();
    unawaited(UpdateService.instance.checkForUpdate());
    // One-time cleanup: the geocoding cache namespace was retired when the
    // heat map switched from live Nominatim lookups to a bundled static
    // table (see docs/adr/0010-static-cp4-lookup-table.md) — this can be
    // removed once enough time has passed that upgraded devices no longer
    // carry the old keys.
    unawaited(SharedPrefsCache.purgeNamespace('geocode_cache_v2_'));
    DemoMode.pendingTutorial.addListener(_onPendingTutorial);
    NotificationService.pendingDestination.addListener(_onNotificationTap);
    // Drain any destination set before this listener was registered (e.g. a
    // cold-start tap that fired during main() before runApp was called).
    _onNotificationTap();
    // After a DemoMode transition the old MainNav's dispose() runs after this
    // initState — tearing down the subscription init() just created. The
    // post-frame callback re-subscribes once the frame has fully settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SalesStore.ensureSubscribed();
      BuyersStore.ensureSubscribed();
      RepairsStore.ensureSubscribed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DemoMode.pendingTutorial.removeListener(_onPendingTutorial);
    NotificationService.pendingDestination.removeListener(_onNotificationTap);
    SalesStore.dispose();
    BuyersStore.dispose();
    RepairsStore.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    SalesStore.ensureSubscribed();
    BuyersStore.ensureSubscribed();
    RepairsStore.ensureSubscribed();
  }

  void _onNotificationTap() {
    final destination = NotificationService.pendingDestination.value;
    if (destination == null) return;
    NotificationService.pendingDestination.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (destination) {
        case NotificationDestination.settings:
          setState(() => _currentIndex = 3);
        case NotificationDestination.salesList:
          setState(() => _currentIndex = 1);
      }
    });
  }

  void _onPendingTutorial() {
    if (!DemoMode.pendingTutorial.value) return;
    DemoMode.pendingTutorial.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DemoTutorialSheet.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: DemoMode.active,
        builder: (context, demoActive, child) => Column(
          children: [
            if (demoActive) _DemoBanner(),
            Expanded(
              child: demoActive
                  ? MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: child!,
                    )
                  : child!,
            ),
          ],
        ),
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            selectedIcon: const Icon(Icons.dashboard),
            icon: const Icon(Icons.dashboard_outlined),
            label: s.navDashboard,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.sell),
            icon: const Icon(Icons.sell_outlined),
            label: s.navSales,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.people),
            icon: const Icon(Icons.people_outline),
            label: s.navBuyers,
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.settings),
            icon: const Icon(Icons.settings_outlined),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final onContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: onContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.demoBanner,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onContainer,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.help_outline, size: 18, color: onContainer),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tooltip: s.demoTourTitle,
                onPressed: () => DemoTutorialSheet.show(context),
              ),
              TextButton(
                onPressed: DemoMode.exit,
                style: TextButton.styleFrom(
                  foregroundColor: onContainer,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(s.exitDemo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
