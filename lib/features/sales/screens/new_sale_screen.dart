import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/id_gen.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_address.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_stats.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_address_form_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/sales/screens/sale_item_screen.dart';
import 'package:latitude_tracker/features/sales/services/photo_service.dart';
import 'package:latitude_tracker/features/sales/widgets/buyer_picker_screen.dart';
import 'package:latitude_tracker/features/sales/widgets/payment_method_display.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key, this.sale});
  final Sale? sale;

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _saleRepository = SaleRepository();
  final _buyerRepository = BuyerRepository();
  final _photoService = PhotoService();

  Buyer? _selectedBuyer;
  BuyerStats? _selectedBuyerStats;
  List<BuyerAddress> _buyerAddresses = [];
  BuyerAddress? _selectedAddress;

  late final TextEditingController _notesController;
  late final TextEditingController _trackingCodeController;
  late final TextEditingController _postalCodeController;

  late PaymentMethod _paymentMethod;
  late PaymentStatus _paymentStatus;
  late DeliveryType _deliveryType;
  late bool _requiresNif;
  late List<SaleItem> _items;
  late final String _saleId;

  // Item IDs that existed in the original sale (edit mode only).
  late final Set<String> _originalItemIds;

  // Pending deletions accumulated from SaleItemScreen saves.
  final List<String> _pendingDeletions = [];

  DateTime? _scheduledDate;
  bool _isLoading = false;

  bool get _isEditing => widget.sale != null;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;

    _notesController = TextEditingController(text: sale?.notes ?? '');
    _trackingCodeController = TextEditingController(
      text: sale?.shipment.trackingCode ?? '',
    );
    _postalCodeController = TextEditingController(
      text: sale?.shipment.postalCode ?? '',
    );

    _paymentMethod = sale?.payment.method ?? PaymentMethod.mbWay;
    _paymentStatus = sale?.payment.status ?? PaymentStatus.unpaid;
    _deliveryType = sale?.shipment.type ?? DeliveryType.shipping;
    _requiresNif = sale?.requiresNif ?? false;
    _scheduledDate = sale?.scheduledDate;
    _saleId = _isEditing ? sale!.id : newId();
    _items = List.from(sale?.items ?? []);
    _originalItemIds = {for (final item in _items) item.id};

    if (widget.sale != null) unawaited(_loadBuyerForEdit());
  }

  Future<void> _loadBuyerForEdit() async {
    final sale = widget.sale!;
    final buyer = await _buyerRepository.getBuyer(sale.buyerId);
    if (buyer == null || !mounted) return;
    final results = await Future.wait([
      _buyerRepository.watchAddresses(buyer.id).first,
      _saleRepository.getSalesForBuyer(buyer.id),
    ]);
    final addresses = results[0] as List<BuyerAddress>;
    final buyerSales = results[1] as List<Sale>;
    final savedAddress = addresses
        .where((a) => a.id == sale.shipment.addressId)
        .firstOrNull;
    setState(() {
      _selectedBuyer = buyer;
      _buyerAddresses = addresses;
      _selectedAddress = savedAddress ?? addresses.firstOrNull;
      _selectedBuyerStats = BuyerStats.compute(buyerSales);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _trackingCodeController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickBuyer() async {
    if (_isEditing) return;
    final buyer = await Navigator.push<Buyer>(
      context,
      MaterialPageRoute<Buyer>(builder: (_) => const BuyerPickerScreen()),
    );
    if (buyer == null) return;
    final results = await Future.wait([
      _buyerRepository.watchAddresses(buyer.id).first,
      _saleRepository.getSalesForBuyer(buyer.id),
    ]);
    final addresses = results[0] as List<BuyerAddress>;
    final buyerSales = results[1] as List<Sale>;
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull;
    setState(() {
      _selectedBuyer = buyer;
      _buyerAddresses = addresses;
      _selectedBuyerStats = BuyerStats.compute(buyerSales);
      _selectedAddress = defaultAddress ?? addresses.firstOrNull;
      if (_selectedAddress != null) {
        _postalCodeController.text = _selectedAddress!.postalCode;
      }
    });
  }

  Future<void> _addAddress() async {
    if (_selectedBuyer == null) return;
    final existingIds = {for (final a in _buyerAddresses) a.id};
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BuyerAddressFormScreen(buyerId: _selectedBuyer!.id),
      ),
    );
    if (!mounted) return;
    final addresses = await _buyerRepository
        .watchAddresses(_selectedBuyer!.id)
        .first;
    final newAddress = addresses
        .where((a) => !existingIds.contains(a.id))
        .firstOrNull;
    setState(() {
      _buyerAddresses = addresses;
      _selectedAddress =
          newAddress ?? _selectedAddress ?? addresses.firstOrNull;
      if (_selectedAddress != null) {
        _postalCodeController.text = _selectedAddress!.postalCode;
      }
    });
  }

  Future<void> _addItem() async {
    final result = await pushSaleItemScreen(context, saleId: _saleId);
    if (result == null || !mounted) return;
    _pendingDeletions.addAll(result.pendingDeletions);
    setState(() => _items.add(result.item));
  }

  Future<void> _editItem(int index) async {
    final result = await pushSaleItemScreen(
      context,
      saleId: _saleId,
      item: _items[index],
    );
    if (result == null || !mounted) return;
    _pendingDeletions.addAll(result.pendingDeletions);
    setState(() => _items[index] = result.item);
  }

  Future<void> _removeItem(int index) async {
    final item = _items[index];
    // If this item was in the original sale, queue its photos for deletion on
    // save.
    if (_originalItemIds.contains(item.id)) {
      _pendingDeletions.addAll(item.photoUrls);
    } else {
      // New item — delete its photos now (won't be saved).
      for (final url in item.photoUrls) {
        await _photoService.deletePhoto(url);
      }
    }
    if (mounted) setState(() => _items.removeAt(index));
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _cancel() async {
    try {
      if (_isEditing) {
        // Delete photos from newly added items (those not in the original
        // sale).
        for (final item in _items) {
          if (!_originalItemIds.contains(item.id)) {
            for (final url in item.photoUrls) {
              await _photoService.deletePhoto(url);
            }
          }
        }
      } else {
        // New sale — wipe everything under this sale's storage folder.
        await _photoService.deleteAllPhotos(_saleId);
      }
    } on Object catch (e, st) {
      logError(e, st);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final s = context.s;
    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.buyerRequired)));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.atLeastOneItem)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final shipment = SaleShipment(
        type: _deliveryType,
        status: _isEditing
            ? widget.sale!.shipment.status
            : ShipmentStatus.pending,
        trackingCode: _deliveryType == DeliveryType.shipping
            ? _nullIfEmpty(_trackingCodeController.text)
            : null,
        addressId: _selectedAddress?.id,
        postalCode:
            (_deliveryType == DeliveryType.shipping ||
                _deliveryType == DeliveryType.handDelivery)
            ? _nullIfEmpty(_postalCodeController.text)
            : null,
      );

      for (final url in _pendingDeletions) {
        await _photoService.deletePhoto(url);
      }

      final notesValue = _nullIfEmpty(_notesController.text);

      if (_isEditing) {
        final updated = widget.sale!.copyWith(
          items: _items,
          payment: SalePayment(status: _paymentStatus, method: _paymentMethod),
          shipment: shipment,
          requiresNif: _requiresNif,
          scheduledDate: _scheduledDate,
          notes: notesValue,
        );
        await _saleRepository.updateSale(updated);
      } else {
        final sale = Sale(
          id: _saleId,
          buyerId: _selectedBuyer!.id,
          buyerName: _selectedBuyer!.name,
          items: _items,
          payment: SalePayment(status: _paymentStatus, method: _paymentMethod),
          shipment: shipment,
          requiresNif: _requiresNif,
          scheduledDate: _scheduledDate,
          createdAt: DateTime.now(),
          notes: notesValue,
        );
        await _saleRepository.createSale(sale);
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (e, st) {
      logError(e, st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.errorSavingSaleMsg(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPrice => _items.fold(0, (acc, item) => acc + item.price);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_cancel());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? s.editSale : s.newSale),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancel,
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // ── Buyer ──────────────────────────────────────────────────────
            _FormCard(
              title: s.sectionBuyer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BuyerSelector(
                    buyer: _selectedBuyer,
                    label: s.buyerLabel,
                    placeholder: s.tapToSelectBuyer,
                    isEditing: _isEditing,
                    onTap: _pickBuyer,
                  ),
                  if (_selectedBuyerStats != null &&
                      _selectedBuyerStats!.saleCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      s.previousSales(
                        _selectedBuyerStats!.saleCount,
                        _selectedBuyerStats!.lastPurchaseAt != null
                            ? DateFormat(
                                'MMM yyyy',
                              ).format(_selectedBuyerStats!.lastPurchaseAt!)
                            : '',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Items ──────────────────────────────────────────────────────
            _FormCard(
              title: s.sectionItems,
              trailing: _items.isNotEmpty
                  ? Text(
                      '${s.saleTotal}: €${_totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  ..._items.asMap().entries.map(
                    (entry) => _ItemRow(
                      item: entry.value,
                      onEdit: () => _editItem(entry.key),
                      onDelete: () => _removeItem(entry.key),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: Text(s.addItem),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Payment ────────────────────────────────────────────────────
            _FormCard(
              title: s.sectionPayment,
              child: Column(
                children: [
                  DropdownButtonFormField<PaymentMethod>(
                    initialValue: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: s.paymentMethodDropdownLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: kPaymentMethodOrder
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: PaymentMethodDropdownItem(m),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.paid),
                    value: _paymentStatus == PaymentStatus.paid,
                    onChanged: (v) => setState(
                      () => _paymentStatus = v
                          ? PaymentStatus.paid
                          : PaymentStatus.unpaid,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.requiresNifLabel),
                    value: _requiresNif,
                    onChanged: (v) => setState(() => _requiresNif = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Delivery ───────────────────────────────────────────────────
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
                    selected: {_deliveryType},
                    onSelectionChanged: (v) =>
                        setState(() => _deliveryType = v.first),
                  ),
                  if (_deliveryType == DeliveryType.shipping ||
                      _deliveryType == DeliveryType.handDelivery) ...[
                    const SizedBox(height: 16),
                    if (_buyerAddresses.isNotEmpty) ...[
                      DropdownButtonFormField<BuyerAddress>(
                        initialValue: _selectedAddress,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: s.shipToAddressLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: _buyerAddresses
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(
                                  '${a.label} — ${a.street}, ${a.city}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (a) => setState(() {
                          _selectedAddress = a;
                          if (a != null) {
                            _postalCodeController.text = a.postalCode;
                          }
                        }),
                      ),
                      if (_selectedAddress != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${_selectedAddress!.street},'
                            ' ${_selectedAddress!.postalCode}'
                            ' ${_selectedAddress!.city},'
                            ' ${_selectedAddress!.country}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                    if (_selectedBuyer != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addAddress,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(s.newAddress),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: s.postalCodeLabel,
                        hintText: s.postalCodeHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_deliveryType == DeliveryType.shipping) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _trackingCodeController,
                        decoration: InputDecoration(
                          labelText: s.cttTrackingLabel,
                          hintText: s.cttTrackingHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  _ScheduledDatePicker(
                    date: _scheduledDate,
                    isPickup: _deliveryType == DeliveryType.pickup,
                    onChanged: (date) => setState(() => _scheduledDate = date),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Notes ──────────────────────────────────────────────────────
            _FormCard(
              title: s.sectionNotes,
              child: TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.notesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

class _ScheduledDatePicker extends StatelessWidget {
  const _ScheduledDatePicker({
    required this.date,
    required this.isPickup,
    required this.onChanged,
  });
  final DateTime? date;
  final bool isPickup;
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
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final hasDate = date != null;
    final label = hasDate
        ? '${isPickup ? s.readyBy : s.scheduledLabel}:'
        ' ${dateFormat.format(date!)}'
        : isPickup
        ? s.noReadyByDate
        : s.noScheduledDate;
    return Row(
      children: [
        const Icon(Icons.event, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(hasDate ? s.change : s.setDate),
        ),
        if (hasDate)
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(s.clear),
          ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child, this.trailing});
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

class _BuyerSelector extends StatelessWidget {
  const _BuyerSelector({
    required this.buyer,
    required this.label,
    required this.placeholder,
    required this.isEditing,
    required this.onTap,
  });
  final Buyer? buyer;
  final String label;
  final String placeholder;
  final bool isEditing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEditing ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isEditing
              ? null
              : const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        child: Text(
          buyer?.name ?? placeholder,
          style: buyer == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}
