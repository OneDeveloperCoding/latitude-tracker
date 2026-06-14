import '../../../core/id_gen.dart';
import '../../../core/services/error_reporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants.dart';
import '../../../core/theme/color_scheme_ext.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/url_launch_service.dart';
import '../../../core/store/buyers_store.dart';
import '../../buyers/models/buyer.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../../buyers/screens/buyer_detail_screen.dart';
import '../../../core/store/repairs_store.dart';
import '../../../core/store/store_state.dart';
import '../../repairs/models/repair.dart';
import '../../repairs/screens/repair_detail_screen.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../services/sale_urgency_ui.dart';
import '../services/photo_service.dart';
import '../widgets/component_detail_sheet.dart';
import '../widgets/photo_grid.dart';
import 'new_sale_screen.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late final SaleRepository _repository;
  late final Stream<Sale?> _stream;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _repository = SaleRepository();
    _stream = _repository.watchSale(widget.saleId);
  }

  Future<void> _confirmDelete(BuildContext context, Sale sale) async {
    final s = context.s;
    final shipped = sale.shipment.status == ShipmentStatus.shipped ||
        sale.shipment.status == ShipmentStatus.delivered;
    final paid = sale.payment.status == PaymentStatus.paid;

    final totalPhotos =
        sale.items.fold(0, (acc, item) => acc + item.photoUrls.length);

    final String title;
    final String message;

    if (shipped) {
      title = s.deleteShippedSaleTitle;
      final statusLabel = sale.shipment.status == ShipmentStatus.delivered
          ? s.delivered
          : s.shippedStatus;
      message =
          s.deleteShippedSaleBody(statusLabel, sale.atSubmissionDone, totalPhotos);
    } else if (paid) {
      title = s.deletePaidSaleTitle;
      message = s.deletePaidSaleBody(sale.totalPrice, totalPhotos);
    } else {
      title = s.deleteSaleTitle;
      message = s.deleteSaleBody(totalPhotos);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _repository.deleteSale(sale.id);
      if (context.mounted) {
        setState(() => _popping = true);
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.errorDeletingSaleMsg(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Sale?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(context.s.errorLoadingDetail)),
            body: Center(child: Text(context.s.errorLoadingDetail)),
          );
        }
        final sale = snapshot.data;
        if (sale == null) {
          if (!_popping && snapshot.connectionState != ConnectionState.waiting) {
            _popping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          return Scaffold(
            appBar: AppBar(title: Text(context.s.saleFallbackTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(sale.buyerName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: context.s.editSale,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewSaleScreen(sale: sale),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: context.s.duplicateSaleTooltip,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NewSaleScreen(sale: sale, isDuplicate: true),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: context.s.deleteSaleTooltip,
                onPressed: () => _confirmDelete(context, sale),
              ),
            ],
          ),
          body: _SaleDetailBody(sale: sale, repository: _repository),
        );
      },
    );
  }
}

class _SaleDetailBody extends StatelessWidget {
  static final _dateFormat = DateFormat('dd MMM yyyy');

  final Sale sale;
  final SaleRepository repository;

  const _SaleDetailBody({required this.sale, required this.repository});

