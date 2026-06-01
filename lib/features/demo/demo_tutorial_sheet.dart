import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';

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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    final tips = [
      _Tip(icon: Icons.dashboard_outlined, color: const Color(0xFF6750A4), title: s.tipDashboardTitle, body: s.tipDashboardBody),
      _Tip(icon: Icons.sell_outlined, color: const Color(0xFF1976D2), title: s.tipSalesTitle, body: s.tipSalesBody),
      _Tip(icon: Icons.edit_note, color: const Color(0xFF00796B), title: s.tipDetailTitle, body: s.tipDetailBody),
      _Tip(icon: Icons.checklist_outlined, color: const Color(0xFF388E3C), title: s.tipComponentsTitle, body: s.tipComponentsBody),
      _Tip(icon: Icons.people_outlined, color: const Color(0xFFF57C00), title: s.tipBuyersTitle, body: s.tipBuyersBody),
      _Tip(icon: Icons.shopping_cart_outlined, color: const Color(0xFFD32F2F), title: s.tipShoppingTitle, body: s.tipShoppingBody),
      _Tip(icon: Icons.receipt_long_outlined, color: const Color(0xFF7B1FA2), title: s.tipNifTitle, body: s.tipNifBody),
    ];

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
                    s.demoTourTitle,
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
              itemCount: tips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TipCard(tip: tips[index]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.gotIt),
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
