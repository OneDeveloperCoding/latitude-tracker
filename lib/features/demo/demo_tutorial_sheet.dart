import 'dart:async';
import 'package:flutter/material.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';

class DemoTutorialSheet extends StatefulWidget {
  const DemoTutorialSheet({super.key});

  static void show(BuildContext context) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DemoTutorialSheet(),
    ));
  }

  @override
  State<DemoTutorialSheet> createState() => _DemoTutorialSheetState();
}

class _DemoTutorialSheetState extends State<DemoTutorialSheet> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_page < total - 1) {
      unawaited(_controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      ));
    } else {
      Navigator.pop(context);
    }
  }

  void _back() {
    unawaited(_controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;

    final pages = _buildPages(s);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, _) => Column(
        children: [
          _Header(title: s.appTour),
          const Divider(height: 1),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: pages.length,
              itemBuilder: (context, i) => _PageContent(page: pages[i]),
            ),
          ),
          _Footer(
            page: _page,
            total: pages.length,
            colorScheme: colorScheme,
            backLabel: s.tutorialBack,
            nextLabel: _page == pages.length - 1
                ? s.tutorialGetStarted
                : s.tutorialNext,
            onBack: _back,
            onNext: () => _next(pages.length),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<_TutorialPage> _buildPages(AppStrings s) => [
    _TutorialPage(
      icon: Icons.storefront_outlined,
      color: const Color(0xFF6750A4),
      title: s.tourWelcomeTitle,
      body: s.tourWelcomeBody,
    ),
    _TutorialPage(
      icon: Icons.add_circle_outline,
      color: const Color(0xFF1976D2),
      title: s.tourCreateSaleTitle,
      body: s.tourCreateSaleBody,
    ),
    _TutorialPage(
      icon: Icons.receipt_long_outlined,
      color: const Color(0xFF00796B),
      title: s.tourSaleDetailTitle,
      body: s.tourSaleDetailBody,
    ),
    _TutorialPage(
      icon: Icons.dashboard_outlined,
      color: const Color(0xFF3949AB),
      title: s.tourDashboardTitle,
      body: s.tourDashboardBody,
    ),
    _TutorialPage(
      icon: Icons.people_outlined,
      color: const Color(0xFFF57C00),
      title: s.tourBuyersTitle,
      body: s.tourBuyersBody,
    ),
    _TutorialPage(
      icon: Icons.bar_chart_outlined,
      color: const Color(0xFF7B1FA2),
      title: s.tourAnalyticsTitle,
      body: s.tourAnalyticsBody,
    ),
    _TutorialPage(
      icon: Icons.tips_and_updates_outlined,
      color: const Color(0xFF0288D1),
      title: s.tourDiscoverTitle,
      body: s.tourDiscoverBody,
      gems: [
        _Gem(
          Icons.checklist_outlined,
          const Color(0xFF388E3C),
          s.tourGemShoppingTitle,
          s.tourGemShoppingBody,
        ),
        _Gem(
          Icons.map_outlined,
          const Color(0xFF0288D1),
          s.tourGemMapTitle,
          s.tourGemMapBody,
        ),
        _Gem(
          Icons.account_balance_wallet_outlined,
          const Color(0xFFD32F2F),
          s.tourGemUnpaidTitle,
          s.tourGemUnpaidBody,
        ),
        _Gem(
          Icons.receipt_outlined,
          const Color(0xFF7B1FA2),
          s.tourGemNifTitle,
          s.tourGemNifBody,
        ),
      ],
    ),
  ];
}

// ── Sub-widgets
// ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          Icon(
            Icons.explore_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.page,
    required this.total,
    required this.colorScheme,
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
  });
  final int page;
  final int total;
  final ColorScheme colorScheme;
  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (page > 0)
                TextButton(
                  onPressed: onBack,
                  child: Text(backLabel),
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                child: Text(nextLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _TutorialPage page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: page.color.withAlpha(28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(page.icon, size: 32, color: page.color),
          ),
          const SizedBox(height: 20),
          Text(
            page.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.body,
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withAlpha(200),
              height: 1.5,
            ),
          ),
          if (page.gems != null) ...[
            const SizedBox(height: 20),
            ...page.gems!.map((gem) => _GemCard(gem: gem)),
          ],
        ],
      ),
    );
  }
}

class _GemCard extends StatelessWidget {
  const _GemCard({required this.gem});
  final _Gem gem;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gem.color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(gem.icon, size: 18, color: gem.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gem.title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gem.body,
                  style: textTheme.bodySmall?.copyWith(
                    color: onSurface.withAlpha(170),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Models
// ────────────────────────────────────────────────────────────────────

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.gems,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<_Gem>? gems;
}

class _Gem {
  const _Gem(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}
