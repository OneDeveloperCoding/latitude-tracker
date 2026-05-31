import 'package:flutter/material.dart';

import '../models/buyer.dart';
import '../models/buyer_address.dart';
import '../repositories/buyer_repository.dart';
import 'buyer_address_form_screen.dart';
import 'buyer_form_screen.dart';

class BuyerDetailScreen extends StatelessWidget {
  final String buyerId;

  const BuyerDetailScreen({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    final repository = BuyerRepository();

    return StreamBuilder<List<dynamic>>(
      stream: Stream.fromFuture(
        Future.wait([
          repository.getBuyer(buyerId).then((b) => b),
        ]),
      ),
      builder: (context, _) {
        return FutureBuilder<Buyer?>(
          future: repository.getBuyer(buyerId),
          builder: (context, snapshot) {
            final buyer = snapshot.data;

            return Scaffold(
              appBar: AppBar(
                title: Text(buyer?.name ?? 'Buyer'),
                actions: [
                  if (buyer != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuyerFormScreen(buyer: buyer),
                        ),
                      ),
                    ),
                ],
              ),
              body: buyer == null
                  ? const Center(child: CircularProgressIndicator())
                  : _BuyerDetailBody(buyer: buyer, repository: repository),
            );
          },
        );
      },
    );
  }
}

class _BuyerDetailBody extends StatelessWidget {
  final Buyer buyer;
  final BuyerRepository repository;

  const _BuyerDetailBody({required this.buyer, required this.repository});

  void _addAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerAddressFormScreen(buyerId: buyer.id),
      ),
    );
  }

  void _editAddress(BuildContext context, BuyerAddress address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BuyerAddressFormScreen(buyerId: buyer.id, address: address),
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    BuyerAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repository.deleteAddress(buyer.id, address.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(buyer: buyer),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Addresses', style: textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _addAddress(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<BuyerAddress>>(
          stream: repository.watchAddresses(buyer.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final addresses = snapshot.data ?? [];
            if (addresses.isEmpty) {
              return Text(
                'No addresses saved.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              );
            }
            return Column(
              children: addresses
                  .map((a) => _AddressTile(
                        address: a,
                        onEdit: () => _editAddress(context, a),
                        onDelete: () => _deleteAddress(context, a),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Buyer buyer;

  const _InfoSection({required this.buyer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (buyer.instagramHandle != null)
              _InfoRow(icon: Icons.alternate_email, text: '@${buyer.instagramHandle}'),
            if (buyer.phone != null)
              _InfoRow(icon: Icons.phone, text: buyer.phone!),
            if (buyer.nif != null)
              _InfoRow(icon: Icons.badge, text: 'NIF: ${buyer.nif}'),
            if (buyer.instagramHandle == null &&
                buyer.phone == null &&
                buyer.nif == null)
              const Text('No contact details saved.'),
          ],
        ),
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
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final BuyerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text(address.label),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('Default'),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${address.street}\n${address.postalCode} ${address.city}, ${address.country}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}
