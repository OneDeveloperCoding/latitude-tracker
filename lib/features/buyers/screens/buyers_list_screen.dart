import 'package:flutter/material.dart';

import '../models/buyer.dart';
import '../repositories/buyer_repository.dart';
import 'buyer_detail_screen.dart';
import 'buyer_form_screen.dart';

class BuyersListScreen extends StatefulWidget {
  const BuyersListScreen({super.key});

  @override
  State<BuyersListScreen> createState() => _BuyersListScreenState();
}

class _BuyersListScreenState extends State<BuyersListScreen> {
  final _repository = BuyerRepository();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Buyer> _filtered(List<Buyer> buyers) {
    if (_searchQuery.isEmpty) return buyers;
    final query = _searchQuery.toLowerCase();
    return buyers
        .where((b) =>
            b.name.toLowerCase().contains(query) ||
            (b.instagramHandle?.toLowerCase().contains(query) ?? false) ||
            (b.phone?.contains(query) ?? false))
        .toList();
  }

  void _openBuyer(BuildContext context, Buyer buyer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BuyerDetailScreen(buyerId: buyer.id)),
    );
  }

  void _addBuyer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuyerFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buyers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBuyer(context),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search buyers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Buyer>>(
              stream: _repository.watchBuyers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final buyers = _filtered(snapshot.data ?? []);
                if (buyers.isEmpty) {
                  return const Center(
                    child: Text('No buyers yet. Tap + to add one.'),
                  );
                }
                return ListView.builder(
                  itemCount: buyers.length,
                  itemBuilder: (context, index) {
                    final buyer = buyers[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(buyer.name[0].toUpperCase())),
                      title: Text(buyer.name),
                      subtitle: buyer.instagramHandle != null
                          ? Text('@${buyer.instagramHandle}')
                          : buyer.phone != null
                              ? Text(buyer.phone!)
                              : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openBuyer(context, buyer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
