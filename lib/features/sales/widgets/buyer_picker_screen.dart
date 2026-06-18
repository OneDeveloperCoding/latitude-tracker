import 'package:flutter/material.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/buyers/models/buyer.dart';
import 'package:latitude_tracker/features/buyers/repositories/buyer_repository.dart';
import 'package:latitude_tracker/features/buyers/screens/buyer_form_screen.dart';

class BuyerPickerScreen extends StatefulWidget {
  const BuyerPickerScreen({super.key});

  @override
  State<BuyerPickerScreen> createState() => _BuyerPickerScreenState();
}

class _BuyerPickerScreenState extends State<BuyerPickerScreen> {
  final _repository = BuyerRepository();
  late final Stream<List<Buyer>> _stream;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _stream = _repository.watchBuyers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Buyer> _filtered(List<Buyer> buyers) {
    if (_searchQuery.isEmpty) return buyers;
    final query = _searchQuery.toLowerCase();
    return buyers
        .where(
          (b) =>
              b.name.toLowerCase().contains(query) ||
              (b.instagramHandle?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _createAndPickBuyer() async {
    final buyer = await Navigator.push<Buyer>(
      context,
      MaterialPageRoute<Buyer>(builder: (_) => const BuyerFormScreen()),
    );
    if (buyer != null && mounted) {
      Navigator.pop(context, buyer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.selectBuyer)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _createAndPickBuyer,
        icon: const Icon(Icons.person_add),
        label: Text(s.newBuyer),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s.searchBuyers,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Buyer>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(context.s.errorLoadingDetail));
                }
                final buyers = _filtered(snapshot.data ?? []);
                if (buyers.isEmpty) {
                  return Center(child: Text(s.noBuyersFound));
                }
                return ListView.builder(
                  itemCount: buyers.length,
                  itemBuilder: (context, index) {
                    final buyer = buyers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          buyer.name.isNotEmpty
                              ? buyer.name[0].toUpperCase()
                              : '?',
                        ),
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
