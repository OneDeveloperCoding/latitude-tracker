import 'package:flutter/material.dart';

import '../../../core/id_gen.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/discard_dialog.dart';
import '../models/buyer_address.dart';
import '../repositories/buyer_repository.dart';
import '../widgets/address_form_fields.dart';

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
  final _addressFormKey = GlobalKey<AddressFormFieldsState>();
  final _repository = BuyerRepository();

  bool _isLoading = false;

  bool get _isEditing => widget.address != null;

  bool get _hasChanges =>
      _addressFormKey.currentState?.hasChanges ?? false;

  Future<void> _onPopInvoked(bool didPop, _) async {
    if (didPop) return;
    if (!_hasChanges || (await showDiscardDialog(context) && mounted)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final addressState = _addressFormKey.currentState!;
      if (_isEditing) {
        final updated = addressState.buildAddress(widget.address!.id);
        await _repository.updateAddress(widget.buyerId, updated);
      } else {
        final id = newId();
        final address = addressState.buildAddress(id);
        await _repository.createAddress(widget.buyerId, address);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingAddressMsg(e))),
        );
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
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? s.editAddress : s.newAddress),
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
            AddressFormFields(
              key: _addressFormKey,
              initial: widget.address,
              showIsDefault: true,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
  }
}
