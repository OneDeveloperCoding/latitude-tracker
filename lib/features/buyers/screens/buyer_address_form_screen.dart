import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/buyer_address.dart';
import '../repositories/buyer_repository.dart';

const _kCountries = [
  'Portugal',
  'Spain',
  'France',
  'Germany',
  'United Kingdom',
  'Netherlands',
  'Belgium',
  'Italy',
  'Switzerland',
  'Other',
];

class BuyerAddressFormScreen extends StatefulWidget {
  final String buyerId;
  final BuyerAddress? address;

  const BuyerAddressFormScreen({
    super.key,
    required this.buyerId,
    this.address,
  });

  @override
  State<BuyerAddressFormScreen> createState() => _BuyerAddressFormScreenState();
}

class _BuyerAddressFormScreenState extends State<BuyerAddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BuyerRepository();

  late final TextEditingController _labelController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late String _country;
  late bool _isDefault;

  bool _isLoading = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label);
    _streetController = TextEditingController(text: widget.address?.street);
    _cityController = TextEditingController(text: widget.address?.city);
    _postalCodeController =
        TextEditingController(text: widget.address?.postalCode);
    final saved = widget.address?.country ?? 'Portugal';
    _country = _kCountries.contains(saved) ? saved : 'Other';
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = widget.address!.copyWith(
          label: _labelController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _country,
          isDefault: _isDefault,
        );
        await _repository.updateAddress(widget.buyerId, updated);
      } else {
        final address = BuyerAddress(
          id: FirebaseFirestore.instance.collection('_').doc().id,
          label: _labelController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _country,
          isDefault: _isDefault,
        );
        await _repository.createAddress(widget.buyerId, address);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Address' : 'New Address'),
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
            TextFormField(
              controller: _labelController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Label *',
                hintText: 'e.g. Home, Work',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Label is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Street *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Street is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'City is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Postal code *',
                hintText: '0000-000',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Postal code is required';
                }
                if (_country == 'Portugal' &&
                    !RegExp(r'^\d{4}-\d{3}$').hasMatch(v.trim())) {
                  return 'Format: 0000-000';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _country,
              decoration: const InputDecoration(
                labelText: 'Country *',
                border: OutlineInputBorder(),
              ),
              items: _kCountries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _country = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Default address'),
              subtitle: const Text('Pre-filled when creating a new sale'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
          ],
        ),
      ),
    );
  }
}
