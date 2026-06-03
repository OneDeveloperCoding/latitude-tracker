import 'package:flutter/material.dart';

import '../../features/buyers/screens/buyers_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/demo/demo_mode.dart';
import '../../features/demo/demo_tutorial_sheet.dart';
import '../../features/heat_map/services/geocoding_service.dart';
import '../../features/heat_map/services/heat_map_service.dart';
import '../../features/sales/screens/sales_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../l10n/app_strings.dart';
import '../store/buyers_store.dart';
import '../store/sales_store.dart';
import '../store/store_state.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    SalesListScreen(),
    BuyersListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SalesStore.init();
    BuyersStore.init();
    DemoMode.pendingTutorial.addListener(_onPendingTutorial);
    SalesStore.state.addListener(_onSalesStoreChanged);
  }

  @override
  void dispose() {
    DemoMode.pendingTutorial.removeListener(_onPendingTutorial);
    SalesStore.state.removeListener(_onSalesStoreChanged);
    SalesStore.dispose();
    BuyersStore.dispose();
    super.dispose();
  }

  // Geocode heat map prefixes in the background whenever the sales list
  // changes. Already-cached prefixes return immediately from memory, so
  // re-runs on incremental updates are cheap. Only genuinely new CP4 prefixes
  // (new shipped sales) trigger a Nominatim request.
  void _onSalesStoreChanged() {
    final state = SalesStore.state.value;
    if (state is! StoreLoaded<List>) return;
    final sales = SalesStore.current;
    if (sales == null || sales.isEmpty) return;
    final prefixes = HeatMapService.postalCounts(sales).keys;
    GeocodingService.warmUp(prefixes);
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
                onPressed: () => DemoMode.exit(),
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
