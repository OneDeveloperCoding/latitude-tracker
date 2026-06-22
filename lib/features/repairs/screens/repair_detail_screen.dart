import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latitude_tracker/core/id_gen.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/store/sales_store.dart';
import 'package:latitude_tracker/core/widgets/status_indicator_strip.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_detail_screen.dart';
import 'package:latitude_tracker/features/repairs/models/repair.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';
import 'package:latitude_tracker/features/repairs/services/repair_photo_service.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_photo_grid.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_colors.dart';
import 'package:latitude_tracker/features/repairs/widgets/repair_status_dots.dart';
import 'package:latitude_tracker/features/repairs/widgets/sale_picker_screen.dart';
import 'package:latitude_tracker/features/sales/models/sale.dart';
import 'package:latitude_tracker/features/sales/screens/sale_detail_screen.dart';
import 'package:latitude_tracker/features/sales/widgets/buyer_picker_screen.dart';
import 'package:latitude_tracker/features/sales/widgets/category_picker.dart';
import 'package:latitude_tracker/features/sales/widgets/payment_method_display.dart';
import 'package:latitude_tracker/features/sales/widgets/photo_grid.dart';
import 'package:latitude_tracker/features/sales/widgets/sale_status_dots.dart';

class RepairDetailScreen extends StatefulWidget {
  const RepairDetailScreen({
    required this.repairId,
    this.editModeSignal,
    super.key,
  });

  final String repairId;

  /// Incrementing this notifier from outside (e.g. tablet FAB) triggers edit
  /// mode on the currently displayed repair.
  final ValueNotifier<int>? editModeSignal;

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  // ── stream ─────────────────────────────────────────────────────────────────
  late final RepairRepository _repository;
  late final Stream<Repair?> _stream;
  bool _popping = false;
  Repair? _lastKnownRepair;

  // ── edit mode ──────────────────────────────────────────────────────────────
  // Lazily initialized so Firebase isn't accessed until edit mode is entered.
  RepairPhotoService? _photoService;
  RepairPhotoService get _lazyPhotoService =>
      _photoService ??= RepairPhotoService();

  bool _isEditing = false;
  bool _isSaving = false;

  // Item
  final _itemDescController = TextEditingController();
  String _editItemCategory = '';

  // Problem & work
  final _problemController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _materialsCostController = TextEditingController();

  // Status & payment
  RepairStatus _editStatus = RepairStatus.received;
  PaymentStatus _editPaymentStatus = PaymentStatus.unpaid;
  PaymentMethod _editPaymentMethod = PaymentMethod.mbWay;

  // Return delivery
  DeliveryType _editReturnType = DeliveryType.pickup;
  ShipmentStatus _editReturnStatus = ShipmentStatus.pending;
  final _trackingController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Linked sale
  Sale? _editLinkedSale;

  // Photos
  List<String> _editPhotoUrls = [];
  final List<String> _sessionUploads = [];

  @override
  void initState() {
    super.initState();
    _repository = RepairRepository();
    _stream = _repository.watchRepair(widget.repairId);
    widget.editModeSignal?.addListener(_onEditModeSignal);
  }

  @override
  void dispose() {
    widget.editModeSignal?.removeListener(_onEditModeSignal);
    _itemDescController.dispose();
    _problemController.dispose();
    _workDoneController.dispose();
    _materialsCostController.dispose();
    _trackingController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _onEditModeSignal() {
    final repair = _lastKnownRepair;
    if (repair == null || _isEditing) return;
    _enterEditMode(repair);
  }

  // ── edit lifecycle ─────────────────────────────────────────────────────────

  void _enterEditMode(Repair repair) {
    setState(() {
      _isEditing = true;

      _itemDescController.text = repair.itemDescription;
      _editItemCategory = repair.itemCategory;
      _problemController.text = repair.problemDescription;
      _workDoneController.text = repair.workDone;
      _materialsCostController.text =
          repair.materialsCost != null
              ? repair.materialsCost!.toStringAsFixed(2)
              : '';

      _editStatus = repair.status;
      _editPaymentStatus = repair.payment.status;
      _editPaymentMethod = repair.payment.method;

      _editReturnType = repair.returnDelivery.type;
      _editReturnStatus = repair.returnDelivery.status;
      _trackingController.text = repair.returnDelivery.trackingCode ?? '';
      _postalCodeController.text = repair.returnDelivery.postalCode ?? '';

      _editLinkedSale = repair.linkedSaleId != null
          ? SalesStore.currentOrEmpty
              .where((s) => s.id == repair.linkedSaleId)
              .firstOrNull
          : null;

      _editPhotoUrls = List.from(repair.photoUrls);
    });
  }

  Future<void> _confirmCancelEdit(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.discardChanges),
        content: Text(s.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.discard),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _cancelEdit();
  }

