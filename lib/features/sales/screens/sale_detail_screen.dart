import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../../buyers/screens/buyer_detail_screen.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../widgets/photo_grid.dart';
import 'new_sale_screen.dart';

class SaleDetailScreen extends StatelessWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    final repository = SaleRepository();

    return StreamBuilder<Sale?>(
      stream: repository.watchSale(saleId),
      builder: (context, snapshot) {
        final sale = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(sale?.buyerName ?? context.s.saleFallbackTitle),
            actions: [
              if (sale != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewSaleScreen(sale: sale),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: context.s.duplicateSaleTooltip,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NewSaleScreen(sale: sale, isDuplicate: true),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.s.deleteSaleTooltip,
                  onPressed: () =>
                      _confirmDelete(context, sale, repository),
                ),
              ],
            ],
          ),
          body: sale == null
              ? const Center(child: CircularProgressIndicator())
              : _SaleDetailBody(sale: sale, repository: repository),
        );
      },
    );
  }
}

Future<void> _confirmDelete(
    BuildContext context, Sale sale, SaleRepository repository) async {
  final s = context.s;
  final shipped = sale.shipment.status == ShipmentStatus.shipped ||
      sale.shipment.status == ShipmentStatus.delivered;
  final paid = sale.payment.status == PaymentStatus.paid;

  final String title;
  final String message;

  if (shipped) {
    title = s.deleteShippedSaleTitle;
    final statusLabel = sale.shipment.status == ShipmentStatus.delivered
        ? s.delivered
        : s.shippedStatus;
    message = s.deleteShippedSaleBody(
        statusLabel, sale.atSubmissionDone, sale.photoUrls.length);
  } else if (paid) {
    title = s.deletePaidSaleTitle;
    message = s.deletePaidSaleBody(sale.price, sale.photoUrls.length);
  } else {
    title = s.deleteSaleTitle;
    message = s.deleteSaleBody(sale.photoUrls.length);
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: Text(s.delete),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    await repository.deleteSale(sale.id);
    if (context.mounted) Navigator.of(context).pop();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.errorDeletingSaleMsg(e))));
    }
  }
}

class _SaleDetailBody extends StatelessWidget {
  final Sale sale;
  final SaleRepository repository;

  const _SaleDetailBody({required this.sale, required this.repository});

