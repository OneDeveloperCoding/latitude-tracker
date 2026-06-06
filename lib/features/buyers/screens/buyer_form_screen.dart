import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/discard_dialog.dart';
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
  late final TextEditingController _notesController;
  late final TextEditingController _tagInputController;

  late List<String> _tags;
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
    _notesController = TextEditingController(text: widget.buyer?.notes ?? '');
    _tagInputController = TextEditingController();
    _tags = List<String>.from(widget.buyer?.tags ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instagramController.dispose();
    _phoneController.dispose();
    _nifController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagInputController.clear();
    });
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  bool get _hasChanges {
    if (_isEditing) {
      final b = widget.buyer!;
      return _nameController.text.trim() != b.name ||
          (_nullIfEmpty(_instagramController.text) ?? '') != (b.instagramHandle ?? '') ||
          (_nullIfEmpty(_phoneController.text) ?? '') != (b.phone ?? '') ||
          (_nullIfEmpty(_nifController.text) ?? '') != (b.nif ?? '') ||
          (_nullIfEmpty(_notesController.text) ?? '') != (b.notes ?? '') ||
          !listEquals(_tags, b.tags);
    }
    return _nameController.text.trim().isNotEmpty ||
        _instagramController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _nifController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _tags.isNotEmpty ||
        _addAddress;
  }

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
      final notesValue = _nullIfEmpty(_notesController.text);
      if (_isEditing) {
        final updated = widget.buyer!.copyWith(
          name: _nameController.text.trim(),
          instagramHandle: _nullIfEmpty(_instagramController.text),
          phone: _nullIfEmpty(_phoneController.text),
          nif: _nullIfEmpty(_nifController.text),
          tags: _tags,
          notes: notesValue,
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
          tags: _tags,
          notes: notesValue,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            const SizedBox(height: 24),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.tagsLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () =>
                              setState(() => _tags.remove(tag)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      hintText: s.addTagHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.buyerNotesHint,
                border: const OutlineInputBorder(),
              ),
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
    ),
  );
  }
}

