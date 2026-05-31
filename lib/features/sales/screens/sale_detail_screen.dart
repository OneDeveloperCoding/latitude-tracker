import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../buyers/models/buyer_address.dart';
import '../../buyers/repositories/buyer_repository.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
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
            title: Text(sale?.buyerName ?? 'Sale'),
            actions: [
              if (sale != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewSaleScreen(sale: sale),
                    ),
                  ),
                ),
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
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(children: [
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
            const _InfoRow(icon: Icons.badge, text: 'NIF receipt required'),
        ]),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Assembly',
          child: DropdownButton<AssemblyStatus>(
            value: sale.assemblyStatus,
            isExpanded: true,
            underline: const SizedBox(),
            items: AssemblyStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => _update(
              context,
              sale.copyWith(assemblyStatus: v),
            ),
          ),
        ),
        if (sale.components.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Components',
            child: Column(
              children: sale.components.map((c) {
                return CheckboxListTile(
                  dense: true,
                  title: Text(c.name),
                  subtitle:
                      Text(c.isAvailable ? 'Have it' : 'Need to buy'),
                  value: c.isAvailable,
                  onChanged: (_) {
                    final updated = sale.components
                        .map((item) => item.id == c.id
                            ? item.copyWith(isAvailable: !item.isAvailable)
                            : item)
                        .toList();
                    _update(context, sale.copyWith(components: updated));
                  },
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Payment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sale.payment.method.label),
                  _StatusChip(
                    label: sale.payment.status == PaymentStatus.paid
                        ? 'Paid'
                        : 'Unpaid',
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
                title: const Text('Mark as paid'),
                value: sale.payment.status == PaymentStatus.paid,
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(
                    payment: sale.payment.copyWith(
                      status:
                          v ? PaymentStatus.paid : PaymentStatus.unpaid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Scheduled delivery',
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
          title: 'Delivery',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sale.shipment.type == DeliveryType.shipping
                      ? 'Shipping'
                      : 'In-person pickup'),
                  _StatusChip(
                    label: sale.shipment.status.label,
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
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => _update(
                  context,
                  sale.copyWith(shipment: sale.shipment.copyWith(status: v)),
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
    if (!_editing && _controller.text.isEmpty) {
      return TextButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.add),
        label: const Text('Add CTT tracking code'),
      );
    }

    if (_editing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'CTT tracking code',
                border: OutlineInputBorder(),
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
            onTap: () => _openCttTracking(_controller.text),
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
          icon: const Icon(Icons.edit, size: 16),
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }

  Future<void> _openCttTracking(String code) async {
    final uri = Uri.parse(
      'https://www.ctt.pt/feapl_2/app/open/objectSearch/objectSearch.jspx?codObjeto=$code',
    );
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
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    if (date == null) {
      return TextButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.event),
        label: const Text('Set scheduled date'),
      );
    }
    return Row(
      children: [
        const Icon(Icons.event, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(dateFormat.format(date!))),
        TextButton(
          onPressed: () => _pick(context),
          child: const Text('Change'),
        ),
        TextButton(
          onPressed: () => onChanged(null),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _AddressDisplay extends StatelessWidget {
  final String buyerId;
  final String addressId;
  final String? postalCode;

  const _AddressDisplay({
    required this.buyerId,
    required this.addressId,
    this.postalCode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BuyerAddress>>(
      stream: BuyerRepository().watchAddresses(buyerId),
      builder: (context, snapshot) {
        final address = snapshot.data
            ?.where((a) => a.id == addressId)
            .firstOrNull;
        if (address == null) {
          return postalCode != null
              ? _InfoRow(icon: Icons.location_on, text: postalCode!)
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

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
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
