import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/buyer.dart';
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

class BuyerFormScreen extends StatefulWidget {
  final Buyer? buyer;

  const BuyerFormScreen({super.key, this.buyer});

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BuyerRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _instagramController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nifController;

  // Quick address fields — only shown when creating a new buyer
  bool _addAddress = false;
  final _labelController = TextEditingController(text: 'Home');
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  String _quickAddressCountry = 'Portugal';

  bool _isLoading = false;

  bool get _isEditing => widget.buyer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.buyer?.name);
    _instagramController =
        TextEditingController(text: widget.buyer?.instagramHandle);
    _phoneController = TextEditingController(text: widget.buyer?.phone);
    _nifController = TextEditingController(text: widget.buyer?.nif);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instagramController.dispose();
    _phoneController.dispose();
    _nifController.dispose();
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  bool get _addressFilled =>
      _streetController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _postalCodeController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = widget.buyer!.copyWith(
          name: _nameController.text.trim(),
          instagramHandle: _nullIfEmpty(_instagramController.text),
          phone: _nullIfEmpty(_phoneController.text),
          nif: _nullIfEmpty(_nifController.text),
        );
        await _repository.updateBuyer(updated);
        if (mounted) Navigator.pop(context);
      } else {
        final buyer = Buyer(
          id: FirebaseFirestore.instance.collection('_').doc().id,
          name: _nameController.text.trim(),
          instagramHandle: _nullIfEmpty(_instagramController.text),
          phone: _nullIfEmpty(_phoneController.text),
          nif: _nullIfEmpty(_nifController.text),
          createdAt: DateTime.now(),
        );
        await _repository.createBuyer(buyer);

        if (_addAddress && _addressFilled) {
          final address = BuyerAddress(
            id: FirebaseFirestore.instance.collection('_').doc().id,
            label: _labelController.text.trim().isEmpty
                ? 'Home'
                : _labelController.text.trim(),
            street: _streetController.text.trim(),
            city: _cityController.text.trim(),
            postalCode: _postalCodeController.text.trim(),
            country: _quickAddressCountry,
            isDefault: true,
          );
          await _repository.createAddress(buyer.id, address);
        }

        if (mounted) Navigator.pop(context, buyer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving buyer: $e')),
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
        title: Text(_isEditing ? 'Edit Buyer' : 'New Buyer'),
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
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram handle',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nifController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NIF',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length != 9) return 'NIF must be 9 digits';
                return null;
              },
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 24),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add shipping address'),
                subtitle: const Text('Optional — can be added later'),
                value: _addAddress,
                onChanged: (v) => setState(() => _addAddress = v),
              ),
              if (_addAddress) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _labelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. Home, Work',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _streetController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Street *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _addAddress && (v == null || v.trim().isEmpty)
                      ? 'Street is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _addAddress && (v == null || v.trim().isEmpty)
                      ? 'City is required'
                      : null,
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
                    if (!_addAddress) return null;
                    if (v == null || v.trim().isEmpty) {
                      return 'Postal code is required';
                    }
                    if (_quickAddressCountry == 'Portugal' &&
                        !RegExp(r'^\d{4}-\d{3}$').hasMatch(v.trim())) {
                      return 'Format: 0000-000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _quickAddressCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  items: _kCountries
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _quickAddressCountry = v!),
                ),
              ],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