  Future<void> _cancelEdit() async {
    for (final url in _sessionUploads) {
      try {
        await _lazyPhotoService.deletePhoto(url);
      } on Object catch (e, st) {
        logError(e, st);
      }
    }
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _isSaving = false;
      _editPhotoUrls = [];
      _sessionUploads.clear();
    });
  }

  Future<void> _saveEdit(BuildContext context) async {
    final s = context.s;
    if (_itemDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.repairItemDescriptionRequired)),
      );
      return;
    }
    if (_editItemCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.categoryRequired)),
      );
      return;
    }
    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.repairProblemDescriptionRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repair = _lastKnownRepair!;
      final cost = _materialsCostController.text.trim().isEmpty
          ? null
          : double.tryParse(
              _materialsCostController.text.trim().replaceAll(',', '.'),
            );
      final updated = repair.copyWith(
        itemDescription: _itemDescController.text.trim(),
        itemCategory: _editItemCategory,
        problemDescription: _problemController.text.trim(),
        workDone: _workDoneController.text.trim(),
        materialsCost: cost,
        status: _editStatus,
        payment: SalePayment(
          status: _editPaymentStatus,
          method: _editPaymentMethod,
        ),
        returnDelivery: RepairReturnDelivery(
          type: _editReturnType,
          status: _editReturnStatus,
          trackingCode: _nullIfEmpty(_trackingController.text),
          postalCode: _editReturnType == DeliveryType.shipping
              ? _nullIfEmpty(_postalCodeController.text)
              : null,
        ),
        linkedSaleId: _editLinkedSale?.id,
        photoUrls: _editPhotoUrls,
      );
      await _repository.updateRepair(updated);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _editPhotoUrls = [];
        _sessionUploads.clear();
      });
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingRepair)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── linked sale picker ─────────────────────────────────────────────────────

  Future<void> _pickLinkedSale(BuildContext context, Repair repair) async {
    String? buyerId;
    String? buyerName;

    if (repair.isLinkedToBuyer) {
      buyerId = repair.buyerId;
      buyerName = repair.buyerName;
    }

    if (buyerId == null) {
      // Free-text contact: must pick a buyer first to browse their sales.
      final buyer = await Navigator.of(context).push<Buyer>(
        MaterialPageRoute<Buyer>(
          builder: (_) => const BuyerPickerScreen(),
        ),
      );
      if (buyer == null || !context.mounted) return;
      buyerId = buyer.id;
      buyerName = buyer.name;
    }

    if (!context.mounted) return;
    final sale = await Navigator.of(context).push<Sale>(
      MaterialPageRoute<Sale>(
        builder: (_) => SalePickerScreen(
          buyerId: buyerId!,
          buyerName: buyerName ?? '',
        ),
      ),
    );
    if (sale != null && mounted) setState(() => _editLinkedSale = sale);
  }

  // ── read-mode operations ───────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context, Repair repair) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteRepairTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await _repository.deleteRepair(repair.id);
      if (context.mounted) {
        setState(() => _popping = true);
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.s.errorDeletingRepair}: $e')),
        );
      }
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  List<ShipmentStatus> _availableReturnStatuses(DeliveryType type) {
    if (type == DeliveryType.pickup || type == DeliveryType.handDelivery) {
      return [ShipmentStatus.pending, ShipmentStatus.delivered];
    }
    return ShipmentStatus.values;
  }

  // ── AppBars ────────────────────────────────────────────────────────────────

  AppBar _buildReadAppBar(BuildContext context, Repair repair) {
    return AppBar(
      title: Text(repair.itemDescription),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: context.s.deleteRepair,
          onPressed: () => _confirmDelete(context, repair),
        ),
      ],
    );
  }

  AppBar _buildEditAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _confirmCancelEdit(context),
      ),
      title: Text(context.s.editRepair),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => _saveEdit(context),
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.s.save),
        ),
      ],
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Repair?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.s.errorLoadingDetail)),
          );
        }
        final repair = snapshot.data;
        if (repair == null) {
          if (!_popping &&
              snapshot.connectionState != ConnectionState.waiting) {
            _popping = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!_isEditing) _lastKnownRepair = repair;

        return PopScope(
          canPop: !_isEditing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmCancelEdit(context));
          },
          child: Scaffold(
            appBar: _isEditing
                ? _buildEditAppBar(context)
                : _buildReadAppBar(context, repair),
            floatingActionButton: _isEditing
                ? null
                : FloatingActionButton(
                    tooltip: context.s.editRepair,
                    onPressed: () => _enterEditMode(repair),
                    child: const Icon(Icons.edit),
                  ),
            body: _isEditing
                ? _buildEditBody(context, repair)
                : _RepairDetailReadBody(
                    repair: repair,
                    onDelete: _confirmDelete,
                  ),
          ),
        );
      },
    );
  }

  // ── edit body ──────────────────────────────────────────────────────────────

  Widget _buildEditBody(BuildContext context, Repair repair) {
    final s = context.s;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        // ── Contact (locked) ────────────────────────────────────────────────
        _FormCard(
          title: s.repairSectionContact,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: s.repairContact,
              border: const OutlineInputBorder(),
            ),
            child: Text(repair.contactName),
          ),
        ),
        const SizedBox(height: 12),

        // ── Item ────────────────────────────────────────────────────────────
        _FormCard(
          title: s.repairSectionItem,
          child: Column(
            children: [
              TextFormField(
                controller: _itemDescController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.repairItemDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _editItemCategory.isEmpty
                      ? s.categoryPickerHint
                      : _editItemCategory,
                  style: _editItemCategory.isEmpty
                      ? TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                subtitle: Text(s.categoryLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final cat = await showCategoryPicker(
                    context,
                    current: _editItemCategory,
                  );
                  if (cat != null) setState(() => _editItemCategory = cat);
                },
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _problemController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.repairProblemDescription,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Work ────────────────────────────────────────────────────────────
        _FormCard(
          title: s.repairSectionWork,
          child: Column(
            children: [
              DropdownButtonFormField<RepairStatus>(
                initialValue: _editStatus,
                decoration: InputDecoration(
                  labelText: s.repairStatusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: RepairStatus.values
                    .map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text(s.repairStatusLabelFor(st)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _editStatus = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _workDoneController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: s.repairWorkDone,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _materialsCostController,
                decoration: InputDecoration(
                  labelText: s.repairMaterialsCost,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Photos ──────────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionPhotos,
          child: RepairPhotoGrid(
            repairId: widget.repairId,
            photoUrls: _editPhotoUrls,
            onUploaded: (url) => setState(() {
              _editPhotoUrls.add(url);
              _sessionUploads.add(url);
            }),
            onRemoved: (url) async {
              setState(() => _editPhotoUrls.remove(url));
              if (_sessionUploads.contains(url)) {
                await _lazyPhotoService.deletePhoto(url);
                _sessionUploads.remove(url);
              }
              // Pre-existing photos removed from the list are orphaned in
              // Storage until the repair is deleted — acceptable given the
              // small size and that deleteRepair cleans the whole folder.
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── Payment ─────────────────────────────────────────────────────────
        _FormCard(
          title: s.sectionPayment,
          child: Column(
            children: [
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _editPaymentMethod,
                decoration: InputDecoration(
                  labelText: s.paymentMethodDropdownLabel,
                  border: const OutlineInputBorder(),
                ),
                items: kPaymentMethodOrder
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: PaymentMethodDropdownItem(m),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _editPaymentMethod = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.paid),
                value: _editPaymentStatus == PaymentStatus.paid,
                onChanged: (v) => setState(
                  () => _editPaymentStatus =
                      v ? PaymentStatus.paid : PaymentStatus.unpaid,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Return Delivery ─────────────────────────────────────────────────
        _FormCard(
          title: s.repairSectionReturn,
          child: Column(
            children: [
              SegmentedButton<DeliveryType>(
                segments: [
                  ButtonSegment(
                    value: DeliveryType.shipping,
                    label: Text(s.shipping),
                  ),
                  ButtonSegment(
                    value: DeliveryType.pickup,
                    label: Text(s.pickup),
                  ),
                  ButtonSegment(
                    value: DeliveryType.handDelivery,
                    icon: const Icon(Icons.directions_walk),
                    label: Text(s.handDelivery),
                  ),
                ],
                selected: {_editReturnType},
                onSelectionChanged: (v) {
                  final newType = v.first;
                  final statuses = _availableReturnStatuses(newType);
                  setState(() {
                    _editReturnType = newType;
                    if (!statuses.contains(_editReturnStatus)) {
                      _editReturnStatus = ShipmentStatus.pending;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShipmentStatus>(
                key: ValueKey(_editReturnType),
                initialValue: _editReturnStatus,
                decoration: InputDecoration(
                  labelText: s.repairReturnStatusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _availableReturnStatuses(_editReturnType)
                    .map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text(s.shipmentStatusLabel(st)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _editReturnStatus = v!),
              ),
              if (_editReturnType == DeliveryType.shipping) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _trackingController,
                  decoration: InputDecoration(
                    labelText: s.cttTrackingLabel,
                    hintText: s.cttTrackingHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.postalCodeLabel,
                    hintText: s.postalCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Linked Sale ─────────────────────────────────────────────────────
        _FormCard(
          title: s.repairSectionLinked,
          child: _EditLinkedSaleRow(
            linkedSale: _editLinkedSale,
            onPick: () => _pickLinkedSale(context, repair),
            onClear: () => setState(() => _editLinkedSale = null),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Read-only detail body ────────────────────────────────────────────────────

class _RepairDetailReadBody extends StatelessWidget {
  const _RepairDetailReadBody({
    required this.repair,
    required this.onDelete,
  });

  final Repair repair;
  final Future<void> Function(BuildContext, Repair) onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _SectionCard(
          title: s.repairSectionContact,
          children: [_ContactRow(repair: repair)],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: s.sectionPayment,
          indicator: paymentDot(repair.payment, colorScheme),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                repair.payment.status == PaymentStatus.paid
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: repair.payment.status == PaymentStatus.paid
                    ? Colors.green
                    : colorScheme.error,
              ),
              title: Text(
                repair.payment.status == PaymentStatus.paid
                    ? s.paid
                    : s.unpaid,
              ),
              subtitle: Text(s.paymentMethodLabel(repair.payment.method)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: s.repairSectionItem,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(repair.itemDescription),
              subtitle: Text(repair.itemCategory),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.report_problem_outlined),
              title: Text(repair.problemDescription),
              subtitle: Text(s.repairProblemLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat('dd MMM yyyy').format(repair.createdAt),
              ),
              subtitle: Text(s.receivedLabel),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: s.repairSectionWork,
          indicator: repairWorkDot(repair.status, colorScheme),
          children: [
            _ReadRepairStatusChips(repair: repair),
            if (repair.workDone.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(repair.workDone),
                subtitle: Text(s.repairWorkDone),
              ),
            if (repair.materialsCost != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handyman_outlined),
                title: Text('€${repair.materialsCost!.toStringAsFixed(2)}'),
                subtitle: Text(s.repairMaterialsCost),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: s.repairSectionReturn,
          indicator: contextualReturnDeliveryDot(repair, colorScheme),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(switch (repair.returnDelivery.type) {
                DeliveryType.shipping => s.shipping,
                DeliveryType.pickup => s.inPersonPickup,
                DeliveryType.handDelivery => s.handDelivery,
              }),
              subtitle: Text(
                s.shipmentStatusLabel(repair.returnDelivery.status),
              ),
            ),
            if (repair.returnDelivery.trackingCode != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code),
                title: Text(repair.returnDelivery.trackingCode!),
                subtitle: Text(s.cttTrackingLabel),
              ),
            _ReturnDeliveryActions(repair: repair),
          ],
        ),
        if (repair.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: s.sectionPhotos,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: repair.photoUrls
                      .asMap()
                      .entries
                      .map(
                        (e) => PhotoThumbnail(
                          url: e.value,
                          size: 80,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PhotoViewer(
                                urls: repair.photoUrls,
                                initialIndex: e.key,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
        if (repair.linkedSaleId != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: s.repairSectionLinked,
            children: [_LinkedSaleRow(saleId: repair.linkedSaleId!)],
          ),
        ],
      ],
    );
  }
}

// ── Read-only RepairStatus display ───────────────────────────────────────────

class _ReadRepairStatusChips extends StatelessWidget {
  const _ReadRepairStatusChips({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.repairStatusLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RepairStatus.values.map((status) {
              final (color, onColor) =
                  repairStatusContainerColors(status, cs);
              final isSelected = status == repair.status;
              return ChoiceChip(
                label: Text(s.repairStatusLabelFor(status)),
                selected: isSelected,
                selectedColor: color,
                labelStyle: isSelected ? TextStyle(color: onColor) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Contact row (read mode) ──────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (repair.isLinkedToBuyer) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: Text(repair.contactName),
        subtitle: Text(s.buyer),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BuyerDetailScreen(buyerId: repair.buyerId!),
          ),
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(repair.contactName),
      subtitle: Text(s.repairContactFreeText),
      trailing: TextButton(
        onPressed: () => _promoteToBuyer(context),
        child: Text(s.promoteToBuyer),
      ),
    );
  }

  Future<void> _promoteToBuyer(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.promoteToBuyerTitle),
        content: Text(s.promoteToBuyerBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.promoteToBuyer),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final newBuyer = Buyer(
        id: newId(),
        name: repair.freeTextContact!,
        createdAt: DateTime.now(),
      );
      await BuyerRepository().createBuyer(newBuyer);

      final updated = Repair(
        id: repair.id,
        buyerId: newBuyer.id,
        buyerName: newBuyer.name,
        linkedSaleId: repair.linkedSaleId,
        itemDescription: repair.itemDescription,
        itemCategory: repair.itemCategory,
        problemDescription: repair.problemDescription,
        workDone: repair.workDone,
        materialsCost: repair.materialsCost,
        status: repair.status,
        payment: repair.payment,
        returnDelivery: repair.returnDelivery,
        photoUrls: repair.photoUrls,
        createdAt: repair.createdAt,
      );
      await RepairRepository().updateRepair(updated);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.promotedToBuyerMsg(newBuyer.name))),
        );
      }
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingRepair)),
        );
      }
    }
  }
}

// ── Linked sale row (read mode) ──────────────────────────────────────────────

class _LinkedSaleRow extends StatelessWidget {
  const _LinkedSaleRow({required this.saleId});

  final String saleId;

  @override
  Widget build(BuildContext context) {
    final sale = SalesStore.currentOrEmpty
        .where((s) => s.id == saleId)
        .firstOrNull;
    final title = sale != null
        ? '${sale.buyerName} — ${sale.items.first.description}'
        : saleId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.sell_outlined),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SaleDetailScreen(saleId: saleId),
        ),
      ),
    );
  }
}

// ── Linked sale row (edit mode) ──────────────────────────────────────────────

class _EditLinkedSaleRow extends StatelessWidget {
  const _EditLinkedSaleRow({
    required this.linkedSale,
    required this.onPick,
    required this.onClear,
  });

  final Sale? linkedSale;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final linked = linkedSale;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        linked != null
            ? () {
                final date =
                    DateFormat('dd MMM yyyy').format(linked.createdAt);
                final item = linked.items.isNotEmpty
                    ? ' · ${linked.items.first.description}'
                    : '';
                return '$date$item';
              }()
            : s.repairLinkedSaleNone,
        style: linked == null
            ? TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(s.repairLinkedSale),
      trailing: linked != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            )
          : const Icon(Icons.chevron_right),
      onTap: linked == null ? onPick : null,
    );
  }
}

// ── Return delivery quick actions (read mode) ────────────────────────────────

class _ReturnDeliveryActions extends StatefulWidget {
  const _ReturnDeliveryActions({required this.repair});

  final Repair repair;

  @override
  State<_ReturnDeliveryActions> createState() => _ReturnDeliveryActionsState();
}

class _ReturnDeliveryActionsState extends State<_ReturnDeliveryActions> {
  bool _isUpdating = false;

  Future<void> _advance() async {
    final repair = widget.repair;
    final delivery = repair.returnDelivery;
    final nextStatus =
        delivery.type == DeliveryType.shipping &&
                delivery.status == ShipmentStatus.pending
            ? ShipmentStatus.shipped
            : ShipmentStatus.delivered;

    setState(() => _isUpdating = true);
    try {
      await RepairRepository().updateRepair(
        repair.copyWith(
          returnDelivery: delivery.copyWith(status: nextStatus),
          status: nextStatus == ShipmentStatus.delivered
              ? RepairStatus.returned
              : null,
        ),
      );
    } on Object catch (e, st) {
      logError(e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorSavingRepair)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;
    if (repair.status != RepairStatus.done &&
        repair.status != RepairStatus.returned) {
      return const SizedBox.shrink();
    }

    final delivery = repair.returnDelivery;
    if (delivery.status == ShipmentStatus.delivered) {
      return const SizedBox.shrink();
    }

    final s = context.s;
    final isShippingPending = delivery.type == DeliveryType.shipping &&
        delivery.status == ShipmentStatus.pending;
    final label = isShippingPending ? s.markAsSent : s.markAsDelivered;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: FilledButton.tonal(
          onPressed: _isUpdating ? null : _advance,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }
}

// ── Section card (read mode) ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.indicator,
  });

  final String title;
  final List<Widget> children;
  final StatusIndicatorDot? indicator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (indicator != null) ...[
                  Icon(indicator!.icon, size: 16, color: indicator!.color),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Form card (edit mode) ────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
