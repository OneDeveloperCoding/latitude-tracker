import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/store/sales_store.dart';
import '../../buyers/models/buyer.dart';
import '../../sales/models/sale.dart';
import '../../sales/widgets/buyer_picker_screen.dart';
import '../../sales/widgets/category_picker.dart';
import '../../sales/widgets/payment_method_display.dart';
import 'package:intl/intl.dart';

import '../models/repair.dart';
import '../repositories/repair_repository.dart';
import '../services/repair_photo_service.dart';
import '../widgets/repair_photo_grid.dart';
import '../widgets/sale_picker_screen.dart';

class NewRepairScreen extends StatefulWidget {
  final Repair? existing;

  const NewRepairScreen({super.key, this.existing});

  @override
  State<NewRepairScreen> createState() => _NewRepairScreenState();
}

class _NewRepairScreenState extends State<NewRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  late final String _repairId;
  final _photoService = RepairPhotoService();

  // Contact
  Buyer? _linkedBuyer;
  final _freeTextController = TextEditingController();
  bool _useFreeText = false;

  // Item
  final _itemDescController = TextEditingController();
  String _itemCategory = '';

  // Problem & work
  final _problemController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _materialsCostController = TextEditingController();

  // Status & payment
  RepairStatus _status = RepairStatus.received;
  PaymentStatus _paymentStatus = PaymentStatus.unpaid;
  PaymentMethod _paymentMethod = PaymentMethod.mbWay;

  // Return delivery
  DeliveryType _returnType = DeliveryType.pickup;
  ShipmentStatus _returnStatus = ShipmentStatus.pending;
  final _trackingController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Linked sale
  Sale? _linkedSale;

  // Photos
  List<String> _photoUrls = [];
  final List<String> _sessionUploads = [];

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _repairId = existing.id;
      if (existing.isLinkedToBuyer) {
        _useFreeText = false;
        // Buyer object loaded lazily in form; we keep the ids
      } else {
        _useFreeText = true;
        _freeTextController.text = existing.freeTextContact ?? '';
      }
      _itemDescController.text = existing.itemDescription;
      _itemCategory = existing.itemCategory;
      _problemController.text = existing.problemDescription;
      _workDoneController.text = existing.workDone;
      if (existing.materialsCost != null) {
        _materialsCostController.text =
            existing.materialsCost!.toStringAsFixed(2);
      }
      _status = existing.status;
      _paymentStatus = existing.payment.status;
      _paymentMethod = existing.payment.method;
      _returnType = existing.returnDelivery.type;
      _returnStatus = existing.returnDelivery.status;
      _trackingController.text = existing.returnDelivery.trackingCode ?? '';
      _postalCodeController.text = existing.returnDelivery.postalCode ?? '';
      _photoUrls = List.from(existing.photoUrls);
      _linkedSale = existing.linkedSaleId != null
          ? (SalesStore.current ?? [])
              .where((s) => s.id == existing.linkedSaleId)
              .firstOrNull
          : null;
    } else {
      _repairId = _uuid.v4();
    }
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    _itemDescController.dispose();
    _problemController.dispose();
    _workDoneController.dispose();
    _materialsCostController.dispose();
    _trackingController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickBuyer() async {
    final buyer = await Navigator.of(context).push<Buyer>(
      MaterialPageRoute(builder: (_) => const BuyerPickerScreen()),
    );
    if (buyer != null) setState(() => _linkedBuyer = buyer);
  }

  Future<void> _pickSale() async {
    String? buyerId;
    String? buyerName;

    if (!_useFreeText) {
      buyerId = _linkedBuyer?.id ?? widget.existing?.buyerId;
      buyerName = _linkedBuyer?.name ?? widget.existing?.buyerName;
    }

    if (buyerId == null) {
      final buyer = await Navigator.of(context).push<Buyer>(
        MaterialPageRoute(builder: (_) => const BuyerPickerScreen()),
      );
      if (buyer == null || !mounted) return;
      buyerId = buyer.id;
      buyerName = buyer.name;
      // Filling the Contact section avoids the save guard blocking after this flow.
      if (!_useFreeText) setState(() => _linkedBuyer = buyer);
    }

    final sale = await Navigator.of(context).push<Sale>(
      MaterialPageRoute(
        builder: (_) => SalePickerScreen(
          buyerId: buyerId!,
          buyerName: buyerName ?? '',
        ),
      ),
    );
    if (sale != null && mounted) setState(() => _linkedSale = sale);
  }

  Future<void> _pickCategory() async {
    final cat = await showCategoryPicker(context, current: _itemCategory);
    if (cat != null) setState(() => _itemCategory = cat);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final contactOk = _useFreeText
        ? _freeTextController.text.trim().isNotEmpty
        : _linkedBuyer != null || (widget.existing?.isLinkedToBuyer ?? false);
    if (!contactOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.repairContactRequired)),
      );
      return;
    }

    if (_itemCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.categoryRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cost = _materialsCostController.text.trim().isEmpty
          ? null
          : double.tryParse(
              _materialsCostController.text.trim().replaceAll(',', '.'));

      final repair = Repair(
        id: _repairId,
        buyerId: _useFreeText ? null : (_linkedBuyer?.id ?? widget.existing?.buyerId),
        buyerName: _useFreeText
            ? null
            : (_linkedBuyer?.name ?? widget.existing?.buyerName),
        freeTextContact:
            _useFreeText ? _freeTextController.text.trim() : null,
        linkedSaleId: _linkedSale?.id,
        itemDescription: _itemDescController.text.trim(),
        itemCategory: _itemCategory,
        problemDescription: _problemController.text.trim(),
        workDone: _workDoneController.text.trim(),
        materialsCost: cost,
        status: _status,
        payment: SalePayment(status: _paymentStatus, method: _paymentMethod),
        returnDelivery: RepairReturnDelivery(
          type: _returnType,
          status: _returnStatus,
          trackingCode: _trackingController.text.trim().isEmpty
              ? null
              : _trackingController.text.trim(),
          postalCode: _returnType == DeliveryType.shipping &&
                  _postalCodeController.text.trim().isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
        ),
        photoUrls: _photoUrls,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      final repo = RepairRepository();
      if (_isEdit) {
        await repo.updateRepair(repair);
      } else {
        await repo.createRepair(repair);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${context.s.errorSavingRepair}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    // Delete only photos uploaded in this session on cancel
    for (final url in _sessionUploads) {
      await _photoService.deletePhoto(url);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.editRepair : s.newRepair),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : _cancel,
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _SectionHeader(label: s.repairSectionContact),
            _buildContactSection(s),
            const SizedBox(height: 16),
            _SectionHeader(label: s.repairSectionItem),
            _buildItemSection(s),
            const SizedBox(height: 16),
            _SectionHeader(label: s.repairSectionWork),
            _buildWorkSection(s),
            const SizedBox(height: 16),
            _SectionHeader(label: s.sectionPhotos),
            RepairPhotoGrid(
              repairId: _repairId,
              photoUrls: _photoUrls,
              onUploaded: (url) => setState(() {
                _photoUrls.add(url);
                _sessionUploads.add(url);
              }),
              onRemoved: (url) async {
                setState(() => _photoUrls.remove(url));
                if (_sessionUploads.contains(url)) {
                  await _photoService.deletePhoto(url);
                  _sessionUploads.remove(url);
                }
              },
            ),
            const SizedBox(height: 16),
            _SectionHeader(label: s.sectionPayment),
            _buildPaymentSection(s),
            const SizedBox(height: 16),
            _SectionHeader(label: s.repairSectionReturn),
            _buildReturnSection(s),
            const SizedBox(height: 16),
            _SectionHeader(label: s.repairSectionLinked),
            _buildLinkedSaleSection(s),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(s.repairContactFreeText),
          value: _useFreeText,
          onChanged: (v) => setState(() {
            _useFreeText = v;
            _linkedBuyer = null;
            _freeTextController.clear();
          }),
          contentPadding: EdgeInsets.zero,
        ),
        if (_useFreeText)
          TextFormField(
            controller: _freeTextController,
            decoration: InputDecoration(
              labelText: s.repairContact,
              hintText: s.repairContactHint,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? s.repairContactRequired : null,
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _linkedBuyer?.name ??
                  widget.existing?.buyerName ??
                  s.tapToSelectBuyer,
              style: _linkedBuyer == null && widget.existing?.buyerName == null
                  ? TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)
                  : null,
            ),
            subtitle: Text(s.repairContact),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickBuyer,
          ),
      ],
    );
  }

  Widget _buildItemSection(AppStrings s) {
    return Column(
      children: [
        TextFormField(
          controller: _itemDescController,
          decoration: InputDecoration(
            labelText: s.repairItemDescription,
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? s.repairItemDescriptionRequired
              : null,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _itemCategory.isEmpty ? s.categoryLabel : _itemCategory,
            style: _itemCategory.isEmpty
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)
                : null,
          ),
          subtitle: Text(s.categoryLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: _pickCategory,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _problemController,
          decoration: InputDecoration(
            labelText: s.repairProblemDescription,
          ),
          maxLines: 3,
          validator: (v) => v == null || v.trim().isEmpty
              ? s.repairProblemDescriptionRequired
              : null,
        ),
      ],
    );
  }

  Widget _buildWorkSection(AppStrings s) {
    return Column(
      children: [
        DropdownButtonFormField<RepairStatus>(
          initialValue: _status,
          decoration: InputDecoration(labelText: s.repairStatusLabel),
          items: RepairStatus.values
              .map((st) => DropdownMenuItem(
                    value: st,
                    child: Text(s.repairStatusLabelFor(st)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _workDoneController,
          decoration: InputDecoration(labelText: s.repairWorkDone),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _materialsCostController,
          decoration: InputDecoration(labelText: s.repairMaterialsCost),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(AppStrings s) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(s.paid),
          value: _paymentStatus == PaymentStatus.paid,
          onChanged: (v) => setState(() =>
              _paymentStatus = v ? PaymentStatus.paid : PaymentStatus.unpaid),
          contentPadding: EdgeInsets.zero,
        ),
        DropdownButtonFormField<PaymentMethod>(
          initialValue: _paymentMethod,
          decoration:
              InputDecoration(labelText: s.paymentMethodDropdownLabel),
          items: kPaymentMethodOrder
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: PaymentMethodDropdownItem(m),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _paymentMethod = v!),
        ),
      ],
    );
  }

  Widget _buildReturnSection(AppStrings s) {
    return Column(
      children: [
        SegmentedButton<DeliveryType>(
          segments: [
            ButtonSegment(
                value: DeliveryType.shipping, label: Text(s.shipping)),
            ButtonSegment(value: DeliveryType.pickup, label: Text(s.pickup)),
          ],
          selected: {_returnType},
          onSelectionChanged: (v) =>
              setState(() => _returnType = v.first),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ShipmentStatus>(
          initialValue: _returnStatus,
          decoration: InputDecoration(labelText: s.repairStatusLabel),
          items: ShipmentStatus.values
              .map((st) => DropdownMenuItem(
                    value: st,
                    child: Text(s.shipmentStatusLabel(st)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _returnStatus = v!),
        ),
        if (_returnType == DeliveryType.shipping) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _trackingController,
            decoration: InputDecoration(
              labelText: s.cttTrackingLabel,
              hintText: s.cttTrackingHint,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _postalCodeController,
            decoration: InputDecoration(
              labelText: s.postalCodeLabel,
              hintText: s.postalCodeHint,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLinkedSaleSection(AppStrings s) {
    final linked = _linkedSale;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        linked != null
            ? '${DateFormat('dd MMM yyyy').format(linked.createdAt)}${linked.items.isNotEmpty ? ' · ${linked.items.first.description}' : ''}'
            : s.repairLinkedSaleNone,
        style: linked == null
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(s.repairLinkedSale),
      trailing: linked != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _linkedSale = null),
            )
          : const Icon(Icons.chevron_right),
      onTap: linked == null ? _pickSale : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

