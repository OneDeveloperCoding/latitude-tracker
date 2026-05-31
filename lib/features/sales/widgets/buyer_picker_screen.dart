import 'package:flutter/material.dart';

import '../../buyers/models/buyer.dart';
import '../../buyers/repositories/buyer_repository.dart';

class BuyerPickerScreen extends StatefulWidget {
  const BuyerPickerScreen({super.key});

  @override
  State<BuyerPickerScreen> createState() => _BuyerPickerScreenState();
}

class _BuyerPickerScreenState extends State<BuyerPickerScreen> {
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
            (b.instagramHandle?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Buyer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search buyers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Buyer>>(
              stream: _repository.watchBuyers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final buyers = _filtered(snapshot.data ?? []);
                if (buyers.isEmpty) {
                  return const Center(child: Text('No buyers found.'));
                }
                return ListView.builder(
                  itemCount: buyers.length,
                  itemBuilder: (context, index) {
                    final buyer = buyers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(buyer.name[0].toUpperCase()),
                      ),
                      title: Text(buyer.name),
                      subtitle: buyer.instagramHandle != null
                          ? Text('@${buyer.instagramHandle}')
                          : null,
                      onTap: () => Navigator.pop(context, buyer),
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
