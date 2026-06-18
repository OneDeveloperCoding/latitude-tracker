import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/store/repairs_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/widgets/sheet_section_label.dart';
import 'package:latitude_tracker/core/widgets/store_error_widget.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/screens/new_repair_screen.dart';
import 'package:latitude_tracker/features/repairs/screens/repair_detail_screen.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_card.dart';

enum _SortOrder { newestFirst, oldestFirst }

class RepairsListScreen extends StatefulWidget {
  const RepairsListScreen({super.key});

  @override
  State<RepairsListScreen> createState() => _RepairsListScreenState();
}

class _RepairsListScreenState extends State<RepairsListScreen> {
  Repair? _selectedRepair;
  final _rightPanelKey = GlobalKey<NavigatorState>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchExpanded = false;
  _SortOrder _sortOrder = _SortOrder.newestFirst;
  Set<RepairStatus> _statusFilters = {};

  bool get _isWide => MediaQuery.sizeOf(context).width >= 700;

  int get _activeFilterCount =>
      _statusFilters.length + (_sortOrder != _SortOrder.newestFirst ? 1 : 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Repair> _applyFilter(List<Repair> all) {
    // Default (no chips selected): honour the domain's isActive flag so
    // fully-returned+delivered repairs are hidden, matching the old behaviour.
    if (_statusFilters.isEmpty) return all.where((r) => r.isActive).toList();
    return all.where((r) => _statusFilters.contains(r.status)).toList();
  }

  List<Repair> _applySearch(List<Repair> repairs) {
    if (_searchQuery.isEmpty) return repairs;
    final q = _searchQuery.toLowerCase();
    return repairs
        .where((r) =>
            r.contactName.toLowerCase().contains(q) ||
            r.itemDescription.toLowerCase().contains(q))
        .toList();
  }

  List<Repair> _applySort(List<Repair> repairs) {
    if (_sortOrder == _SortOrder.newestFirst) return repairs;
    final sorted = List<Repair>.from(repairs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ValueListenableBuilder<StoreState<List<Repair>>>(
      valueListenable: RepairsStore.state,
      builder: (context, state, _) {
        final isError = state is StoreError<List<Repair>>;
        final allRepairs = state is StoreLoaded<List<Repair>>
            ? state.data
            : <Repair>[];
        final isLoading = state is StoreLoading;
        final repairs = _applySort(_applySearch(_applyFilter(allRepairs)));

        // On wide layout, clear selection if the repair was deleted on another device.
        if (_selectedRepair != null && state is StoreLoaded<List<Repair>>) {
          if (!allRepairs.any((r) => r.id == _selectedRepair!.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedRepair = null);
            });
          }
        }

        final filterCount = _activeFilterCount;

        final listPanel = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(
                children: [
                  if (_searchExpanded)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: s.searchRepairs,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              setState(() => _searchExpanded = false);
                            },
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          _searchQuery = v;
                          setState(() {});
                        },
                      ),
                    )
                  else ...[
                    FilterChip(
                      avatar: const Icon(Icons.search, size: 18),
                      label: Text(s.searchRepairs),
                      onSelected: (_) => setState(() => _searchExpanded = true),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                  ],
                  Badge(
                    label: filterCount > 0 ? Text('$filterCount') : null,
                    isLabelVisible: filterCount > 0,
                    child: IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: s.moreFilters,
                      onPressed: _showOptionsSheet,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isError
                  ? StoreErrorWidget(
                      message: s.errorLoadingRepairs,
                      onRetry: RepairsStore.ensureSubscribed,
                    )
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : repairs.isEmpty
                          ? Center(
                              child: Text(
                                s.noRepairsFound,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                                          ?.pushReplacement(MaterialPageRoute<void>(
                                        builder: (_) => RepairDetailScreen(
                                            repairId: repair.id),
                                      ));
                                    } else {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute<void>(
                                        builder: (_) => RepairDetailScreen(
                                            repairId: repair.id),
                                      ));
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        );

        final fab = FloatingActionButton(
          heroTag: 'repair-fab',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewRepairScreen()),
          ),
          tooltip: s.newRepair,
          child: const Icon(Icons.add),
        );

        if (!_isWide) {
          return Scaffold(
            floatingActionButton: fab,
            body: listPanel,
          );
        }

        return Scaffold(
          floatingActionButton: fab,
          body: Row(
            children: [
              SizedBox(width: 380, child: listPanel),
              const VerticalDivider(width: 1),
              Expanded(
                child: isError || _selectedRepair == null
                    ? Center(
                        child: Text(
                          s.noRepairsFound,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Navigator(
                        key: _rightPanelKey,
                        onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (_) => RepairDetailScreen(
                            repairId: _selectedRepair!.id,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsSheet() {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          void refresh() {
            setState(() {});
            setSheetState(() {});
          }

          void clearAll() {
            _sortOrder = _SortOrder.newestFirst;
            _statusFilters = {};
            refresh();
          }

          final hasAnyActive =
              _sortOrder != _SortOrder.newestFirst || _statusFilters.isNotEmpty;

          return SafeArea(
            child: DraggableScrollableSheet(
              expand: false,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (_, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.filterSort,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (hasAnyActive)
                            TextButton(
                              onPressed: clearAll,
                              child: Text(s.clearAllFilters),
                            ),
                        ],
                      ),
                    ),
                    SheetSectionLabel(s.sortBy.toUpperCase()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: FilterChip(
                        label: Text(s.sortDimensionDate),
                        avatar: _sortOrder == _SortOrder.oldestFirst
                            ? const Icon(Icons.arrow_upward, size: 16)
                            : null,
                        selected: _sortOrder == _SortOrder.oldestFirst,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          _sortOrder = _sortOrder == _SortOrder.oldestFirst
                              ? _SortOrder.newestFirst
                              : _SortOrder.oldestFirst;
                          refresh();
                        },
                      ),
                    ),
                    const Divider(height: 24),
                    SheetSectionLabel(s.repairStatusLabel.toUpperCase()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: RepairStatus.values
                            .map((status) => FilterChip(
                                  label: Text(s.repairStatusLabelFor(status)),
                                  selected: _statusFilters.contains(status),
                                  onSelected: (on) {
                                    _statusFilters = on
                                        ? {..._statusFilters, status}
                                        : ({..._statusFilters}..remove(status));
                                    refresh();
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
