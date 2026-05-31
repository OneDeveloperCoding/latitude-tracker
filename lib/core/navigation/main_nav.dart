import 'package:flutter/material.dart';

import '../../features/buyers/screens/buyers_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
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
      body: IndexedStack(index: _currentIndex, children: _screens),
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
