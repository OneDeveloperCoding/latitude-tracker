import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/repairs/screens/repairs_list_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale_filter.dart';
import 'package:latitude_tracker/features/sales/screens/sales_list_screen.dart';

class SalesRepairsTabScreen extends StatefulWidget {

  const SalesRepairsTabScreen({
    super.key,
    this.initialSaleFilters = const {},
    this.startOnRepairs = false,
  });
  final Set<SaleFilter> initialSaleFilters;
  final bool startOnRepairs;

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
    return SafeArea(
      bottom: false,
      child: Column(
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
      ),
    );
  }
}
