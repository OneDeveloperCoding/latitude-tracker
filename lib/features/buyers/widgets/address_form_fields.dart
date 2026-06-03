import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/services/postal_code_service.dart';
import '../models/buyer_address.dart';

const kAddressCountries = [
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

final _ptPostalCodeRegex = RegExp(r'^\d{4}-\d{3}$');

class AddressFormFields extends StatefulWidget {
  final BuyerAddress? initial;
  final bool showIsDefault;

  const AddressFormFields({
    super.key,
    this.initial,
    this.showIsDefault = false,
  });

  @override
  State<AddressFormFields> createState() => AddressFormFieldsState();
}

class AddressFormFieldsState extends State<AddressFormFields> {
  late final TextEditingController _labelController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _streetController;
  late final TextEditingController _houseNumberController;
  late final TextEditingController _fractionController;
  late final TextEditingController _notesController;
  late String _country;
  late bool _isDefault;

  bool _isLookingUp = false;
  String? _lastLookedUp;
  bool _cityAutoFilled = false;
  bool _streetAutoFilled = false;

  bool get isFilled =>
      _postalCodeController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _streetController.text.trim().isNotEmpty &&
      _houseNumberController.text.trim().isNotEmpty;

  BuyerAddress buildAddress(String id) => BuyerAddress(
        id: id,
        label: _labelController.text.trim().isEmpty
            ? context.s.addressDefaultLabel
            : _labelController.text.trim(),
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        fraction: _fractionController.text.trim().isEmpty
            ? null
            : _fractionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _country,
        isDefault: _isDefault,
      );

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _labelController = TextEditingController(text: a?.label);
    _postalCodeController = TextEditingController(text: a?.postalCode);
    _cityController = TextEditingController(text: a?.city);
    _streetController = TextEditingController(text: a?.street);
    _houseNumberController = TextEditingController(text: a?.houseNumber);
    _fractionController = TextEditingController(text: a?.fraction);
    _notesController = TextEditingController(text: a?.notes);
    final saved = a?.country ?? 'Portugal';
    _country = kAddressCountries.contains(saved) ? saved : 'Other';
    _isDefault = a?.isDefault ?? false;
    _lastLookedUp = a?.postalCode;
    _postalCodeController.addListener(_onPostalCodeChanged);
  }

  @override
  void dispose() {
    _postalCodeController.removeListener(_onPostalCodeChanged);
    _labelController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _fractionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPostalCodeChanged() {
    if (_country != 'Portugal') return;
    final code = _postalCodeController.text.trim();
    if (!_ptPostalCodeRegex.hasMatch(code)) {
      _clearAutoFilledFields();
      return;
    }
    if (code == _lastLookedUp) return;
    _lookup(code);
  }

  void _clearAutoFilledFields() {
    if (_cityAutoFilled) {
      _cityController.clear();
      _cityAutoFilled = false;
    }
    if (_streetAutoFilled) {
      _streetController.clear();
      _streetAutoFilled = false;
    }
    _lastLookedUp = null;
  }

  Future<void> _lookup(String postalCode) async {
    if (!mounted) return;
    setState(() {
      _isLookingUp = true;
      _lastLookedUp = postalCode;
    });

    final result = await PostalCodeService.lookup(postalCode);
    if (!mounted) return;
    setState(() => _isLookingUp = false);
    // Country changed while request was in-flight — ignore result silently.
    if (_country != 'Portugal') return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.postalCodeNoResults)),
      );
      return;
    }

    if (result.city.isNotEmpty) {
      _cityController.text = result.city;
      _cityAutoFilled = true;
    }

    if (result.streets.length == 1) {
      if (_streetController.text.trim().isEmpty) {
        _streetController.text = result.streets.first;
        _streetAutoFilled = true;
      }
    } else if (result.streets.length > 1) {
      final chosen = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => _StreetPickerSheet(streets: result.streets),
      );
      if (!mounted) return;
      if (chosen != null) {
        _streetController.text = chosen;
        _streetAutoFilled = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        TextFormField(
          controller: _labelController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: s.addressLabelField,
            hintText: s.addressLabelHint,
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.addressLabelRequired : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _country,
          decoration: InputDecoration(
            labelText: s.addressCountry,
            border: const OutlineInputBorder(),
          ),
          items: kAddressCountries
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(s.countryDisplayNames[c] ?? c),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _country = v!;
            // Allow re-lookup if user switches back to Portugal.
            _lastLookedUp = null;
          }),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: s.postalCodeLabel,
            hintText: s.postalCodeHint,
            border: const OutlineInputBorder(),
            suffixIcon: _isLookingUp
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return s.postalCodeRequired;
            if (_country == 'Portugal' &&
                !_ptPostalCodeRegex.hasMatch(v.trim())) {
              return s.postalCodeInvalidFormat;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: s.addressCity,
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.addressCityRequired : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: s.addressStreet,
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? s.addressStreetRequired : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _houseNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: s.addressHouseNumber,
            hintText: s.addressHouseNumberHint,
            border: const OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? s.addressHouseNumberRequired
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fractionController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: s.addressFraction,
            hintText: s.addressFractionHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: s.addressNotes,
            hintText: s.addressNotesHint,
            border: const OutlineInputBorder(),
          ),
        ),
        if (widget.showIsDefault) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.defaultAddressLabel),
            subtitle: Text(s.defaultAddressSubtitle),
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
        ],
      ],
    );
  }
}

class _StreetPickerSheet extends StatelessWidget {
  final List<String> streets;

  const _StreetPickerSheet({required this.streets});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              context.s.selectStreet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...streets.map(
            (street) => ListTile(
              title: Text(street),
              onTap: () => Navigator.pop(context, street),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