  Future<void> _update(BuildContext context, Sale updated) async {
    try {
      await repository.updateSale(updated);
    } catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.s.errorMsg(e))));
      }
    }
  }

  void _updateItem(BuildContext context, SaleItem updated) {
    final updatedItems = sale.items
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _update(context, sale.copyWith(items: updatedItems));
  }

  void _openItemDetail(BuildContext context, SaleItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemDetailSheet(
        saleId: sale.id,
        item: item,
        onUpdateItem: (updated) => _updateItem(context, updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        _InfoCard(children: [
          _InfoRow(
            icon: Icons.person,
            text: sale.buyerName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuyerDetailScreen(buyerId: sale.buyerId),
              ),
            ),
          ),
          _InfoRow(
            icon: Icons.calendar_today,
            text: _dateFormat.format(sale.createdAt),
          ),
          _InfoRow(
            icon: Icons.euro,
            text: '€${sale.totalPrice.toStringAsFixed(2)} · ${sale.items.length} ${sale.items.length == 1 ? 'item' : 'items'}',
          ),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionItems,
          child: Column(
            children: [
              ...sale.items.map((item) => _ItemSummaryTile(
                    item: item,
                    onTap: () => _openItemDetail(context, item),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionPayment,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.paymentMethodLabel(sale.payment.method)),
                  _StatusChip(
                    label: sale.payment.status == PaymentStatus.paid
                        ? s.paid
                        : s.unpaid,
                    color: sale.payment.status == PaymentStatus.paid
                        ? cs.success
                        : cs.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(s.markAsPaidLabel),
                value: sale.payment.status == PaymentStatus.paid,
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(
                    payment: sale.payment.copyWith(
                      status: v ? PaymentStatus.paid : PaymentStatus.unpaid,
                    ),
                  ),
                ),
              ),
              if (sale.requiresNif) ...[
                const Divider(height: 16),
                ValueListenableBuilder(
                  valueListenable: BuyersStore.state,
                  builder: (context, _, _) => _NifComplianceRow(
                    sale: sale,
                    repository: repository,
                    buyer: BuyersStore.current
                        ?.where((b) => b.id == sale.buyerId)
                        .firstOrNull,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: sale.shipment.type == DeliveryType.pickup
              ? s.readyBy
              : s.scheduledLabel,
          child: _ScheduledDateField(
            date: sale.scheduledDate,
            onChanged: (date) => _update(
              context,
              sale.copyWith(scheduledDate: date),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionDelivery,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(switch (sale.shipment.type) {
                    DeliveryType.shipping => s.shipping,
                    DeliveryType.pickup => s.inPersonPickup,
                    DeliveryType.handDelivery => s.handDelivery,
                  }),
                  _StatusChip(
                    label: s.shipmentStatusLabel(sale.shipment.status),
                    color: sale.shipment.status == ShipmentStatus.delivered
                        ? cs.success
                        : sale.shipment.status == ShipmentStatus.shipped
                            ? cs.shipped
                            : cs.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButton<ShipmentStatus>(
                value: sale.shipment.status,
                isExpanded: true,
                underline: const SizedBox(),
                items: _availableStatuses(sale.shipment)
                    .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(s.shipmentStatusLabel(status))))
                    .toList(),
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(
                      shipment: sale.shipment.copyWith(status: v)),
                ),
              ),
              if (sale.shipment.type == DeliveryType.shipping ||
                  sale.shipment.type == DeliveryType.handDelivery) ...[
                const SizedBox(height: 8),
                if (sale.shipment.addressId != null)
                  _AddressDisplay(
                    buyerId: sale.buyerId,
                    addressId: sale.shipment.addressId!,
                    postalCode: sale.shipment.postalCode,
                  )
                else if (sale.shipment.postalCode != null)
                  _InfoRow(
                    icon: Icons.location_on,
                    text: sale.shipment.postalCode!,
                  ),
                if (sale.shipment.type == DeliveryType.shipping)
                _TrackingCodeField(
                  initialValue: sale.shipment.trackingCode ?? '',
                  onSave: (code) => _update(
                    context,
                    sale.copyWith(
                        shipment: sale.shipment.copyWith(
                      trackingCode: code.isEmpty ? null : code,
                    )),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RepairsSection(saleId: sale.id),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionNotes,
          child: _NotesField(
            initialValue: sale.notes ?? '',
            onSave: (text) => _update(
              context,
              sale.copyWith(notes: text.isEmpty ? null : text),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<ShipmentStatus> _availableStatuses(SaleShipment shipment) {
    if (shipment.type == DeliveryType.pickup ||
        shipment.type == DeliveryType.handDelivery) {
      return [ShipmentStatus.pending, ShipmentStatus.delivered];
    }
    return ShipmentStatus.values;
  }
}

class _ItemSummaryTile extends StatelessWidget {
  final SaleItem item;
  final VoidCallback onTap;

  const _ItemSummaryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.assemblyStatus.colorOf(Theme.of(context).colorScheme);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: item.photoUrls.isNotEmpty
          ? PhotoThumbnail(
              url: item.photoUrls.first,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewer(
                    urls: item.photoUrls,
                    initialIndex: 0,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        item.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(item.category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '€${item.price.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Icon(Icons.circle, size: 10, color: statusColor),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }

}

// Bottom sheet shown when tapping a SaleItem in the detail view.
class _ItemDetailSheet extends StatefulWidget {
  final String saleId;
  final SaleItem item;
  final ValueChanged<SaleItem> onUpdateItem;

  const _ItemDetailSheet({
    required this.saleId,
    required this.item,
    required this.onUpdateItem,
  });

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  final _componentController = TextEditingController();
  final _photoService = PhotoService();
  // Tracks URLs of component photos uploaded while this sheet is open, so
  // orphans can be deleted if the sheet is dismissed before onChanged fires.
  final _sessionComponentUploads = <String>{};
  late SaleItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _componentController.dispose();
    final committedUrls = {
      for (final c in _item.components) ...c.photoUrls,
    };
    for (final url in _sessionComponentUploads) {
      if (!committedUrls.contains(url)) {
        // Upload landed in Storage but the sheet was dismissed before the
        // Firestore write confirmed — delete the orphan best-effort.
        _photoService.deletePhoto(url);
      }
    }
    super.dispose();
  }

  void _toggleComponent(ComponentItem c) {
    final updated = _item.withUpdatedComponents(
      _item.components
          .map((ci) =>
              ci.id == c.id ? ci.copyWith(isAvailable: !c.isAvailable) : ci)
          .toList(),
    );
    setState(() => _item = updated);
    widget.onUpdateItem(updated);
  }

  // Void (not async) so Dismissible.onDismissed can call it without
  // discarding a Future. Firestore write happens first for consistency;
  // Storage deletes follow as acknowledged fire-and-forget.
  void _removeComponent(ComponentItem c) {
    final updated = _item.withUpdatedComponents(
      _item.components.where((ci) => ci.id != c.id).toList(),
    );
    setState(() => _item = updated);
    widget.onUpdateItem(updated);
    for (final url in c.photoUrls) {
      _photoService.deletePhoto(url);
    }
  }

  Future<void> _openComponentSheet(ComponentItem c) async {
    await showComponentDetailSheet(
      context,
      component: c,
      saleId: widget.saleId,
      itemId: _item.id,
      onChanged: (updated) {
        final newItem = _item.withUpdatedComponents(
          _item.components
              .map((ci) => ci.id == updated.id ? updated : ci)
              .toList(),
        );
        setState(() => _item = newItem);
        widget.onUpdateItem(newItem);
      },
      onPhotoAdded: (url) => _sessionComponentUploads.add(url),
      onPhotoRemoved: (url) {
        _sessionComponentUploads.remove(url);
        _photoService.deletePhoto(url);
      },
    );
  }

  void _addComponent() {
    final name = _componentController.text.trim();
    if (name.isEmpty) return;
    final updated = _item.withUpdatedComponents([
      ..._item.components,
      ComponentItem(
        id: newId(),
        name: name,
        isAvailable: false,
      ),
    ]);
    setState(() {
      _item = updated;
      _componentController.clear();
    });
    widget.onUpdateItem(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            _item.description,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${_item.category} · €${_item.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Text(s.assemblyStatusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 8),
          DropdownButton<AssemblyStatus>(
            value: _item.assemblyStatus,
            isExpanded: true,
            underline: const SizedBox(),
            items: AssemblyStatus.values
                .map((st) => DropdownMenuItem(
                    value: st, child: Text(s.assemblyLabel(st))))
                .toList(),
            onChanged: (v) =>
                widget.onUpdateItem(_item.copyWith(assemblyStatus: v)),
          ),
          if (_item.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.sectionPhotos,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 8),
            PhotoGrid(
              saleId: widget.saleId,
              itemId: _item.id,
              photoUrls: _item.photoUrls,
              onChanged: (urls) =>
                  widget.onUpdateItem(_item.copyWith(photoUrls: urls)),
            ),
          ],
          const SizedBox(height: 16),
          Text(s.sectionComponents,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 4),
          ..._item.components.map((c) => Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _removeComponent(c),
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name),
                  subtitle:
                      Text(c.isAvailable ? s.haveIt : s.needToBuy),
                  value: c.isAvailable,
                  onChanged: (_) => _toggleComponent(c),
                  secondary: ComponentPhotoBadge(
                    count: c.photoUrls.length,
                    onTap: () => _openComponentSheet(c),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _componentController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: s.addComponentHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addComponent(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addComponent,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingCodeField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _TrackingCodeField({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_TrackingCodeField> createState() => _TrackingCodeFieldState();
}

class _TrackingCodeFieldState extends State<_TrackingCodeField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addCttTracking),
      );
    }

    if (_editing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.cttTrackingLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSave(_controller.text.trim());
              setState(() => _editing = false);
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.local_shipping, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyCode(context),
            onLongPress: () => _openCttTracking(_controller.text),
            child: Text(
              _controller.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share, size: 16),
          tooltip: s.shareTracking,
          onPressed: _shareTracking,
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new, size: 16),
          tooltip: s.openOnCtt,
          onPressed: () => _openCttTracking(_controller.text),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }

  Uri _cttUri(String code) => Uri.parse(
        'https://www.ctt.pt/feapl_2/app/open/objectSearch/objectSearch.jspx?codObjeto=$code',
      );

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.trackingCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareTracking() async {
    final code = _controller.text;
    final url = _cttUri(code);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Olá! O teu envio tem o código de rastreamento $code.'
            ' Podes acompanhar aqui: $url',
      ),
    );
  }

  Future<void> _openCttTracking(String code) async {
    final uri = _cttUri(code);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ScheduledDateField extends StatelessWidget {
  static final _dateFormat = DateFormat('EEE, dd MMM yyyy');

  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _ScheduledDateField({required this.date, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final first = DateTime(DateTime.now().year - 5);
    final last = DateTime(DateTime.now().year + 2, 12, 31);
    final initial = date == null
        ? DateTime.now()
        : date!.isBefore(first)
            ? first
            : date!.isAfter(last)
                ? last
                : date!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (date == null) {
      return TextButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event),
        label: Text(s.setScheduledDate),
      );
    }
    return Row(
      children: [
        const Icon(Icons.event, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(_dateFormat.format(date!))),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(s.change),
        ),
        TextButton(
          onPressed: () => onChanged(null),
          child: Text(s.clear),
        ),
      ],
    );
  }
}

class _AddressDisplay extends StatefulWidget {
  final String buyerId;
  final String addressId;
  final String? postalCode;

  const _AddressDisplay({
    required this.buyerId,
    required this.addressId,
    this.postalCode,
  });

  @override
  State<_AddressDisplay> createState() => _AddressDisplayState();
}

class _AddressDisplayState extends State<_AddressDisplay> {
  late Stream<List<BuyerAddress>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = BuyerRepository().watchAddresses(widget.buyerId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BuyerAddress>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.postalCode != null
              ? _InfoRow(icon: Icons.location_on, text: widget.postalCode!)
              : const SizedBox.shrink();
        }
        final address = snapshot.data
            ?.where((a) => a.id == widget.addressId)
            .firstOrNull;
        if (address == null) {
          return widget.postalCode != null
              ? _InfoRow(icon: Icons.location_on, text: widget.postalCode!)
              : const SizedBox.shrink();
        }
        return _InfoRow(
          icon: Icons.location_on,
          text: [
            if (address.street.isNotEmpty) address.street,
            if (address.houseNumber.isNotEmpty) address.houseNumber,
            if (address.fraction != null) address.fraction!,
            '${address.postalCode} ${address.city}',
            address.country,
          ].join(', '),
          trailing: address.hasMapsAddress
              ? IconButton(
                  icon: const Icon(Icons.location_on, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _launchMaps(context, address),
                )
              : null,
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _NifComplianceRow extends StatelessWidget {
  final Sale sale;
  final SaleRepository repository;
  final Buyer? buyer;

  const _NifComplianceRow({required this.sale, required this.repository, required this.buyer});

  Future<void> _toggleAt(BuildContext context) async {
    try {
      await repository.updateSale(
          sale.copyWith(atSubmissionDone: !sale.atSubmissionDone));
    } catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.s.errorMsg(e))));
      }
    }
  }

  Future<void> _showAddNifDialog(BuildContext context, Buyer buyer) async {
    final s = context.s;
    final controller = TextEditingController(text: buyer.nif ?? '');
    final formKey = GlobalKey<FormState>();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.nifLabel),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 9,
              autofocus: true,
              decoration: InputDecoration(labelText: s.nifLabel),
              validator: (v) =>
                  (v == null || v.length != 9) ? s.nifInvalid : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(s.save),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      await BuyerRepository()
          .updateBuyer(buyer.copyWith(nif: controller.text.trim()));
    } catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.s.errorMsg(e))));
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    final isPaid = sale.payment.status == PaymentStatus.paid;
    final hasNif = buyer?.nif?.isNotEmpty == true;

    final String label;
    Widget? trailing;

    if (!hasNif) {
      label = s.noNifOnFile;
      trailing = buyer != null
          ? TextButton(
              onPressed: () => _showAddNifDialog(context, buyer!),
              child: Text(s.addNif),
            )
          : null;
    } else if (!isPaid) {
      label = s.nifReceiptRequiredInfo;
    } else {
      label = sale.atSubmissionDone ? s.atReceiptFiled : s.atReceiptPending;
      trailing = IconButton(
        icon: Icon(
          sale.atSubmissionDone
              ? Icons.check_circle
              : Icons.check_circle_outline,
          color: sale.atSubmissionDone ? cs.success : cs.warning,
        ),
        tooltip: sale.atSubmissionDone ? s.markAsPending : s.markAsFiled,
        onPressed: () => _toggleAt(context),
      );
    }

    return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(kNifIcon,
              size: 20, color: Theme.of(context).colorScheme.primary),
          title: Text(label),
          trailing: trailing,
        );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _InfoRow({required this.icon, required this.text, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(4), child: row);
  }
}

Future<void> _launchMaps(BuildContext context, BuyerAddress address) =>
    launchMapsUrl(context, address.mapsUri);

class _NotesField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _NotesField({required this.initialValue, required this.onSave});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addNotes),
      );
    }

    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: s.notesHintDetail,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.text = widget.initialValue;
                  setState(() => _editing = false);
                },
                child: Text(s.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  widget.onSave(_controller.text.trim());
                  setState(() => _editing = false);
                },
                child: Text(s.save),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(_controller.text)),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RepairsSection extends StatelessWidget {
  final String saleId;

  const _RepairsSection({required this.saleId});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ValueListenableBuilder<StoreState<List<Repair>>>(
      valueListenable: RepairsStore.state,
      builder: (context, storeState, _) {
        if (storeState is StoreError<List<Repair>>) {
          return _SectionCard(
            title: s.repairsOnSale,
            child: Text(s.errorLoadingRepairs,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          );
        }
        if (storeState is StoreLoading<List<Repair>>) {
          return _SectionCard(
            title: s.repairsOnSale,
            child: const LinearProgressIndicator(),
          );
        }
        if (storeState is! StoreLoaded<List<Repair>>) {
          return const SizedBox.shrink();
        }
        final repairs = storeState.data
            .where((r) => r.linkedSaleId == saleId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (repairs.isEmpty) return const SizedBox.shrink();

        return _SectionCard(
          title: s.repairsOnSale,
          child: Column(
            children: repairs
                .map((repair) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.build_outlined),
                      title: Text(repair.itemDescription),
                      subtitle: Text(
                          '${repair.contactName} · ${s.repairStatusLabelFor(repair.status)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RepairDetailScreen(repairId: repair.id),
                        ),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
