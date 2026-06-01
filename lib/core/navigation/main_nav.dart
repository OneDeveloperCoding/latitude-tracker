import 'package:flutter/material.dart';

import '../../features/buyers/screens/buyers_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/demo/demo_mode.dart';
import '../../features/sales/screens/sales_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: DemoMode.active,
        builder: (context, demoActive, child) => Column(
          children: [
            if (demoActive) _DemoBanner(),
            Expanded(child: child!),
          ],
        ),
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.sell), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Buyers'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo mode — changes are not saved',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => DemoMode.exit(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Exit demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
