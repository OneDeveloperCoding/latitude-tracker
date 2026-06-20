import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/id_gen.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_detail_screen.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';
import 'package:latitude_tracker/features/repairs/screens/new_repair_screen.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_colors.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_dots.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sale_detail_screen.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart';
import 'package:latitude_tracker/features/sales/widgets/sale_status_dots.dart';

class RepairDetailScreen extends StatefulWidget {

  const RepairDetailScreen({required this.repairId, super.key});
  final String repairId;

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  late final RepairRepository _repository;
  late final Stream<Repair?> _stream;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _repository = RepairRepository();
    _stream = _repository.watchRepair(widget.repairId);
  }

  Future<void> _confirmDelete(BuildContext context, Repair repair) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteRepairTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _repository.deleteRepair(repair.id);
      if (context.mounted) {
        setState(() => _popping = true);
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.errorDeletingRepair}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Repair?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.s.errorLoadingDetail)),
          );
        }
        final repair = snapshot.data;
        if (repair == null) {
          if (!_popping &&
              snapshot.connectionState != ConnectionState.waiting) {
            _popping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return _RepairDetailBody(repair: repair, onDelete: _confirmDelete);
      },
    );
  }
}

class _RepairDetailBody extends StatelessWidget {

  const _RepairDetailBody({required this.repair, required this.onDelete});
  final Repair repair;
  final Future<void> Function(BuildContext, Repair) onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(repair.itemDescription),
        actions: [
          if (!DemoMode.active.value)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: s.deleteRepair,
              onPressed: () => onDelete(context, repair),
            ),
        ],
      ),
      floatingActionButton: DemoMode.active.value
          ? null
          : FloatingActionButton(
              tooltip: s.edit,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NewRepairScreen(existing: repair),
                ),
              ),
              child: const Icon(Icons.edit),
            ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _SectionCard(
            title: s.repairSectionContact,
            children: [
              _ContactRow(repair: repair),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.repairSectionItem,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(repair.itemDescription),
                subtitle: Text(repair.itemCategory),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(repair.problemDescription),
                subtitle: Text(s.repairProblemLabel),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd MMM yyyy').format(repair.createdAt)),
                subtitle: Text(s.receivedLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.repairSectionWork,
            indicator: repairWorkDot(repair.status, colorScheme),
            children: [
              _RepairStatusPicker(repair: repair),
              if (repair.workDone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(repair.workDone),
                  subtitle: Text(s.repairWorkDone),
                ),
              if (repair.materialsCost != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handyman_outlined),
                  title: Text(
                      '€${repair.materialsCost!.toStringAsFixed(2)}'),
                  subtitle: Text(s.repairMaterialsCost),
                ),
            ],
          ),
          if (repair.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: s.sectionPhotos,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: repair.photoUrls
                        .asMap()
                        .entries
                        .map((e) => PhotoThumbnail(
                              url: e.value,
                              size: 80,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => PhotoViewer(
                                    urls: repair.photoUrls,
                                    initialIndex: e.key,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _SectionCard(
            title: s.sectionPayment,
            indicator: paymentDot(repair.payment, colorScheme),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  repair.payment.status == PaymentStatus.paid
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: repair.payment.status == PaymentStatus.paid
                      ? Colors.green
                      : colorScheme.error,
                ),
                title: Text(repair.payment.status == PaymentStatus.paid
                    ? s.paid
                    : s.unpaid),
                subtitle:
                    Text(s.paymentMethodLabel(repair.payment.method)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.repairSectionReturn,
            indicator: contextualReturnDeliveryDot(repair, colorScheme),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(switch (repair.returnDelivery.type) {
                  DeliveryType.shipping => s.shipping,
                  DeliveryType.pickup => s.inPersonPickup,
                  DeliveryType.handDelivery => s.handDelivery,
                }),
                subtitle: Text(
                    s.shipmentStatusLabel(repair.returnDelivery.status)),
              ),
              if (repair.returnDelivery.trackingCode != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.qr_code),
                  title: Text(repair.returnDelivery.trackingCode!),
                  subtitle: Text(s.cttTrackingLabel),
                ),
              if (!DemoMode.active.value)
                _ReturnDeliveryActions(repair: repair),
            ],
          ),
          if (repair.linkedSaleId != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: s.repairSectionLinked,
              children: [
                _LinkedSaleRow(saleId: repair.linkedSaleId!),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

class _ContactRow extends StatelessWidget {

  const _ContactRow({required this.repair});
  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (repair.isLinkedToBuyer) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: Text(repair.contactName),
        subtitle: Text(s.buyer),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BuyerDetailScreen(buyerId: repair.buyerId!),
          ),
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(repair.contactName),
      subtitle: Text(s.repairContactFreeText),
      trailing: DemoMode.active.value
          ? null
          : TextButton(
              onPressed: () => _promoteToBuyer(context),
              child: Text(s.promoteToBuyer),
            ),
    );
  }

  Future<void> _promoteToBuyer(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.promoteToBuyerTitle),
        content: Text(s.promoteToBuyerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.promoteToBuyer),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final newBuyer = Buyer(
        id: newId(),
        name: repair.freeTextContact!,
        createdAt: DateTime.now(),
      );
      await BuyerRepository().createBuyer(newBuyer);

      // Update repair to link to the new buyer
      final updated = Repair(
        id: repair.id,
        buyerId: newBuyer.id,
        buyerName: newBuyer.name,
        linkedSaleId: repair.linkedSaleId,
        itemDescription: repair.itemDescription,
        itemCategory: repair.itemCategory,
        problemDescription: repair.problemDescription,
        workDone: repair.workDone,
        materialsCost: repair.materialsCost,
        status: repair.status,
        payment: repair.payment,
        returnDelivery: repair.returnDelivery,
        photoUrls: repair.photoUrls,
        createdAt: repair.createdAt,
      );
      await RepairRepository().updateRepair(updated);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.promotedToBuyerMsg(newBuyer.name))),
        );
      }
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorSavingRepair)),
        );
      }
    }
  }
}

