import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/buyer.dart';
import '../repositories/buyer_repository.dart';

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
        if (mounted) Navigator.pop(context, buyer);
        return;
      }
      if (mounted) Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }
}
