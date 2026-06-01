import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_strings.dart';
import '../../buyers/models/buyer.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/models/buyer_stats.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../services/photo_service.dart';
import '../widgets/buyer_picker_screen.dart';
import '../widgets/photo_grid.dart';

class NewSaleScreen extends StatefulWidget {
  final Sale? sale;
  final bool isDuplicate;

  const NewSaleScreen({super.key, this.sale, this.isDuplicate = false});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleRepository = SaleRepository();
  final _buyerRepository = BuyerRepository();

  Buyer? _selectedBuyer;
  BuyerStats? _selectedBuyerStats;
  List<BuyerAddress> _buyerAddresses = [];
  BuyerAddress? _selectedAddress;

  late final TextEditingController _itemDescController;
  late final TextEditingController _notesController;
  late final TextEditingController _priceController;
  late final TextEditingController _trackingCodeController;
  late final TextEditingController _postalCodeController;
  final TextEditingController _newComponentController = TextEditingController();

  late AssemblyStatus _assemblyStatus;
  late PaymentMethod _paymentMethod;
  late PaymentStatus _paymentStatus;
  late DeliveryType _deliveryType;
  late bool _requiresNif;
  late List<ComponentItem> _components;
  late List<String> _photoUrls;
  late final String _saleId;
  late final List<String> _originalPhotoUrls;
  final List<String> _uploadedInSession = [];
  final List<String> _pendingDeletions = [];
  final _photoService = PhotoService();
  DateTime? _scheduledDate;
  bool _isLoading = false;

  bool get _isEditing => widget.sale != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    final dup = widget.isDuplicate;
    _itemDescController =
        TextEditingController(text: sale?.itemDescription ?? '');
    _notesController =
        TextEditingController(text: dup ? '' : (sale?.notes ?? ''));
    _priceController = TextEditingController(
        text: sale != null ? sale.price.toStringAsFixed(2) : '');
    _trackingCodeController = TextEditingController(
        text: dup ? '' : (sale?.shipment.trackingCode ?? ''));
    _postalCodeController =
        TextEditingController(text: sale?.shipment.postalCode ?? '');
    _assemblyStatus = dup
        ? AssemblyStatus.notStarted
        : (sale?.assemblyStatus ?? AssemblyStatus.notStarted);
    _paymentMethod = sale?.payment.method ?? PaymentMethod.mbWay;
    _paymentStatus =
        dup ? PaymentStatus.unpaid : (sale?.payment.status ?? PaymentStatus.unpaid);
    _deliveryType = sale?.shipment.type ?? DeliveryType.shipping;
    _requiresNif = sale?.requiresNif ?? false;
    _components = dup
        ? (sale?.components
                .map((c) => c.copyWith(isAvailable: false))
                .toList() ??
            [])
        : List.from(sale?.components ?? []);
    _photoUrls = dup ? [] : List.from(sale?.photoUrls ?? []);
    _originalPhotoUrls = dup ? [] : List.from(sale?.photoUrls ?? []);
    _scheduledDate = dup ? null : sale?.scheduledDate;
    _saleId = _isEditing
        ? sale!.id
        : FirebaseFirestore.instance.collection('_').doc().id;

