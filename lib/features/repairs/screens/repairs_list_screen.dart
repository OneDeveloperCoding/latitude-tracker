import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/repairs_store.dart';
import '../../../core/store/store_state.dart';
import '../models/repair.dart';
import '../widgets/repair_card.dart';
import 'new_repair_screen.dart';
import 'repair_detail_screen.dart';

class RepairsListScreen extends StatefulWidget {
  const RepairsListScreen({super.key});

  @override
  State<RepairsListScreen> createState() => _RepairsListScreenState();
}

class _RepairsListScreenState extends State<RepairsListScreen> {
  Repair? _selectedRepair;
  final _rightPanelKey = GlobalKey<NavigatorState>();

  bool _showAll = false;

  bool get _isWide => MediaQuery.sizeOf(context).width >= 700;

  List<Repair> _filterRepairs(List<Repair> all) {
    if (_showAll) return all;
    return all.where((r) => r.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ValueListenableBuilder<StoreState<List<Repair>>>(
      valueListenable: RepairsStore.state,
      builder: (context, state, _) {
        final repairs = state is StoreLoaded<List<Repair>>
            ? _filterRepairs(state.data)
            : <Repair>[];
        final isLoading = state is StoreLoading;

        if (_isWide) {
          return Row(
            children: [
              SizedBox(
                width: 380,
                child: _buildList(context, s, repairs, isLoading),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _selectedRepair == null
                    ? Center(
                        child: Text(
                          s.noRepairsFound,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Navigator(
                        key: _rightPanelKey,
                        onGenerateRoute: (_) => MaterialPageRoute(
                          builder: (_) => RepairDetailScreen(
                            repairId: _selectedRepair!.id,
                          ),
                        ),
                      ),
              ),
            ],
          );
        }

        return _buildList(context, s, repairs, isLoading);
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    AppStrings s,
    List<Repair> repairs,
    bool isLoading,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(s.repairs),
        actions: [
          IconButton(
            icon: Icon(_showAll ? Icons.filter_list_off : Icons.filter_list),
            tooltip: _showAll ? 'Active only' : 'Show all',
            onPressed: () => setState(() => _showAll = !_showAll),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : repairs.isEmpty
              ? Center(
                  child: Text(
                    s.noRepairsFound,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: repairs.length,
                  itemBuilder: (context, i) {
                    final repair = repairs[i];
                    return RepairCard(
                      repair: repair,
                      selected: _selectedRepair?.id == repair.id,
                      onTap: () {
                        if (_isWide) {
                          setState(() => _selectedRepair = repair);
                          _rightPanelKey.currentState
                              ?.pushReplacement(MaterialPageRoute(
                            builder: (_) =>
                                RepairDetailScreen(repairId: repair.id),
                          ));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                RepairDetailScreen(repairId: repair.id),
                          ));
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'repair-fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NewRepairScreen(),
          ),
        ),
        tooltip: s.newRepair,
        child: const Icon(Icons.add),
      ),
    );
  }
}
