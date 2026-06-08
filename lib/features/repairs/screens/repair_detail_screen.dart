import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/id_gen.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/services/error_reporter.dart';
import '../../../core/store/sales_store.dart';
import '../../buyers/models/buyer.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../../buyers/screens/buyer_detail_screen.dart';
import '../../demo/demo_mode.dart';
import '../../sales/models/sale.dart';
import '../../sales/screens/sale_detail_screen.dart';
import '../../sales/widgets/photo_grid.dart';
import '../models/repair.dart';
import '../repositories/repair_repository.dart';
import 'new_repair_screen.dart';

class RepairDetailScreen extends StatefulWidget {
  final String repairId;

  const RepairDetailScreen({super.key, required this.repairId});

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
    } catch (e) {
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
          if (!_popping && snapshot.connectionState != ConnectionState.waiting) {
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
  final Repair repair;
  final Future<void> Function(BuildContext, Repair) onDelete;

  const _RepairDetailBody({required this.repair, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(repair.itemDescription),
        actions: [
          if (!DemoMode.active.value) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: s.edit,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewRepairScreen(existing: repair),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: s.deleteRepair,
              onPressed: () => onDelete(context, repair),
            ),
          ],
        ],
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
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: s.repairSectionWork,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.build_outlined),
                title: Text(s.repairStatusLabelFor(repair.status)),
                subtitle: Text(s.repairStatusLabel),
              ),
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
                                MaterialPageRoute(
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${s.receivedLabel}: ${DateFormat('d MMM y').format(repair.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

}

class _ContactRow extends StatelessWidget {
  final Repair repair;

  const _ContactRow({required this.repair});

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
          MaterialPageRoute(
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
        freeTextContact: null,
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorSavingRepair)),
        );
      }
    }
  }
}

class _LinkedSaleRow extends StatelessWidget {
  final String saleId;

  const _LinkedSaleRow({required this.saleId});

  @override
  Widget build(BuildContext context) {
    final sale = (SalesStore.current ?? [])
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
        MaterialPageRoute(
          builder: (_) => SaleDetailScreen(saleId: saleId),
        ),
      ),
    );
  }
}


class _ReturnDeliveryActions extends StatefulWidget {
  final Repair repair;

  const _ReturnDeliveryActions({required this.repair});

  @override
  State<_ReturnDeliveryActions> createState() => _ReturnDeliveryActionsState();
}

class _ReturnDeliveryActionsState extends State<_ReturnDeliveryActions> {
  bool _isUpdating = false;

  Future<void> _advance() async {
    // Snapshot before any await so the write is consistent with what was rendered.
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
    } catch (e, st) {
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
    if (delivery.status == ShipmentStatus.delivered) return const SizedBox.shrink();

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
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
