import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/constants.dart';
import 'package:latitude_tracker/core/id_gen.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/services/url_launch_service.dart';
import 'package:latitude_tracker/core/store/buyers_store.dart';
import 'package:latitude_tracker/core/store/repairs_store.dart';
import 'package:latitude_tracker/core/store/store_state.dart';
import 'package:latitude_tracker/core/theme/color_scheme_ext.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_address_form_screen.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_detail_screen.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/screens/repair_detail_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/sales/screens/new_sale_screen.dart';
import 'package:latitude_tracker/features/sales/screens/sale_item_screen.dart';
import 'package:latitude_tracker/features/sales/services/photo_service.dart';
import 'package:latitude_tracker/features/sales/services/sale_urgency_ui.dart';
import 'package:latitude_tracker/features/sales/widgets/component_detail_sheet.dart';
import 'package:latitude_tracker/features/sales/widgets/payment_method_display.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart';
import 'package:latitude_tracker/features/sales/widgets/sale_status_dots.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SaleDetailScreen extends StatefulWidget {
  const SaleDetailScreen({
    required this.saleId,
    this.editModeSignal,
    super.key,
  });

  final String saleId;

  /// Incrementing this notifier from outside (e.g. tablet FAB) triggers edit
  /// mode on the currently displayed sale.
  final ValueNotifier<int>? editModeSignal;

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  // ── stream ─────────────────────────────────────────────────────────────────
  late final SaleRepository _repository;
  late final Stream<Sale?> _stream;
  bool _popping = false;
  Sale? _lastKnownSale;

  // ── edit mode ──────────────────────────────────────────────────────────────
  final _photoService = PhotoService();
  bool _isEditing = false;
  bool _isSaving = false;

  // Buffer populated from the sale snapshot when entering edit mode.
  String _editBuyerId = '';
  String _editBuyerName = '';
  Set<String> _originalItemIds = {};
  List<SaleItem> _editItems = [];
  List<String> _pendingDeletions = [];

  PaymentMethod _editPaymentMethod = PaymentMethod.mbWay;
  PaymentStatus _editPaymentStatus = PaymentStatus.unpaid;
  bool _editRequiresNif = false;
  bool _editAtSubmissionDone = false;

  DeliveryType _editDeliveryType = DeliveryType.shipping;
  ShipmentStatus _editShipmentStatus = ShipmentStatus.pending;
  DateTime? _editShippedAt;
  List<BuyerAddress> _buyerAddresses = [];
  BuyerAddress? _editSelectedAddress;
  final _editTrackingCodeController = TextEditingController();
  final _editPostalCodeController = TextEditingController();

  DateTime? _editScheduledDate;
  final _editNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = SaleRepository();
    _stream = _repository.watchSale(widget.saleId);
    widget.editModeSignal?.addListener(_onEditModeSignal);
  }

  @override
  void dispose() {
    widget.editModeSignal?.removeListener(_onEditModeSignal);
    _editTrackingCodeController.dispose();
    _editPostalCodeController.dispose();
    _editNotesController.dispose();
    super.dispose();
  }

  void _onEditModeSignal() {
    final sale = _lastKnownSale;
    if (sale == null || _isEditing) return;
    _enterEditMode(sale);
  }

  // ── edit lifecycle ────────────────────────────────────────────────────────

  void _enterEditMode(Sale sale) {
    setState(() {
      _isEditing = true;
      _editBuyerId = sale.buyerId;
      _editBuyerName = sale.buyerName;
      _originalItemIds = {for (final i in sale.items) i.id};
      _editItems = List.from(sale.items);
      _pendingDeletions = [];

      _editPaymentMethod = sale.payment.method;
      _editPaymentStatus = sale.payment.status;
      _editRequiresNif = sale.requiresNif;
      _editAtSubmissionDone = sale.atSubmissionDone;

      _editDeliveryType = sale.shipment.type;
      _editShipmentStatus = sale.shipment.status;
      _editShippedAt = sale.shipment.shippedAt;
      _editSelectedAddress = null;
      _editTrackingCodeController.text = sale.shipment.trackingCode ?? '';
      _editPostalCodeController.text = sale.shipment.postalCode ?? '';

      _editScheduledDate = sale.scheduledDate;
      _editNotesController.text = sale.notes ?? '';
    });
    unawaited(_loadBuyerAddresses(sale.buyerId, sale.shipment.addressId));
  }

  Future<void> _loadBuyerAddresses(
      String buyerId, String? currentAddressId) async {
    try {
      final addresses =
          await BuyerRepository().watchAddresses(buyerId).first;
      if (!mounted) return;
      final current =
          addresses.where((a) => a.id == currentAddressId).firstOrNull;
      setState(() {
        _buyerAddresses = addresses;
        _editSelectedAddress = current ?? addresses.firstOrNull;
        if (_editSelectedAddress != null &&
            _editPostalCodeController.text.isEmpty) {
          _editPostalCodeController.text = _editSelectedAddress!.postalCode;
        }
      });
    } on Object catch (e, st) {
      logError(e, st);
    }
  }

  Future<void> _confirmCancelEdit(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.discardChanges),
        content: Text(s.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.discard),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _cancelEdit();
  }

  Future<void> _cancelEdit() async {
    // Delete photos of items added in this session.
    // Per-URL try/catch so one failure doesn't orphan the rest.
    for (final item in _editItems) {
      if (!_originalItemIds.contains(item.id)) {
        for (final url in item.photoUrls) {
          try {
            await _photoService.deletePhoto(url);
          } on Object catch (e, st) {
            logError(e, st);
          }
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _editItems = [];
      _pendingDeletions = [];
      _buyerAddresses = [];
      _editSelectedAddress = null;
    });
  }

  Future<void> _saveEdit(BuildContext context) async {
    final s = context.s;
    if (_editItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.atLeastOneItem)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      for (final url in _pendingDeletions) {
        await _photoService.deletePhoto(url);
      }
      final sale = _lastKnownSale!;
      final needsAddress = _editDeliveryType == DeliveryType.shipping ||
          _editDeliveryType == DeliveryType.handDelivery;
      final shipment = SaleShipment(
        type: _editDeliveryType,
        status: _editShipmentStatus,
        trackingCode: _editDeliveryType == DeliveryType.shipping
            ? _nullIfEmpty(_editTrackingCodeController.text)
            : null,
        addressId: needsAddress ? _editSelectedAddress?.id : null,
        postalCode:
            needsAddress ? _nullIfEmpty(_editPostalCodeController.text) : null,
        shippedAt: _editDeliveryType == DeliveryType.shipping
            ? _editShippedAt
            : null,
      );
      final updated = sale.copyWith(
        items: _editItems,
        payment: SalePayment(
          status: _editPaymentStatus,
          method: _editPaymentMethod,
        ),
        shipment: shipment,
        requiresNif: _editRequiresNif,
        atSubmissionDone: _editAtSubmissionDone,
        scheduledDate: _editScheduledDate,
        notes: _nullIfEmpty(_editNotesController.text),
      );
      await _repository.updateSale(updated);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _editItems = [];
        _pendingDeletions = [];
        _buyerAddresses = [];
        _editSelectedAddress = null;
      });
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.errorSavingSaleMsg(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── item helpers ─────────────────────────────────────────────────────────

  Future<void> _addItem(BuildContext context) async {
    final result =
        await pushSaleItemScreen(context, saleId: widget.saleId);
    if (result == null || !mounted) return;
    _pendingDeletions.addAll(result.pendingDeletions);
    setState(() => _editItems.add(result.item));
  }

  Future<void> _editItem(BuildContext context, int index) async {
    final result = await pushSaleItemScreen(
      context,
      saleId: widget.saleId,
      item: _editItems[index],
    );
    if (result == null || !mounted) return;
    _pendingDeletions.addAll(result.pendingDeletions);
    setState(() => _editItems[index] = result.item);
  }

  Future<void> _removeItem(int index) async {
    final item = _editItems[index];
    if (_originalItemIds.contains(item.id)) {
      _pendingDeletions.addAll(item.photoUrls);
    } else {
      for (final url in item.photoUrls) {
        await _photoService.deletePhoto(url);
      }
    }
    if (mounted) setState(() => _editItems.removeAt(index));
  }

  // ── address helpers (edit mode) ───────────────────────────────────────────

  Future<void> _addAddress(BuildContext context) async {
    final existingIds = {for (final a in _buyerAddresses) a.id};
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BuyerAddressFormScreen(buyerId: _editBuyerId),
      ),
    );
    if (!mounted) return;
    final addresses =
        await BuyerRepository().watchAddresses(_editBuyerId).first;
    final newAddress =
        addresses.where((a) => !existingIds.contains(a.id)).firstOrNull;
    setState(() {
      _buyerAddresses = addresses;
      _editSelectedAddress =
          newAddress ?? _editSelectedAddress ?? addresses.firstOrNull;
      if (_editSelectedAddress != null) {
        _editPostalCodeController.text = _editSelectedAddress!.postalCode;
      }
    });
  }

  // ── read-mode operations ─────────────────────────────────────────────────

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
      message = s.deleteShippedSaleBody(
        statusLabel,
        atDone: sale.atSubmissionDone,
        photoCount: totalPhotos,
      );
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
        _popping = true;
        Navigator.of(context).pop();
      }
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.errorDeletingSaleMsg(e))));
      }
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  List<ShipmentStatus> _availableShipmentStatuses(DeliveryType type) {
    if (type == DeliveryType.pickup || type == DeliveryType.handDelivery) {
      return [ShipmentStatus.pending, ShipmentStatus.delivered];
    }
    return ShipmentStatus.values;
  }

  void _onShipmentStatusChanged(ShipmentStatus? newStatus) {
    if (newStatus == null) return;
    final autoShippedAt =
        newStatus == ShipmentStatus.shipped && _editShippedAt == null
            ? DateTime.now()
            : _editShippedAt;
    setState(() {
      _editShipmentStatus = newStatus;
      _editShippedAt = autoShippedAt;
    });
  }

  // ── AppBars ───────────────────────────────────────────────────────────────

  AppBar _buildReadAppBar(BuildContext context, Sale sale) {
    return AppBar(
      title: Text(sale.buyerName),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: context.s.duplicateSaleTooltip,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => NewSaleScreen(sale: sale, isDuplicate: true),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: context.s.deleteSaleTooltip,
          onPressed: () => _confirmDelete(context, sale),
        ),
      ],
    );
  }

  AppBar _buildEditAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _confirmCancelEdit(context),
      ),
      title: Text(context.s.editSale),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => _saveEdit(context),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.s.save),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

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
            appBar: AppBar(title: Text(context.s.saleFallbackTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Cache for tablet FAB signal; only update in read mode so the snapshot
        // used when entering edit mode reflects the last-seen state.
        if (!_isEditing) _lastKnownSale = sale;

        return PopScope(
          canPop: !_isEditing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmCancelEdit(context));
          },
          child: Scaffold(
            appBar: _isEditing
                ? _buildEditAppBar(context)
                : _buildReadAppBar(context, sale),
            floatingActionButton: _isEditing
                ? null
                : FloatingActionButton(
                    tooltip: context.s.editSale,
                    onPressed: () => _enterEditMode(sale),
                    child: const Icon(Icons.edit),
                  ),
            body: _isEditing
                ? _buildEditBody(context)
                : _SaleDetailReadBody(sale: sale),
          ),
        );
      },
    );
  }

  // ── edit body ─────────────────────────────────────────────────────────────

  Widget _buildEditBody(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    final total = _editItems.fold<double>(0, (acc, i) => acc + i.price);

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        // ── Buyer (locked) ─────────────────────────────────────────────────
        _FormCard(
          title: s.sectionBuyer,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: s.buyerLabel,
              border: const OutlineInputBorder(),
            ),
            child: Text(_editBuyerName),
          ),
        ),
        const SizedBox(height: 12),

        // ── Items ──────────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionItems,
          trailing: _editItems.isNotEmpty
              ? Text(
                  '${s.saleTotal}: €${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                )
              : null,
          child: Column(
            children: [
              ..._editItems.asMap().entries.map(
                    (e) => _EditItemRow(
                      item: e.value,
                      onEdit: () => _editItem(context, e.key),
                      onDelete: () => _removeItem(e.key),
                    ),
                  ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addItem(context),
                  icon: const Icon(Icons.add),
                  label: Text(s.addItem),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Payment ────────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionPayment,
          child: Column(
            children: [
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _editPaymentMethod,
                decoration: InputDecoration(
                  labelText: s.paymentMethodDropdownLabel,
                  border: const OutlineInputBorder(),
                ),
                items: kPaymentMethodOrder
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: PaymentMethodDropdownItem(m),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _editPaymentMethod = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.markAsPaidLabel),
                value: _editPaymentStatus == PaymentStatus.paid,
                onChanged: (v) => setState(() => _editPaymentStatus =
                    v ? PaymentStatus.paid : PaymentStatus.unpaid),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.requiresNifLabel),
                value: _editRequiresNif,
                onChanged: (v) => setState(() => _editRequiresNif = v),
              ),
              if (_editRequiresNif &&
                  _editPaymentStatus == PaymentStatus.paid) ...[
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_editAtSubmissionDone
                      ? s.atReceiptFiled
                      : s.atReceiptPending),
                  value: _editAtSubmissionDone,
                  onChanged: (v) =>
                      setState(() => _editAtSubmissionDone = v),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Delivery ───────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionDelivery,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<DeliveryType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DeliveryType.shipping,
                    icon: const Icon(Icons.local_shipping),
                    label: Text(s.shipping),
                  ),
                  ButtonSegment(
                    value: DeliveryType.pickup,
                    icon: const Icon(Icons.store),
                    label: Text(s.pickup),
                  ),
                  ButtonSegment(
                    value: DeliveryType.handDelivery,
                    icon: const Icon(Icons.directions_walk),
                    label: Text(s.handDelivery),
                  ),
                ],
                selected: {_editDeliveryType},
                onSelectionChanged: (v) {
                  final newType = v.first;
                  final statuses = _availableShipmentStatuses(newType);
                  setState(() {
                    _editDeliveryType = newType;
                    if (!statuses.contains(_editShipmentStatus)) {
                      _editShipmentStatus = ShipmentStatus.pending;
                    }
                    // Clear captured shipped date when leaving shipping type so
                    // it doesn't silently re-attach if the user switches back.
                    if (newType != DeliveryType.shipping) {
                      _editShippedAt = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShipmentStatus>(
                key: ValueKey(_editDeliveryType),
                initialValue: _editShipmentStatus,
                decoration: InputDecoration(
                  labelText: s.deliveryStatusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _availableShipmentStatuses(_editDeliveryType)
                    .map((st) => DropdownMenuItem(
                          value: st,
                          child: Text(s.shipmentStatusLabel(st)),
                        ))
                    .toList(),
                onChanged: _onShipmentStatusChanged,
              ),
              if (_editDeliveryType == DeliveryType.shipping ||
                  _editDeliveryType == DeliveryType.handDelivery) ...[
                const SizedBox(height: 16),
                if (_buyerAddresses.isNotEmpty)
                  DropdownButtonFormField<BuyerAddress>(
                    initialValue: _editSelectedAddress,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s.shipToAddressLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: _buyerAddresses
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                '${a.label} — ${a.street}, ${a.city}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (a) {
                      setState(() {
                        _editSelectedAddress = a;
                        if (a != null) {
                          _editPostalCodeController.text = a.postalCode;
                        }
                      });
                    },
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _addAddress(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(s.newAddress),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _editPostalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.postalCodeLabel,
                    hintText: s.postalCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_editDeliveryType == DeliveryType.shipping) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _editTrackingCodeController,
                    decoration: InputDecoration(
                      labelText: s.cttTrackingLabel,
                      hintText: s.cttTrackingHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ShippedAtField(
                    shippedAt: _editShippedAt,
                    isReadOnly: false,
                    onChanged: (dt) => setState(() => _editShippedAt = dt),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              _ScheduledDateField(
                date: _editScheduledDate,
                isPickup: _editDeliveryType == DeliveryType.pickup,
                isReadOnly: false,
                onChanged: (date) => setState(() => _editScheduledDate = date),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Notes ──────────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionNotes,
          child: TextFormField(
            controller: _editNotesController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.notesHintDetail,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Read-only detail body ────────────────────────────────────────────────────

class _SaleDetailReadBody extends StatelessWidget {
  const _SaleDetailReadBody({required this.sale});

  static final _dateFormat = DateFormat('dd MMM yyyy');

  final Sale sale;

  void _openItemDetail(BuildContext context, SaleItem item) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemDetailSheet(
        saleId: sale.id,
        item: item,
        isReadOnly: true,
        onUpdateItem: (_) {},
      ),
    ));
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
              MaterialPageRoute<void>(
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
            text: () {
              final price = sale.totalPrice.toStringAsFixed(2);
              final n = sale.items.length;
              return '€$price · $n ${n == 1 ? 'item' : 'items'}';
            }(),
          ),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionPayment,
          indicator: paymentDot(sale.payment, cs),
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
              if (sale.requiresNif) ...[
                const Divider(height: 16),
                ValueListenableBuilder(
                  valueListenable: BuyersStore.state,
                  builder: (context, _, _) => _NifComplianceRow(
                    sale: sale,
                    isReadOnly: true,
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
          title: s.sectionItems,
          indicator: assemblyDot(sale.derivedAssemblyStatus, cs),
          child: Column(
            children: sale.items
                .map((item) => _ItemSummaryTile(
                      item: item,
                      onTap: () => _openItemDetail(context, item),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionDelivery,
          indicator: shipmentDot(sale.shipment, cs),
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
                if (sale.shipment.type == DeliveryType.shipping) ...[
                  _TrackingCodeField(
                    value: sale.shipment.trackingCode ?? '',
                    isReadOnly: true,
                    onSave: (_) {},
                  ),
                  const SizedBox(height: 8),
                  _ShippedAtField(
                    shippedAt: sale.shipment.shippedAt,
                    isReadOnly: true,
                    onChanged: (_) {},
                  ),
                ],
              ],
            ],
          ),
        ),
        if (sale.scheduledDate != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: sale.shipment.type == DeliveryType.pickup
                ? s.readyBy
                : s.scheduledLabel,
            child: _ScheduledDateField(
              date: sale.scheduledDate,
              isPickup: sale.shipment.type == DeliveryType.pickup,
              isReadOnly: true,
              onChanged: (_) {},
            ),
          ),
        ],
        const SizedBox(height: 16),
        _RepairsSection(saleId: sale.id),
        if (sale.notes != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: s.sectionNotes,
            child: Text(sale.notes!),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Item summary tile (read-only) ────────────────────────────────────────────

class _ItemSummaryTile extends StatelessWidget {
  const _ItemSummaryTile({required this.item, required this.onTap});

  final SaleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        item.assemblyStatus.colorOf(Theme.of(context).colorScheme);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: item.photoUrls.isNotEmpty
          ? PhotoThumbnail(
              url: item.photoUrls.first,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
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

// ── Edit item row (used in edit body) ────────────────────────────────────────

class _EditItemRow extends StatelessWidget {
  const _EditItemRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final SaleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onEdit,
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
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item detail sheet (read-only in read mode) ───────────────────────────────

class _ItemDetailSheet extends StatefulWidget {
  const _ItemDetailSheet({
    required this.saleId,
    required this.item,
    required this.isReadOnly,
    required this.onUpdateItem,
  });

  final String saleId;
  final SaleItem item;
  final bool isReadOnly;
  final ValueChanged<SaleItem> onUpdateItem;

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  final _componentController = TextEditingController();
  final _photoService = PhotoService();
  final _sessionComponentUploads = <String>{};
  Timer? _quantityDebounce;
  late SaleItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _quantityDebounce?.cancel();
    _componentController.dispose();
    if (!widget.isReadOnly) {
      final committedUrls = {
        for (final c in _item.components) ...c.photoUrls,
      };
      for (final url in _sessionComponentUploads) {
        if (!committedUrls.contains(url)) {
          unawaited(_photoService.deletePhoto(url));
        }
      }
    }
    super.dispose();
  }

  void _applyItemUpdate(SaleItem updated) {
    setState(() => _item = updated);
    widget.onUpdateItem(updated);
  }

  void _toggleComponent(ComponentItem c) {
    final updated = _item.copyWith(
      components: _item.components
          .map((ci) =>
              ci.id == c.id ? ci.copyWith(isAvailable: !c.isAvailable) : ci)
          .toList(),
    );
    setState(() => _item = updated);
    widget.onUpdateItem(updated);
  }

  void _adjustQuantity(ComponentItem c, int delta) {
    final updated = _item.copyWith(
      components: _item.components
          .map((ci) => ci.id == c.id ? ci.adjustedQuantity(delta) : ci)
          .toList(),
    );
    setState(() => _item = updated);
    _quantityDebounce?.cancel();
    _quantityDebounce = Timer(const Duration(milliseconds: 600), () {
      widget.onUpdateItem(updated);
    });
  }

  void _removeComponent(ComponentItem c) {
    final updated = _item.copyWith(
      components: _item.components.where((ci) => ci.id != c.id).toList(),
    );
    setState(() => _item = updated);
    widget.onUpdateItem(updated);
    c.photoUrls.forEach(_photoService.deletePhoto);
  }

  Future<void> _openComponentSheet(ComponentItem c) async {
    await showComponentDetailSheet(
      context,
      component: c,
      saleId: widget.saleId,
      itemId: _item.id,
      isReadOnly: widget.isReadOnly,
      onChanged: widget.isReadOnly
          ? (_) {}
          : (updated) => _applyItemUpdate(
                _item.copyWith(
                  components: _item.components
                      .map((ci) => ci.id == updated.id ? updated : ci)
                      .toList(),
                ),
              ),
      onPhotoAdded: widget.isReadOnly ? (_) {} : _sessionComponentUploads.add,
      onPhotoRemoved: widget.isReadOnly
          ? (_) {}
          : (url) {
              _sessionComponentUploads.remove(url);
              unawaited(_photoService.deletePhoto(url));
            },
    );
  }

  void _addComponent() {
    if (widget.isReadOnly) return;
    final name = _componentController.text.trim();
    if (name.isEmpty) return;
    final updated = _item.copyWith(
      components: [
        ..._item.components,
        ComponentItem(id: newId(), name: name, isAvailable: false),
      ],
    );
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
          if (widget.isReadOnly)
            Text(s.assemblyLabel(_item.assemblyStatus))
          else
            DropdownButton<AssemblyStatus>(
              value: _item.assemblyStatus,
              isExpanded: true,
              underline: const SizedBox(),
              items: AssemblyStatus.values
                  .map((st) => DropdownMenuItem(
                      value: st, child: Text(s.assemblyLabel(st))))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                _applyItemUpdate(_item.copyWith(assemblyStatus: v));
              },
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
              isReadOnly: widget.isReadOnly,
              onChanged: widget.isReadOnly
                  ? (_) {}
                  : (urls) =>
                      _applyItemUpdate(_item.copyWith(photoUrls: urls)),
            ),
          ],
          const SizedBox(height: 16),
          Text(s.sectionComponents,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 4),
          if (_item.components.isEmpty)
            Text(
              '—',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ..._item.components.map(
              (c) => widget.isReadOnly
                  ? _ReadOnlyComponentTile(
                      component: c,
                      onOpenSheet: () => _openComponentSheet(c),
                    )
                  : Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(context).colorScheme.error,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _removeComponent(c),
                      child: _InteractiveComponentTile(
                        component: c,
                        onToggle: () => _toggleComponent(c),
                        onAdjustQuantity: (q) =>
                            _adjustQuantity(c, q - c.quantity),
                        onOpenSheet: () => _openComponentSheet(c),
                      ),
                    ),
            ),
          if (!widget.isReadOnly) ...[
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
        ],
      ),
    );
  }
}

class _ReadOnlyComponentTile extends StatelessWidget {
  const _ReadOnlyComponentTile({
    required this.component,
    required this.onOpenSheet,
  });

  final ComponentItem component;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        component.isAvailable ? Icons.check_box : Icons.check_box_outline_blank,
        color: component.isAvailable
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Expanded(child: Text(component.name)),
          if (component.quantity > 1)
            Text(
              '× ${component.quantity}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      subtitle: Text(component.isAvailable ? s.haveIt : s.needToBuy),
      trailing: ComponentPhotoBadge(
        count: component.photoUrls.length,
        onTap: onOpenSheet,
      ),
    );
  }
}

class _InteractiveComponentTile extends StatelessWidget {
  const _InteractiveComponentTile({
    required this.component,
    required this.onToggle,
    required this.onAdjustQuantity,
    required this.onOpenSheet,
  });

  final ComponentItem component;
  final VoidCallback onToggle;
  final ValueChanged<int> onAdjustQuantity;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(component.name)),
          ComponentQuantityStepper(
            quantity: component.quantity,
            onChanged: onAdjustQuantity,
          ),
        ],
      ),
      subtitle: Text(component.isAvailable ? s.haveIt : s.needToBuy),
      value: component.isAvailable,
      onChanged: (_) => onToggle(),
      secondary: ComponentPhotoBadge(
        count: component.photoUrls.length,
        onTap: onOpenSheet,
      ),
    );
  }
}

// ── Tracking code field ──────────────────────────────────────────────────────

class _TrackingCodeField extends StatefulWidget {
  const _TrackingCodeField({
    required this.value,
    required this.isReadOnly,
    required this.onSave,
  });

  final String value;
  final bool isReadOnly;
  final ValueChanged<String> onSave;

  @override
  State<_TrackingCodeField> createState() => _TrackingCodeFieldState();
}

class _TrackingCodeFieldState extends State<_TrackingCodeField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_controller.text.isEmpty) {
      if (widget.isReadOnly) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addCttTracking),
      );
    }

    if (_editing && !widget.isReadOnly) {
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
        if (!widget.isReadOnly)
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

// ── Scheduled date field ─────────────────────────────────────────────────────

class _ScheduledDateField extends StatelessWidget {
  const _ScheduledDateField({
    required this.date,
    required this.isPickup,
    required this.isReadOnly,
    required this.onChanged,
  });

  static final _dateFormat = DateFormat('EEE, dd MMM yyyy');

  final DateTime? date;
  final bool isPickup;
  final bool isReadOnly;
  final ValueChanged<DateTime?> onChanged;

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
      if (isReadOnly) {
        return Text(
          isPickup ? s.noReadyByDate : s.noScheduledDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        );
      }
      return TextButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event),
        label: Text(isPickup ? s.readyBy : s.setScheduledDate),
      );
    }

    return Row(
      children: [
        const Icon(Icons.event, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(_dateFormat.format(date!))),
        if (!isReadOnly) ...[
          TextButton(
            onPressed: () => _pick(context),
            child: Text(s.change),
          ),
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(s.clear),
          ),
        ],
      ],
    );
  }
}

