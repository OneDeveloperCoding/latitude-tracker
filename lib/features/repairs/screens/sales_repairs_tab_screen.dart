import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../sales/models/sale_filter.dart';
import 'repairs_list_screen.dart';

class SalesRepairsTabScreen extends StatefulWidget {
  final Set<SaleFilter> initialSaleFilters;
  final bool startOnRepairs;

  const SalesRepairsTabScreen({
    super.key,
    this.initialSaleFilters = const {},
    this.startOnRepairs = false,
  });

  @override
  State<SalesRepairsTabScreen> createState() => _SalesRepairsTabScreenState();
}

class _SalesRepairsTabScreenState extends State<SalesRepairsTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnRepairs ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.navSales),
            Tab(text: s.repairs),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SalesListScreen(initialFilters: widget.initialSaleFilters),
              const RepairsListScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
