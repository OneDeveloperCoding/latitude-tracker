import 'package:flutter/material.dart';

class DemoTutorialSheet extends StatelessWidget {
  const DemoTutorialSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DemoTutorialSheet(),
    );
  }

  static const _tips = [
    _Tip(
      icon: Icons.dashboard_outlined,
      color: Color(0xFF6750A4),
      title: 'Dashboard',
      body:
          'Your month at a glance — total sales, revenue, and pending actions. Warning cards at the top surface unpaid orders and NIF receipts that need filing.',
    ),
    _Tip(
      icon: Icons.sell_outlined,
      color: Color(0xFF1976D2),
      title: 'Sales list',
      body:
          'All your orders, newest first. Each card shows a progress path — assembly → payment → shipping. Long-press the path bar for a legend explaining each stage.',
    ),
    _Tip(
      icon: Icons.edit_note,
      color: Color(0xFF00796B),
      title: 'Sale detail',
      body:
          'Tap any sale to open the full detail. From here you can edit every field, manage the materials list, add photos, record a tracking number, and duplicate or delete the order.',
    ),
    _Tip(
      icon: Icons.checklist_outlined,
      color: Color(0xFF388E3C),
      title: 'Components',
      body:
          'Inside a sale, tick off materials as they arrive. When the last component is checked, the assembly status advances automatically. Swipe a component left to remove it.',
    ),
    _Tip(
      icon: Icons.people_outlined,
      color: Color(0xFFF57C00),
      title: 'Buyers',
      body:
          'Buyer profiles store contact info, NIF, saved addresses, and a live purchase history. Tap any past order to jump straight to its detail screen.',
    ),
    _Tip(
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFFD32F2F),
      title: 'Shopping list',
      body:
          'Access from the Dashboard. Shows every component still needed across all active sales, grouped by urgency — overdue orders appear first so you know what to prioritise on your next supply run.',
    ),
    _Tip(
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF7B1FA2),
      title: 'NIF / AT receipts',
      body:
          'Sales that require a fiscal receipt are flagged with a purple badge. Open the NIF screen from the Dashboard to see all pending submissions in one place.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.science_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo tour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _tips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _TipCard(tip: _tips[index]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _Tip tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tip.color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(tip.icon, size: 22, color: tip.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                tip.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(180),
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tip {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Tip({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
