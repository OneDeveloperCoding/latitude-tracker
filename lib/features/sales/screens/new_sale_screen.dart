import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  const NewSaleScreen({super.key, this.sale});

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

  bool get _isEditing => widget.sale != null;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    _itemDescController =
        TextEditingController(text: sale?.itemDescription ?? '');
    _notesController = TextEditingController(text: sale?.notes ?? '');
    _priceController = TextEditingController(
        text: sale != null ? sale.price.toStringAsFixed(2) : '');
    _trackingCodeController =
        TextEditingController(text: sale?.shipment.trackingCode ?? '');
    _postalCodeController =
        TextEditingController(text: sale?.shipment.postalCode ?? '');
    _assemblyStatus = sale?.assemblyStatus ?? AssemblyStatus.notStarted;
    _paymentMethod = sale?.payment.method ?? PaymentMethod.mbWay;
    _paymentStatus = sale?.payment.status ?? PaymentStatus.unpaid;
    _deliveryType = sale?.shipment.type ?? DeliveryType.shipping;
    _requiresNif = sale?.requiresNif ?? false;
    _components = List.from(sale?.components ?? []);
    _photoUrls = List.from(sale?.photoUrls ?? []);
    _originalPhotoUrls = List.from(sale?.photoUrls ?? []);
    _scheduledDate = sale?.scheduledDate;
    _saleId = sale?.id ??
        FirebaseFirestore.instance.collection('_').doc().id;

    if (_isEditing) _loadBuyerForEdit();
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
      final c = _components[index];
      _components[index] = c.copyWith(isAvailable: !c.isAvailable);
    });
  }

  void _removeComponent(int index) =>
      setState(() => _components.removeAt(index));

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  /// On cancel: delete photos uploaded in this session that were never saved.
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBuyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a buyer')),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving sale: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sale' : 'New Sale'),
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
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Buyer'),
            _BuyerSelector(
              buyer: _selectedBuyer,
              isEditing: _isEditing,
              onTap: _pickBuyer,
            ),
            if (_selectedBuyerStats != null &&
                _selectedBuyerStats!.saleCount > 0) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${_selectedBuyerStats!.saleCount} previous sale${_selectedBuyerStats!.saleCount == 1 ? '' : 's'}'
                  '${_selectedBuyerStats!.lastPurchaseAt != null ? ' · last: ${DateFormat('MMM yyyy').format(_selectedBuyerStats!.lastPurchaseAt!)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SectionTitle('Item'),
            TextFormField(
              controller: _itemDescController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g. Silver necklace with blue beads',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssemblyStatus>(
              value: _assemblyStatus,
              decoration: const InputDecoration(
                labelText: 'Assembly status',
                border: OutlineInputBorder(),
              ),
              items: AssemblyStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _assemblyStatus = v!),
            ),
            const SizedBox(height: 16),
            _SectionTitle('Photos'),
            PhotoGrid(
              saleId: _saleId,
              photoUrls: _photoUrls,
              onChanged: (urls) => setState(() => _photoUrls = urls),
              onPhotoAdded: (url) => _uploadedInSession.add(url),
              onPhotoRemoved: (url) {
                if (_originalPhotoUrls.contains(url)) {
                  _pendingDeletions.add(url);
                } else {
                  // Uploaded in this session and immediately removed — delete now
                  _photoService.deletePhoto(_saleId, url);
                  _uploadedInSession.remove(url);
                }
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle('Components needed'),
            ..._components.asMap().entries.map(
                  (entry) => CheckboxListTile(
                    title: Text(entry.value.name),
                    subtitle: Text(
                        entry.value.isAvailable ? 'Have it' : 'Need to buy'),
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
                    decoration: const InputDecoration(
                      hintText: 'Add component...',
                      border: OutlineInputBorder(),
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
            _SectionTitle('Payment'),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (€) *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                final parsed =
                    double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Paid'),
              value: _paymentStatus == PaymentStatus.paid,
              onChanged: (v) => setState(() => _paymentStatus =
                  v ? PaymentStatus.paid : PaymentStatus.unpaid),
            ),
            SwitchListTile(
              title: const Text('Requires NIF receipt'),
              value: _requiresNif,
              onChanged: (v) => setState(() => _requiresNif = v),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Delivery'),
            SegmentedButton<DeliveryType>(
              segments: const [
                ButtonSegment(
                    value: DeliveryType.shipping,
                    icon: Icon(Icons.local_shipping),
                    label: Text('Shipping')),
                ButtonSegment(
                    value: DeliveryType.pickup,
                    icon: Icon(Icons.store),
                    label: Text('Pickup')),
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
                  decoration: const InputDecoration(
                    labelText: 'Ship to address',
                    border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Postal code *',
                  hintText: '0000-000',
                  border: OutlineInputBorder(),
                ),
                validator: _deliveryType == DeliveryType.shipping
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Postal code is required';
                        }
                        final isPortugal =
                            (_selectedAddress?.country ?? 'Portugal') ==
                                'Portugal';
                        if (isPortugal &&
                            !RegExp(r'^\d{4}-\d{3}$').hasMatch(v.trim())) {
                          return 'Format: 0000-000';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _trackingCodeController,
                decoration: const InputDecoration(
                  labelText: 'CTT tracking code',
                  hintText: 'Fill in after dropping off at CTT',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ScheduledDatePicker(
              date: _scheduledDate,
              onChanged: (date) => setState(() => _scheduledDate = date),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Notes'),
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Gift wrap, colour preference, special instructions...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}

class _ScheduledDatePicker extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _ScheduledDatePicker({required this.date, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    return Row(
      children: [
        const Icon(Icons.event, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            date != null
                ? 'Scheduled: ${dateFormat.format(date!)}'
                : 'No scheduled date',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(date != null ? 'Change' : 'Set date'),
        ),
        if (date != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Clear'),
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
  final bool isEditing;
  final VoidCallback onTap;

  const _BuyerSelector({
    required this.buyer,
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
          labelText: 'Buyer *',
          border: const OutlineInputBorder(),
          suffixIcon: isEditing
              ? null
              : const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        child: Text(
          buyer?.name ?? 'Tap to select a buyer',
          style: buyer == null
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );
  }
}
