import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../models/buyer.dart';
import '../repositories/buyer_repository.dart';
import '../widgets/address_form_fields.dart';

class BuyerFormScreen extends StatefulWidget {
  final Buyer? buyer;

  const BuyerFormScreen({super.key, this.buyer});

  @override
  State<BuyerFormScreen> createState() => _BuyerFormScreenState();
}

class _BuyerFormScreenState extends State<BuyerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BuyerRepository();
  final _addressFormKey = GlobalKey<AddressFormFieldsState>();

  late final TextEditingController _nameController;
  late final TextEditingController _instagramController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nifController;

  bool _addAddress = false;
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
    super.dispose();
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

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

        final addressState = _addressFormKey.currentState;
        if (_addAddress && (addressState?.isFilled ?? false)) {
          final address = addressState!.buildAddress(
            FirebaseFirestore.instance.collection('_').doc().id,
          );
          await _repository.createAddress(buyer.id, address);
        }

        if (mounted) Navigator.pop(context, buyer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingBuyerMsg(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editBuyer : s.newBuyer),
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
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: '${s.buyerNameLabel} *',
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.buyerNameRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instagramController,
              decoration: InputDecoration(
                labelText: s.instagramHandleLabel,
                prefixText: '@',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.phoneNumberLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nifController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.nifLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (v.trim().length != 9) return s.nifInvalid;
                return null;
              },
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 24),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.addShippingAddress),
                subtitle: Text(s.addShippingAddressSubtitle),
                value: _addAddress,
                onChanged: (v) => setState(() => _addAddress = v),
              ),
              if (_addAddress) ...[
                const SizedBox(height: 8),
                AddressFormFields(key: _addressFormKey),
              ],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