// ── Shipped-at field ─────────────────────────────────────────────────────────

class _ShippedAtField extends StatelessWidget {
  const _ShippedAtField({
    required this.shippedAt,
    required this.isReadOnly,
    required this.onChanged,
  });

  static final _dateTimeFormat = DateFormat('EEE, dd MMM yyyy, HH:mm');

  final DateTime? shippedAt;
  final bool isReadOnly;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial = shippedAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: kShippedAtFirstDate,
      lastDate: DateTime.now().add(kShippedAtMaxFutureOffset),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    onChanged(DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (shippedAt == null) {
      if (isReadOnly) return const SizedBox.shrink();
      return TextButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.local_shipping_outlined),
        label: Text(s.setShippedAt),
      );
    }
    return Row(
      children: [
        const Icon(Icons.local_shipping_outlined, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(_dateTimeFormat.format(shippedAt!))),
        if (!isReadOnly) ...[
          TextButton(
            onPressed: () => _pick(context),
            child: Text(s.change),
          ),
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(s.clear),
          ),
        ],
      ],
    );
  }
}

// ── Address display ──────────────────────────────────────────────────────────

class _AddressDisplay extends StatefulWidget {
  const _AddressDisplay({
    required this.buyerId,
    required this.addressId,
    this.postalCode,
  });