  Future<void> _update(BuildContext context, Sale updated) async {
    try {
      await repository.updateSale(updated);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.s.errorMsg(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      children: [
        if (sale.photoUrls.isNotEmpty) ...[
          _SectionCard(
            title: s.sectionPhotos,
            child: PhotoGrid(
              saleId: sale.id,
              photoUrls: sale.photoUrls,
              onChanged: (urls) =>
                  _update(context, sale.copyWith(photoUrls: urls)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _InfoCard(children: [
          _InfoRow(
            icon: Icons.person,
            text: sale.buyerName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuyerDetailScreen(buyerId: sale.buyerId),
              ),
            ),
          ),
          _InfoRow(
            icon: Icons.calendar_today,
            text: dateFormat.format(sale.createdAt),
          ),
          _InfoRow(
            icon: Icons.description,
            text: sale.itemDescription,
          ),
          _InfoRow(
            icon: Icons.euro,
            text: '€${sale.price.toStringAsFixed(2)}',
          ),
          if (sale.requiresNif)
            _InfoRow(icon: Icons.badge, text: s.nifReceiptRequiredInfo),
          if (sale.requiresNif && sale.payment.status == PaymentStatus.paid)
            _InfoRow(
              icon: sale.atSubmissionDone
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              text: sale.atSubmissionDone
                  ? s.atReceiptFiled
                  : s.atReceiptPending,
              color: sale.atSubmissionDone ? Colors.green : Colors.orange,
              onTap: () => _update(
                context,
                sale.copyWith(
                    atSubmissionDone: !sale.atSubmissionDone),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.assemblyLegendHeader,
          child: DropdownButton<AssemblyStatus>(
            value: sale.assemblyStatus,
            isExpanded: true,
            underline: const SizedBox(),
            items: AssemblyStatus.values
                .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(s.assemblyLabel(status))))
                .toList(),
            onChanged: (v) => _update(
              context,
              sale.copyWith(assemblyStatus: v),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ComponentsCard(sale: sale, onUpdate: _update),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionPayment,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.paymentMethodLabel(sale.payment.method)),
                  _StatusChip(
                    label: sale.payment.status == PaymentStatus.paid
                        ? s.paid
                        : s.unpaid,
                    color: sale.payment.status == PaymentStatus.paid
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(s.markAsPaidLabel),
                value: sale.payment.status == PaymentStatus.paid,
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(
                    payment: sale.payment.copyWith(
                      status: v ? PaymentStatus.paid : PaymentStatus.unpaid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: sale.shipment.type == DeliveryType.pickup
              ? s.readyBy
              : s.scheduledLabel,
          child: _ScheduledDateField(
            date: sale.scheduledDate,
            onChanged: (date) => _update(
              context,
              sale.copyWith(scheduledDate: date),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionDelivery,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sale.shipment.type == DeliveryType.shipping
                      ? s.shipping
                      : s.inPersonPickup),
                  _StatusChip(
                    label: s.shipmentStatusLabel(sale.shipment.status),
                    color: sale.shipment.status == ShipmentStatus.delivered
                        ? Colors.green
                        : sale.shipment.status == ShipmentStatus.shipped
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButton<ShipmentStatus>(
                value: sale.shipment.status,
                isExpanded: true,
                underline: const SizedBox(),
                items: _availableStatuses(sale.shipment)
                    .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(s.shipmentStatusLabel(status))))
                    .toList(),
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(
                      shipment: sale.shipment.copyWith(status: v)),
                ),
              ),
              if (sale.shipment.type == DeliveryType.shipping) ...[
                const SizedBox(height: 8),
                if (sale.shipment.addressId != null)
                  _AddressDisplay(
                    buyerId: sale.buyerId,
                    addressId: sale.shipment.addressId!,
                    postalCode: sale.shipment.postalCode,
                  )
                else if (sale.shipment.postalCode != null)
                  _InfoRow(
                    icon: Icons.location_on,
                    text: sale.shipment.postalCode!,
                  ),
                _TrackingCodeField(
                  initialValue: sale.shipment.trackingCode ?? '',
                  onSave: (code) => _update(
                    context,
                    sale.copyWith(
                        shipment: sale.shipment.copyWith(
                      trackingCode: code.isEmpty ? null : code,
                    )),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: s.sectionNotes,
          child: _NotesField(
            initialValue: sale.notes ?? '',
            onSave: (text) => _update(
              context,
              sale.copyWith(notes: text.isEmpty ? null : text),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<ShipmentStatus> _availableStatuses(SaleShipment shipment) {
    if (shipment.type == DeliveryType.pickup) {
      return [ShipmentStatus.pending, ShipmentStatus.delivered];
    }
    return ShipmentStatus.values;
  }
}

class _TrackingCodeField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _TrackingCodeField({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_TrackingCodeField> createState() => _TrackingCodeFieldState();
}

class _TrackingCodeFieldState extends State<_TrackingCodeField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addCttTracking),
      );
    }

    if (_editing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: s.cttTrackingLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onSave(_controller.text.trim());
              setState(() => _editing = false);
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.local_shipping, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyCode(context),
            onLongPress: () => _openCttTracking(_controller.text),
            child: Text(
              _controller.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share, size: 16),
          tooltip: s.shareTracking,
          onPressed: _shareTracking,
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new, size: 16),
          tooltip: s.openOnCtt,
          onPressed: () => _openCttTracking(_controller.text),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }

  Uri _cttUri(String code) => Uri.parse(
        'https://www.ctt.pt/feapl_2/app/open/objectSearch/objectSearch.jspx?codObjeto=$code',
      );

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.trackingCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareTracking() async {
    final code = _controller.text;
    final url = _cttUri(code);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Olá! O teu envio tem o código de rastreamento $code.'
            ' Podes acompanhar aqui: $url',
      ),
    );
  }

  Future<void> _openCttTracking(String code) async {
    final uri = _cttUri(code);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ScheduledDateField extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _ScheduledDateField({required this.date, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final first = DateTime(DateTime.now().year - 5);
    final last = DateTime(DateTime.now().year + 2, 12, 31);
    final initial = date == null
        ? DateTime.now()
        : date!.isBefore(first)
            ? first
            : date!.isAfter(last)
                ? last
                : date!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    if (date == null) {
      return TextButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event),
        label: Text(s.setScheduledDate),
      );
    }
    return Row(
      children: [
        const Icon(Icons.event, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(dateFormat.format(date!))),
        TextButton(
          onPressed: () => _pick(context),
          child: Text(s.change),
        ),
        TextButton(
          onPressed: () => onChanged(null),
          child: Text(s.clear),
        ),
      ],
    );
  }
}

class _AddressDisplay extends StatefulWidget {
  final String buyerId;
  final String addressId;
  final String? postalCode;

  const _AddressDisplay({
    required this.buyerId,
    required this.addressId,
    this.postalCode,
  });

  @override
  State<_AddressDisplay> createState() => _AddressDisplayState();
}

class _AddressDisplayState extends State<_AddressDisplay> {
  late Stream<List<BuyerAddress>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = BuyerRepository().watchAddresses(widget.buyerId);
  }

  @override
  void didUpdateWidget(_AddressDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buyerId != widget.buyerId) {
      _stream = BuyerRepository().watchAddresses(widget.buyerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BuyerAddress>>(
      stream: _stream,
      builder: (context, snapshot) {
        final address = snapshot.data
            ?.where((a) => a.id == widget.addressId)
            .firstOrNull;
        if (address == null) {
          return widget.postalCode != null
              ? _InfoRow(icon: Icons.location_on, text: widget.postalCode!)
              : const SizedBox.shrink();
        }
        return _InfoRow(
          icon: Icons.location_on,
          text:
              '${address.street}, ${address.postalCode} ${address.city}, ${address.country}',
        );
      },
    );
  }
}

class _ComponentsCard extends StatefulWidget {
  final Sale sale;
  final void Function(BuildContext, Sale) onUpdate;

  const _ComponentsCard({required this.sale, required this.onUpdate});

  @override
  State<_ComponentsCard> createState() => _ComponentsCardState();
}

class _ComponentsCardState extends State<_ComponentsCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final updated = [
      ...widget.sale.components,
      ComponentItem(
        id: FirebaseFirestore.instance.collection('_').doc().id,
        name: name,
        isAvailable: false,
      ),
    ];
    widget.onUpdate(context, widget.sale.copyWith(components: updated));
    setState(() => _controller.clear());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sale = widget.sale;
    return _SectionCard(
      title: s.sectionComponents,
      child: Column(
        children: [
          ...sale.components.map((c) => Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  final updatedComponents = sale.components
                      .where((item) => item.id != c.id)
                      .toList();
                  AssemblyStatus newStatus = sale.assemblyStatus;
                  if (updatedComponents.isNotEmpty &&
                      updatedComponents.every((item) => item.isAvailable) &&
                      (sale.assemblyStatus == AssemblyStatus.notStarted ||
                          sale.assemblyStatus == AssemblyStatus.inProgress)) {
                    newStatus = AssemblyStatus.ready;
                  }
                  widget.onUpdate(
                    context,
                    sale.copyWith(
                        components: updatedComponents,
                        assemblyStatus: newStatus),
                  );
                },
                child: CheckboxListTile(
                  dense: true,
                  title: Text(c.name),
                  subtitle:
                      Text(c.isAvailable ? s.haveIt : s.needToBuy),
                  value: c.isAvailable,
                  onChanged: (_) {
                    final toggled = !c.isAvailable;
                    final updatedComponents = sale.components
                        .map((item) => item.id == c.id
                            ? item.copyWith(isAvailable: toggled)
                            : item)
                        .toList();
                    final allAvailable =
                        updatedComponents.every((item) => item.isAvailable);
                    AssemblyStatus newStatus = sale.assemblyStatus;
                    if (toggled &&
                        allAvailable &&
                        (sale.assemblyStatus == AssemblyStatus.notStarted ||
                            sale.assemblyStatus ==
                                AssemblyStatus.inProgress)) {
                      newStatus = AssemblyStatus.ready;
                    } else if (!toggled &&
                        sale.assemblyStatus == AssemblyStatus.ready) {
                      newStatus = AssemblyStatus.inProgress;
                    }
                    widget.onUpdate(
                      context,
                      sale.copyWith(
                          components: updatedComponents,
                          assemblyStatus: newStatus),
                    );
                  },
                ),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: s.addComponentHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final Color? color;

  const _InfoRow(
      {required this.icon, required this.text, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (onTap != null)
            Icon(Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(4), child: row);
  }
}

class _NotesField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _NotesField({required this.initialValue, required this.onSave});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: Text(s.addNotes),
      );
    }

    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: s.notesHintDetail,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _controller.text = widget.initialValue;
                  setState(() => _editing = false);
                },
                child: Text(s.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  widget.onSave(_controller.text.trim());
                  setState(() => _editing = false);
                },
                child: Text(s.save),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(_controller.text)),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }
}
