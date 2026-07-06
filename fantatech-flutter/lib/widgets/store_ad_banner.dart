import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/store/store_screen.dart';
import '../utils/price_format.dart';

// ─── Product data (mirrors StoreScreen catalogue) ────────────────────────────

class _AdProduct {
  final String id;
  final String name;
  final num priceUsd;
  final IconData icon;
  final Color color;
  final String track; // 'featured' | 'new' | 'all'

  const _AdProduct({
    required this.id,
    required this.name,
    required this.priceUsd,
    required this.icon,
    required this.color,
    required this.track,
  });
}

const _kProducts = [
  // Featured
  _AdProduct(id: 'ft_hub',   name: 'FantaTech Hub Pro',  priceUsd: 149, icon: Symbols.router,         color: Color(0xFF00B4D8), track: 'featured'),
  _AdProduct(id: 'ft_cam',   name: 'FT Camera 4K',       priceUsd: 89,  icon: Symbols.videocam,       color: Color(0xFF9C7AFF), track: 'featured'),
  _AdProduct(id: 'ft_bulb',  name: 'Smart Bulb RGB',     priceUsd: 19,  icon: Symbols.lightbulb,       color: Color(0xFFFFD600), track: 'featured'),
  _AdProduct(id: 'ft_sense', name: 'Motion Sensor',      priceUsd: 29,  icon: Symbols.sensors,        color: Color(0xFFFF6B6B), track: 'featured'),
  // New arrivals
  _AdProduct(id: 'ft_blind', name: 'Smart Blind Motor',  priceUsd: 79,  icon: Symbols.blinds,         color: Color(0xFF7B2FFF), track: 'new'),
  _AdProduct(id: 'ft_plug',  name: 'Smart Plug 16A',     priceUsd: 24,  icon: Symbols.power,          color: Color(0xFF00C896), track: 'new'),
  _AdProduct(id: 'ft_gw',    name: 'Gateway Matter',     priceUsd: 59,  icon: Symbols.hub,            color: Color(0xFF00B4D8), track: 'new'),
  _AdProduct(id: 'ft_strip', name: 'LED Strip 5m',       priceUsd: 34,  icon: Symbols.wb_iridescent,  color: Color(0xFFFF2D8A), track: 'new'),
];

List<_AdProduct> _productsForTrack(AdTrack track) {
  switch (track) {
    case AdTrack.featured:   return _kProducts.where((p) => p.track == 'featured').toList();
    case AdTrack.newArrivals: return _kProducts.where((p) => p.track == 'new').toList();
    case AdTrack.all:         return _kProducts;
    case AdTrack.none:        return [];
  }
}

// ─── StoreAdBanner ────────────────────────────────────────────────────────────

class StoreAdBanner extends StatefulWidget {
  const StoreAdBanner({super.key});

  @override
  State<StoreAdBanner> createState() => _StoreAdBannerState();
}

class _StoreAdBannerState extends State<StoreAdBanner>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Timer? _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _next());
  }

  void _next() {
    final products =
        _productsForTrack(context.read<AppState>().adTrack);
    if (products.isEmpty) return;
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % products.length);
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final track = state.adTrack;

    // Hidden if user chose "none"
    if (track == AdTrack.none) return const SizedBox.shrink();

    final products = _productsForTrack(track);
    if (products.isEmpty) return const SizedBox.shrink();

    final product = products[_index % products.length];

    // Localized product name — brand names stay, generic ones translate.
    final productName = switch (product.id) {
      'ft_sense' => state.strings.prodMotionSensor,
      'ft_blind' => state.strings.prodBlindMotor,
      'ft_plug'  => state.strings.prodSmartPlug,
      'ft_strip' => state.strings.prodLedStrip,
      _          => product.name,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const StoreScreen())),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: product.color.withValues(alpha: 0.25), width: 1.4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Subtle diagonal stripe bg (fills all available space)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StripePainter(color: product.color),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 30),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product icon bubble — larger
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            color: product.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: product.color.withValues(alpha: 0.32),
                                width: 1.2),
                          ),
                          child: Icon(product.icon,
                              color: product.color, size: 46),
                        ),
                        const SizedBox(width: 18),

                        // Name + price + cta
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "AD" chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: product.color.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  state.strings.adStoreLabel,
                                  style: TextStyle(
                                    color: product.color.withValues(alpha: 0.85),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    formatPrice(product.priceUsd,
                                        isHebrew: state.locale ==
                                            AppLocale.hebrew),
                                    style: TextStyle(
                                      color: product.color,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: product.color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      state.strings.storeAddToCart,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right column: settings + dots
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _timer?.cancel();
                                _showTrackSheet(context, state).then((_) {
                                  if (mounted) _startTimer();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Symbols.tune,
                                    color: Colors.white.withValues(alpha: 0.35),
                                    size: 18),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Dot indicators
                            Column(
                              children: List.generate(
                                products.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  width: 4,
                                  height: i == _index % products.length ? 14 : 4,
                                  decoration: BoxDecoration(
                                    color: i == _index % products.length
                                        ? product.color
                                        : Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Track selector bottom-sheet ─────────────────────────────────────────────

Future<void> _showTrackSheet(BuildContext context, AppState state) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdTrackSheet(state: state),
  );
}

class _AdTrackSheet extends StatelessWidget {
  final AppState state;
  const _AdTrackSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final current = state.adTrack;
    final s = state.strings;

    final options = [
      _TrackOption(
        track: AdTrack.featured,
        icon: Symbols.star,
        color: const Color(0xFFFFD600),
        label: s.adFeaturedLabel,
        sub: s.adFeaturedSub,
      ),
      _TrackOption(
        track: AdTrack.newArrivals,
        icon: Symbols.fiber_new,
        color: const Color(0xFF00C896),
        label: s.adNewLabel,
        sub: s.adNewSub,
      ),
      _TrackOption(
        track: AdTrack.all,
        icon: Symbols.grid_view,
        color: AppColors.primary,
        label: s.adAllLabel,
        sub: s.adAllSub,
      ),
      _TrackOption(
        track: AdTrack.none,
        icon: Symbols.block,
        color: Colors.white38,
        label: s.adNoneLabel,
        sub: s.adNoneSub,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              const Icon(Symbols.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                s.adTrackTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.adTrackSub,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Options
          ...options.map((opt) => _TrackTile(
                option: opt,
                selected: current == opt.track,
                onTap: () {
                  state.setAdTrack(opt.track);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

class _TrackOption {
  final AdTrack track;
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _TrackOption(
      {required this.track,
      required this.icon,
      required this.color,
      required this.label,
      required this.sub});
}

class _TrackTile extends StatelessWidget {
  final _TrackOption option;
  final bool selected;
  final VoidCallback onTap;
  const _TrackTile(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? option.color.withValues(alpha: 0.10)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? option.color.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.07),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: option.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(option.sub,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (selected)
              Icon(Symbols.check_circle,
                  color: option.color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Stripe background painter ────────────────────────────────────────────────

class _StripePainter extends CustomPainter {
  final Color color;
  const _StripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.045)
      ..strokeWidth = 1.2;
    const step = 22.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}