    if (widget.sale != null) _loadBuyerForEdit();
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
    _itemDescController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _trackingCodeController.dispose();
    _postalCodeController.dispose();
    _newComponentController.dispose();
    super.dispose();
  }

  Future<void> _pickBuyer() async {
    if (_isEditing) return;
    final buyer = await Navigator.push<Buyer>(
      context,
      MaterialPageRoute(builder: (_) => const BuyerPickerScreen()),
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

  void _addComponent() {
    final name = _newComponentController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _components.add(ComponentItem(
        id: FirebaseFirestore.instance.collection('_').doc().id,
        name: name,
        isAvailable: false,
      ));
      _newComponentController.clear();
    });
  }

  void _toggleComponent(int index) {
    setState(() {
      final updated = List<ComponentItem>.from(_components);
      updated[index] = updated[index].copyWith(isAvailable: !updated[index].isAvailable);
      _applyComponentRule(updated);
    });
  }

  void _removeComponent(int index) {
    setState(() {
      final updated = List<ComponentItem>.from(_components)..removeAt(index);
      _applyComponentRule(updated);
    });
  }

  void _applyComponentRule(List<ComponentItem> updated) {
    _components = updated;
    _assemblyStatus = Sale.deriveAssemblyStatus(updated, _assemblyStatus);
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _cleanupOrphans() async {
    final toDelete = _isEditing
        ? _uploadedInSession
            .where((url) => !_photoUrls.contains(url))
            .toList()
        : List<String>.from(_photoUrls);
    for (final url in toDelete) {
      await _photoService.deletePhoto(_saleId, url);
    }
  }

  Future<void> _cancel() async {
    await _cleanupOrphans();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final s = context.s;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.buyerRequired)),
      );
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
        postalCode: _deliveryType == DeliveryType.shipping
            ? _nullIfEmpty(_postalCodeController.text)
            : null,
      );

      for (final url in _pendingDeletions) {
        await _photoService.deletePhoto(_saleId, url);
      }

      final notesValue = _nullIfEmpty(_notesController.text);

      if (_isEditing) {
        final updated = widget.sale!.copyWith(
          itemDescription: _itemDescController.text.trim(),
          price: double.parse(
              _priceController.text.trim().replaceAll(',', '.')),
          assemblyStatus: _assemblyStatus,
          components: _components,
          photoUrls: _photoUrls,
          payment: SalePayment(
              status: _paymentStatus, method: _paymentMethod),
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
          itemDescription: _itemDescController.text.trim(),
          photoUrls: _photoUrls,
          price: double.parse(
              _priceController.text.trim().replaceAll(',', '.')),
          assemblyStatus: _assemblyStatus,
          components: _components,
          payment: SalePayment(
              status: _paymentStatus, method: _paymentMethod),
          shipment: shipment,
          requiresNif: _requiresNif,
          scheduledDate: _scheduledDate,
          createdAt: DateTime.now(),
          notes: notesValue,
        );
        await _saleRepository.createSale(sale);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.errorSavingSaleMsg(e))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing
              ? s.editSale
              : widget.isDuplicate
                  ? s.duplicateSale
                  : s.newSale),
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
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              _SectionTitle(s.sectionBuyer),
              _BuyerSelector(
                buyer: _selectedBuyer,
                label: s.buyerLabel,
                placeholder: s.tapToSelectBuyer,
                isEditing: _isEditing,
                onTap: _pickBuyer,
              ),
              if (_selectedBuyerStats != null &&
                  _selectedBuyerStats!.saleCount > 0) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    s.previousSales(
                      _selectedBuyerStats!.saleCount,
                      _selectedBuyerStats!.lastPurchaseAt != null
                          ? DateFormat('MMM yyyy')
                              .format(_selectedBuyerStats!.lastPurchaseAt!)
                          : '',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SectionTitle(s.sectionItem),
              TextFormField(
                controller: _itemDescController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.descriptionLabel,
                  hintText: s.descriptionHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.descriptionRequired
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AssemblyStatus>(
                value: _assemblyStatus,
                decoration: InputDecoration(
                  labelText: s.assemblyStatusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: AssemblyStatus.values
                    .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(s.assemblyLabel(status))))
                    .toList(),
                onChanged: (v) => setState(() => _assemblyStatus = v!),
              ),
              const SizedBox(height: 16),
              _SectionTitle(s.sectionPhotos),
              PhotoGrid(
                saleId: _saleId,
                photoUrls: _photoUrls,
                onChanged: (urls) => setState(() => _photoUrls = urls),
                onPhotoAdded: (url) => _uploadedInSession.add(url),
                onPhotoRemoved: (url) {
                  if (_originalPhotoUrls.contains(url)) {
                    _pendingDeletions.add(url);
                  } else {
                    _photoService.deletePhoto(_saleId, url);
                    _uploadedInSession.remove(url);
                  }
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle(s.sectionComponents),
              ..._components.asMap().entries.map(
                    (entry) => CheckboxListTile(
                      title: Text(entry.value.name),
                      subtitle: Text(entry.value.isAvailable
                          ? s.haveIt
                          : s.needToBuy),
                      value: entry.value.isAvailable,
                      onChanged: (_) => _toggleComponent(entry.key),
                      secondary: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeComponent(entry.key),
                      ),
                    ),
                  ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newComponentController,
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
              const SizedBox(height: 24),
              _SectionTitle(s.sectionPayment),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.priceLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.priceRequired;
                  final parsed =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return s.invalidPrice;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: s.paymentMethodDropdownLabel,
                  border: const OutlineInputBorder(),
                ),
                items: PaymentMethod.values
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(s.paymentMethodLabel(m))))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(s.paid),
                value: _paymentStatus == PaymentStatus.paid,
                onChanged: (v) => setState(() => _paymentStatus =
                    v ? PaymentStatus.paid : PaymentStatus.unpaid),
              ),
              SwitchListTile(
                title: Text(s.requiresNifLabel),
                value: _requiresNif,
                onChanged: (v) => setState(() => _requiresNif = v),
              ),
              const SizedBox(height: 24),
              _SectionTitle(s.sectionDelivery),
              SegmentedButton<DeliveryType>(
                segments: [
                  ButtonSegment(
                      value: DeliveryType.shipping,
                      icon: const Icon(Icons.local_shipping),
                      label: Text(s.shipping)),
                  ButtonSegment(
                      value: DeliveryType.pickup,
                      icon: const Icon(Icons.store),
                      label: Text(s.pickup)),
                ],
                selected: {_deliveryType},
                onSelectionChanged: (v) =>
                    setState(() => _deliveryType = v.first),
              ),
              if (_deliveryType == DeliveryType.shipping) ...[
                const SizedBox(height: 16),
                if (_buyerAddresses.isNotEmpty) ...[
                  DropdownButtonFormField<BuyerAddress>(
                    value: _selectedAddress,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${_selectedAddress!.street}, ${_selectedAddress!.postalCode} ${_selectedAddress!.city}, ${_selectedAddress!.country}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.postalCodeLabel,
                    hintText: s.postalCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _deliveryType == DeliveryType.shipping
                      ? (v) {
                          if (v == null || v.trim().isEmpty) {
                            return s.postalCodeRequired;
                          }
                          final isPortugal =
                              (_selectedAddress?.country ?? 'Portugal') ==
                                  'Portugal';
                          if (isPortugal &&
                              !RegExp(r'^\d{4}-\d{3}$')
                                  .hasMatch(v.trim())) {
                            return 'Format: 0000-000';
                          }
                          return null;
                        }
                      : null,
                ),
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
              const SizedBox(height: 16),
              _ScheduledDatePicker(
                date: _scheduledDate,
                isPickup: _deliveryType == DeliveryType.pickup,
                onChanged: (date) => setState(() => _scheduledDate = date),
              ),
              const SizedBox(height: 24),
              _SectionTitle(s.sectionNotes),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.notesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledDatePicker extends StatelessWidget {
  final DateTime? date;
  final bool isPickup;
  final ValueChanged<DateTime?> onChanged;

  const _ScheduledDatePicker({
    required this.date,
    required this.isPickup,
    required this.onChanged,
  });

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
        ? '${isPickup ? s.readyBy : s.scheduledLabel}: ${dateFormat.format(date!)}'
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _BuyerSelector extends StatelessWidget {
  final Buyer? buyer;
  final String label;
  final String placeholder;
  final bool isEditing;
  final VoidCallback onTap;

  const _BuyerSelector({
    required this.buyer,
    required this.label,
    required this.placeholder,
    required this.isEditing,
    required this.onTap,
  });

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
