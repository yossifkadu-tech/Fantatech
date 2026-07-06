import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../state/marketplace_providers.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/pro_upgrade_banner.dart';

/// Marketplace + recommendation feed. Pro users see catalog without ads.
///
/// Mount under a `ProviderScope`. Feed real device data by overriding
/// `ownedDeviceTypesProvider`, e.g.:
///   ProviderScope(overrides: [
///     ownedDeviceTypesProvider.overrideWithValue(
///         appState.devices.map((d) => d.type.name).toList()),
///   ], child: MarketplaceScreen());
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsEnabled = ref.watch(adsEnabledProvider);
    final recos = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('חנות חכמה',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (adsEnabled)
            ProUpgradeBanner(
              onUpgrade: () =>
                  ref.read(subscriptionProvider.notifier).upgradeToPro('demo_token'),
            ),

          if (adsEnabled) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text('מומלץ עבורך',
                  style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            recos.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('שגיאה בטעינת המלצות: $e',
                    style: const TextStyle(color: Color(0xFF8E8E93))),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('אין המלצות כרגע — הבית שלך מצויד היטב 👌',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8E8E93))),
                  );
                }
                return Column(
                  children: [
                    for (final r in list)
                      RecommendationCard(
                        reco: r,
                        onTap: () => _showProductDetail(context, r.product),
                        onDismiss: () {
                          ref.read(dismissedCategoriesProvider.notifier).update(
                              (s) => {...s, r.product.category});
                        },
                      ),
                  ],
                );
              },
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('FantaTech Pro פעיל — ללא פרסומות 🎉',
                    style: TextStyle(
                        color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Product detail sheet ──────────────────────────────────────────────────────

void _showProductDetail(BuildContext context, Product p) {
  const orange = Color(0xFFFF6B00);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (ctx, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // icon + title
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16)),
              child: Icon(_iconFor(p.category), color: orange, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title,
                    style: const TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Symbols.star, color: Color(0xFFFFB800), size: 14),
                  Text(' ${p.rating.toStringAsFixed(1)}',
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(width: 8),
                  _tag(p.category, orange),
                ]),
              ]),
            ),
          ]),

          const SizedBox(height: 20),

          // price row
          Row(children: [
            Text('₪${p.priceIls.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: orange, fontSize: 26, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (p.isBundle)
              _tag('חבילה', const Color(0xFF5C6BC0)),
          ]),

          const SizedBox(height: 16),

          // compatibility chips
          if (p.compatibility.isNotEmpty) ...[
            const Text('תואם ל-',
                style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: p.compatibility
                  .map((c) => Chip(
                        label: Text(c,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF1A1A2E))),
                        backgroundColor: const Color(0xFFF5F7FA),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (p.affiliateUrl != null) {
                  final uri = Uri.tryParse(p.affiliateUrl!);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('נוסף לסל הקניות'),
                    backgroundColor: Color(0xFF34C759),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              icon: Icon(p.affiliateUrl != null
                  ? Symbols.open_in_new
                  : Symbols.shopping_cart, size: 20),
              label: Text(p.affiliateUrl != null ? 'לרכישה באתר' : 'הוסף לסל',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _tag(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );

IconData _iconFor(String category) {
  switch (category) {
    case 'camera':  return Symbols.videocam;
    case 'sensor':  return Symbols.sensors;
    case 'lock':    return Symbols.lock;
    case 'gateway': return Symbols.router;
    case 'light':   return Symbols.lightbulb;
    case 'bundle':  return Symbols.inventory_2;
    default:        return Symbols.devices_other;
  }
}
