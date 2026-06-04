import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import '../../utils/price_format.dart';

// ── Product model ─────────────────────────────────────────────────────────────
class _Product {
  final String id;
  final String name;
  final num priceUsd;            // base price in USD
  final double rating;
  final bool isBestseller;
  final String urlSlug; // path on fantatech.co.il/shop/<slug>

  const _Product(this.id, this.name, this.priceUsd, this.rating,
      this.isBestseller, this.urlSlug);
}

// ─────────────────────────────────────────────────────────────────────────────

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {

  static const _baseUrl = 'https://www.fantatech.co.il';

  static const _featured = [
    _Product('ft_hub',   'FantaTech Hub Pro',  149, 4.8, true,  'hub-pro'),
    _Product('ft_cam',   'FT Camera 4K',       89,  4.7, false, 'camera-4k'),
    _Product('ft_bulb',  'Smart Bulb RGB',     19,  4.6, false, 'smart-bulb'),
    _Product('ft_sense', 'חיישן תנועה Shelly', 29,  4.5, false, 'motion-sensor'),
  ];

  static const _newArrivals = [
    _Product('ft_blind', 'מנוע תריס חכם',  79, 4.4, true,  'blind-motor'),
    _Product('ft_plug',  'שקע חכם 16A',    24, 4.6, false, 'smart-plug'),
    _Product('ft_gw',    'Gateway Matter', 59, 4.9, true,  'gateway-matter'),
    _Product('ft_strip', 'רצועת LED 5מ',  34, 4.3, false, 'led-strip'),
  ];

  // search
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── URL helpers ───────────────────────────────────────────────────────────

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AppState>().strings.storeBrowserError),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _openProduct(_Product p) =>
      _openUrl('$_baseUrl/shop/${p.urlSlug}');

  void _openCart() => _openUrl('$_baseUrl/cart');

  void _openShop() => _openUrl('$_baseUrl/shop');

  void _openNotifyDialog() {
    final s = context.read<AppState>().strings;
    final textDir = context.read<AppState>().isRtl
        ? TextDirection.rtl : TextDirection.ltr;
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: context.tCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.storeNotifyMe,
              style: TextStyle(color: context.tText, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              s.storeNotifyDesc,
              style: TextStyle(
                  color: context.tText2(0.65), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: context.tText),
              decoration: InputDecoration(
                hintText: s.storeYourEmail,
                hintStyle:
                    TextStyle(color: context.tText2(0.35)),
                filled: true,
                fillColor: context.tText2(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: context.tText2(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: context.tText2(0.15)),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel,
                  style: TextStyle(
                      color: context.tText2(0.45))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A3AFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(s.storeNotifySuccess,
                      textDirection: textDir),
                  backgroundColor: AppColors.secured,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Text(s.save,
                  style: TextStyle(color: context.tText)),
            ),
          ],
        );
      },
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  List<_Product> _filter(List<_Product> list) {
    if (_query.isEmpty) return list;
    return list
        .where((p) =>
            p.name.toLowerCase().contains(_query) ||
            p.id.contains(_query))
        .toList();
  }

  bool get _hasResults =>
      _filter(_featured).isNotEmpty || _filter(_newArrivals).isNotEmpty;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final featured    = _filter(_featured);
    final newArrivals = _filter(_newArrivals);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Text(
                      s.storeTitle,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Cart → opens website cart
                    GestureDetector(
                      onTap: _openCart,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: context.tCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: context.tText2(0.10)),
                        ),
                        child: Icon(Icons.shopping_bag_outlined,
                            color: context.tText2(0.7), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.tCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: context.tText2(0.08)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_outlined,
                        color: context.tText2(0.35),
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(
                            color: context.tText, fontSize: 13),
                        textDirection: textDir,
                        decoration: InputDecoration(
                          hintText: s.storeSearchHint,
                          hintStyle: TextStyle(
                            color: context.tText2(0.30),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.close_rounded,
                              color: context.tText2(0.45),
                              size: 16),
                        ),
                      ),
                  ]),
                ),
              ),
            ),

            // ── No results state ────────────────────────────────
            if (_query.isNotEmpty && !_hasResults)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            color: context.tText2(0.2),
                            size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${s.storeNoResultsFor} "$_query"',
                          style: TextStyle(
                              color: context.tText2(0.35),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _openShop,
                          child: Text(s.storeSearchSite,
                              style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Website banner (always visible) ─────────────────
            if (_query.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GestureDetector(
                    onTap: () => _openUrl(_baseUrl),
                    child: Container(
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A3AFF), Color(0xFF7B5EA7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF4A3AFF)
                                  .withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: context.tText2(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.language_outlined,
                                  color: context.tText, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(s.visitWebsite,
                                      style: TextStyle(
                                        color: context.tText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 2),
                                  Text('fantatech.co.il',
                                      style: TextStyle(
                                        color: context.tText
                                            .withValues(alpha: 0.70),
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    context.tText2(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.open_in_new,
                                  color: context.tText, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Promo banner ────────────────────────────────────
            if (_query.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    height: 175,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.tCard, Color(0xFF16213E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFF4A3AFF)
                              .withValues(alpha: 0.30)),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30, top: -30,
                          child: Container(
                            width: 160, height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4A3AFF)
                                  .withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A3AFF)
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFF4A3AFF)
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  s.storeComingSoon.toUpperCase(),
                                  style: TextStyle(
                                    color: Color(0xFF9B8AFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'FantaTech Hub Pro 2.0',
                                style: TextStyle(
                                  color: context.tText,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.storeHubProTagline,
                                style: TextStyle(
                                  color: context.tText2(0.60),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                GestureDetector(
                                  onTap: _openNotifyDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A3AFF),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(s.storeNotifyMe,
                                        style: TextStyle(
                                            color: context.tText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Featured section ────────────────────────────────
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    Text(
                      s.storeFeatured,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openShop,
                      child: Text(s.storeViewAll,
                          style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featured.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (ctx, i) => _ProductCard(
                      product: featured[i],
                      onTap: () => _openProduct(featured[i]),
                      onAdd: () => _openProduct(featured[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ── New arrivals section ────────────────────────────
            if (newArrivals.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    Text(
                      s.storeNewArrivals,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openShop,
                      child: Text(s.storeViewAll,
                          style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ProductCard(
                      product: newArrivals[i],
                      wide: true,
                      onTap: () => _openProduct(newArrivals[i]),
                      onAdd: () => _openProduct(newArrivals[i]),
                    ),
                    childCount: newArrivals.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product card
// ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool wide;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.wide = false,
  });

  IconData get _icon {
    switch (product.id) {
      case 'ft_hub':   return Icons.hub_outlined;
      case 'ft_cam':   return Icons.videocam_outlined;
      case 'ft_bulb':  return Icons.lightbulb_outlined;
      case 'ft_sense': return Icons.sensors_outlined;
      case 'ft_blind': return Icons.blinds_outlined;
      case 'ft_plug':  return Icons.power_outlined;
      case 'ft_gw':    return Icons.router_outlined;
      case 'ft_strip': return Icons.wb_iridescent_outlined;
      default:         return Icons.devices_outlined;
    }
  }

  Color get _iconColor {
    switch (product.id) {
      case 'ft_hub':   return AppColors.primary;
      case 'ft_cam':   return AppColors.cameraColor;
      case 'ft_bulb':  return AppColors.lightColor;
      case 'ft_sense': return AppColors.motionColor;
      case 'ft_blind': return AppColors.primary;
      case 'ft_plug':  return AppColors.plugColor;
      case 'ft_gw':    return const Color(0xFF00B4D8);
      case 'ft_strip': return AppColors.lightColor;
      default:         return Colors.white.withValues(alpha: 0.54);
    }
  }

  /// Localized product name. Brand names (Hub Pro, Camera 4K…) stay as-is;
  /// generic products are translated to the selected language.
  String _name(S s) {
    switch (product.id) {
      case 'ft_sense': return s.prodMotionSensor;
      case 'ft_blind': return s.prodBlindMotor;
      case 'ft_plug':  return s.prodSmartPlug;
      case 'ft_strip': return s.prodLedStrip;
      default:         return product.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final isHebrew = state.locale == AppLocale.hebrew;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? null : 140.0,
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.tText2(0.07),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon area ─────────────────────────────────────
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(_icon, color: _iconColor, size: 38),
                    ),
                    if (product.isBestseller)
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBC05),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'TOP',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // "open in web" hint
                    Positioned(
                      top: 6, right: 6,
                      child: Icon(
                        Icons.open_in_new,
                        color: context.tText2(0.25),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Name ─────────────────────────────────────────
              Text(
                _name(s),
                style: TextStyle(
                  color: context.tText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Rating ────────────────────────────────────────
              Row(children: [
                Icon(Icons.star_rounded,
                    color: Color(0xFFFBBC05), size: 12),
                const SizedBox(width: 3),
                Text(
                  product.rating.toString(),
                  style: TextStyle(
                    color: context.tText2(0.55),
                    fontSize: 10,
                  ),
                ),
              ]),
              const Spacer(),

              // ── Price + Buy button ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(product.priceUsd, isHebrew: isHebrew),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shopping_cart_outlined,
                          color: context.tText, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
