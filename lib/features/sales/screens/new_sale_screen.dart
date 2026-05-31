import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../buyers/models/buyer.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../widgets/buyer_picker_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleRepository = SaleRepository();
  final _buyerRepository = BuyerRepository();

  Buyer? _selectedBuyer;
  List<BuyerAddress> _buyerAddresses = [];
  BuyerAddress? _selectedAddress;

  final _itemDescController = TextEditingController();
  final _priceController = TextEditingController();
  final _trackingCodeController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _newComponentController = TextEditingController();

  AssemblyStatus _assemblyStatus = AssemblyStatus.notStarted;
  PaymentMethod _paymentMethod = PaymentMethod.mbWay;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  DeliveryType _deliveryType = DeliveryType.shipping;
  bool _requiresNif = false;
  bool _isLoading = false;

  final List<ComponentItem> _components = [];

  @override
  void dispose() {
    _itemDescController.dispose();
    _priceController.dispose();
    _trackingCodeController.dispose();
    _postalCodeController.dispose();
    _newComponentController.dispose();
    super.dispose();
  }

  Future<void> _pickBuyer() async {
    final buyer = await Navigator.push<Buyer>(
      context,
      MaterialPageRoute(builder: (_) => const BuyerPickerScreen()),
    );
    if (buyer == null) return;

    final addresses = await _buyerRepository
        .watchAddresses(buyer.id)
        .first;

    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull;

    setState(() {
      _selectedBuyer = buyer;
      _buyerAddresses = addresses;
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

  void _removeComponent(int index) {
    setState(() => _components.removeAt(index));
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
      final sale = Sale(
        id: FirebaseFirestore.instance.collection('_').doc().id,
        buyerId: _selectedBuyer!.id,
        buyerName: _selectedBuyer!.name,
        itemDescription: _itemDescController.text.trim(),
        price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
        assemblyStatus: _assemblyStatus,
        components: _components,
        payment: SalePayment(status: _paymentStatus, method: _paymentMethod),
        shipment: SaleShipment(
          type: _deliveryType,
          status: ShipmentStatus.pending,
          trackingCode: _deliveryType == DeliveryType.shipping
              ? _nullIfEmpty(_trackingCodeController.text)
              : null,
          addressId: _selectedAddress?.id,
          postalCode: _nullIfEmpty(_postalCodeController.text),
        ),
        requiresNif: _requiresNif,
        createdAt: DateTime.now(),
      );
      await _saleRepository.createSale(sale);
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

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
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
              onTap: _pickBuyer,
            ),
            if (_selectedBuyer != null && _buyerAddresses.isNotEmpty) ...[
              const SizedBox(height: 8),
              _requiresNif
                  ? Text('NIF: ${_selectedBuyer!.nif ?? 'not saved on profile'}',
                      style: Theme.of(context).textTheme.bodySmall)
                  : const SizedBox.shrink(),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssemblyStatus>(
              value: _assemblyStatus,
              decoration: const InputDecoration(
                labelText: 'Assembly status',
                border: OutlineInputBorder(),
              ),
              items: AssemblyStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _assemblyStatus = v!),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Components needed'),
            ..._components.asMap().entries.map((entry) => CheckboxListTile(
                  title: Text(entry.value.name),
                  subtitle: Text(entry.value.isAvailable ? 'Have it' : 'Need to buy'),
                  value: entry.value.isAvailable,
                  onChanged: (_) => _toggleComponent(entry.key),
                  secondary: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeComponent(entry.key),
                  ),
                )),
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
                if (parsed == null || parsed <= 0) return 'Enter a valid price';
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
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m.label)))
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
                  decoration: const InputDecoration(
                    labelText: 'Ship to address',
                    border: OutlineInputBorder(),
                  ),
                  items: _buyerAddresses
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                                '${a.label} — ${a.street}, ${a.city}'),
                          ))
                      .toList(),
                  onChanged: (a) => setState(() {
                    _selectedAddress = a;
                    if (a != null) {
                      _postalCodeController.text = a.postalCode;
                    }
                  }),
                ),
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
                        if (!RegExp(r'^\d{4}-\d{3}$').hasMatch(v.trim())) {
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
            const SizedBox(height: 32),
          ],
        ),
      ),
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
  final VoidCallback onTap;

  const _BuyerSelector({required this.buyer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Buyer *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_forward_ios, size: 16),
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