class _LinkedSaleRow extends StatelessWidget {

  const _LinkedSaleRow({required this.saleId});
  final String saleId;

  @override
  Widget build(BuildContext context) {
    final sale = SalesStore.currentOrEmpty
        .where((s) => s.id == saleId)
        .firstOrNull;
    final title = sale != null
        ? '${sale.buyerName} — ${sale.items.first.description}'
        : saleId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.sell_outlined),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SaleDetailScreen(saleId: saleId),
        ),
      ),
    );
  }
}


class _RepairStatusPicker extends StatefulWidget {

  const _RepairStatusPicker({required this.repair});
  final Repair repair;

  @override
  State<_RepairStatusPicker> createState() => _RepairStatusPickerState();
}

class _RepairStatusPickerState extends State<_RepairStatusPicker> {
  bool _isUpdating = false;
  RepairStatus? _optimisticStatus;

  @override
  void didUpdateWidget(_RepairStatusPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the stream confirms any status change, the optimistic guess is no
    // longer needed — trust widget.repair.status again so later changes from
    // other flows (auto-advance on delivery, the edit form, another device)
    // aren't masked by a stale local override.
    if (widget.repair.status != oldWidget.repair.status) {
      _optimisticStatus = null;
    }
  }

  Future<void> _select(RepairStatus status) async {
    final repair = widget.repair;
    if (status == repair.status) return;

    setState(() {
      _optimisticStatus = status;
      _isUpdating = true;
    });
    try {
      await RepairRepository().updateRepair(repair.copyWith(status: status));
    } on Object catch (e, st) {
      logError(e, st);
      if (mounted) {
        setState(() => _optimisticStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingRepair)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _statusLabelRow(AppStrings s) {
    return Row(
      children: [
        Text(s.repairStatusLabel, style: Theme.of(context).textTheme.bodySmall),
        if (_isUpdating) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _statusChipsWrap(AppStrings s, ColorScheme cs) {
    final selectedStatus = _optimisticStatus ?? widget.repair.status;
    final chipsDisabled = DemoMode.active.value || _isUpdating;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RepairStatus.values.map((status) {
        final (color, onColor) = repairStatusContainerColors(status, cs);
        final isSelected = status == selectedStatus;
        return ChoiceChip(
          label: Text(s.repairStatusLabelFor(status)),
          selected: isSelected,
          onSelected: chipsDisabled ? null : (_) => _select(status),
          selectedColor: color,
          labelStyle: isSelected ? TextStyle(color: onColor) : null,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _statusLabelRow(s),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _statusChipsWrap(s, cs),
        ),
      ],
    );
  }
}

class _ReturnDeliveryActions extends StatefulWidget {

  const _ReturnDeliveryActions({required this.repair});
  final Repair repair;

  @override
  State<_ReturnDeliveryActions> createState() => _ReturnDeliveryActionsState();
}

class _ReturnDeliveryActionsState extends State<_ReturnDeliveryActions> {
  bool _isUpdating = false;

  Future<void> _advance() async {
    // Snapshot before any await so the write is consistent with what was
    // rendered.
    final repair = widget.repair;
    final delivery = repair.returnDelivery;
    final nextStatus = delivery.type == DeliveryType.shipping &&
            delivery.status == ShipmentStatus.pending
        ? ShipmentStatus.shipped
        : ShipmentStatus.delivered;

    setState(() => _isUpdating = true);
    try {
      await RepairRepository().updateRepair(
        repair.copyWith(
          returnDelivery: delivery.copyWith(status: nextStatus),
          // Completing delivery marks the repair as returned so isActive flips.
          status: nextStatus == ShipmentStatus.delivered
              ? RepairStatus.returned
              : null,
        ),
      );
    } on Object catch (e, st) {
      logError(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingRepair)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;
    if (repair.status != RepairStatus.done &&
        repair.status != RepairStatus.returned) {
      return const SizedBox.shrink();
    }

    final delivery = repair.returnDelivery;
    if (delivery.status == ShipmentStatus.delivered) {
      return const SizedBox.shrink();
    }

    final s = context.s;
    final isShippingPending = delivery.type == DeliveryType.shipping &&
        delivery.status == ShipmentStatus.pending;
    final label = isShippingPending ? s.markAsSent : s.markAsDelivered;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: FilledButton.tonal(
          onPressed: _isUpdating ? null : _advance,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {

  const _SectionCard({
    required this.title,
    required this.children,
    this.indicator,
  });
  final String title;
  final List<Widget> children;
  final StatusIndicatorDot? indicator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (indicator != null) ...[
                  Icon(indicator!.icon, size: 16, color: indicator!.color),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