  final String buyerId;
  final String addressId;
  final String? postalCode;

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

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.indicator,
  });

  final String title;
  final Widget child;
  final StatusIndicatorDot? indicator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (indicator != null) ...[
                  StatusBubble(
                    icon: indicator!.icon,
                    color: indicator!.color,
                    size: 32,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Form card (used in edit body) ────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

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

// ── NIF compliance row ───────────────────────────────────────────────────────

class _NifComplianceRow extends StatelessWidget {
  const _NifComplianceRow({
    required this.sale,
    required this.isReadOnly,
    required this.buyer,
  });

  final Sale sale;
  final bool isReadOnly;
  final Buyer? buyer;

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
    } else if (!isPaid) {
      label = s.nifReceiptRequiredInfo;
    } else {
      label = sale.atSubmissionDone ? s.atReceiptFiled : s.atReceiptPending;
      if (!isReadOnly) {
        trailing = IconButton(
          icon: Icon(
            sale.atSubmissionDone
                ? Icons.check_circle
                : Icons.check_circle_outline,
            color: sale.atSubmissionDone ? cs.success : cs.warning,
          ),
          tooltip: sale.atSubmissionDone ? s.markAsPending : s.markAsFiled,
          onPressed: () {}, // handled via edit mode buffer
        );
      }
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

// ── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
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

// ── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

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

// ── Repairs section ──────────────────────────────────────────────────────────

class _RepairsSection extends StatelessWidget {
  const _RepairsSection({required this.saleId});

  final String saleId;

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
                        '${repair.contactName}'
                        ' · ${s.repairStatusLabelFor(repair.status)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
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
