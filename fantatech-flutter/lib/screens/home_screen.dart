import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../services/gateways/gateway_manager.dart';
import '../services/gateways/gateway_model.dart';
import '../services/weather/weather_service.dart';
import 'gateways/gateway_hub_screen.dart';
import 'ai/fanta_ai_screen.dart';
import 'smarthome/scan_discovery_screen.dart';
import 'smarthome/smarthome_screen.dart';
import 'smarthome/ac_hub_screen.dart';
import 'smarthome/lights_hub_screen.dart';
import 'smarthome/plugs_hub_screen.dart';
import 'smarthome/smart_switch_hub_screen.dart';
import 'smarthome/sensor_hub_screen.dart';
import 'smarthome/intercom_hub_screen.dart';
import 'security/smart_lock_hub_screen.dart';
import 'energy/energy_screen.dart';
import 'profile/profile_screen.dart' show showHomeManagementSheet;
import 'solar/solar_screen.dart';
import 'rooms/rooms_screen.dart';
import 'store/store_screen.dart';
import 'media/media_screen.dart';
import 'smarthome/add_device_screen.dart';
import 'security/security_screen.dart';
import 'notifications/notifications_screen.dart';
import 'breakers/breakers_screen.dart';
import 'cameras/camera_player_screen.dart';
import 'cameras/cameras_screen.dart';
import 'devices/devices_screen.dart';
import '../widgets/ft_button.dart';
import '../models/layout_item.dart';
import '../providers/layout_provider.dart';
import '../widgets/edit_mode/reorderable_dashboard.dart';
import '../widgets/edit_mode/dashboard_customize_sheet.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
// Design tokens — mapped to central design system
// ─────────────────────────────────────────────────────────────────
const _kOrange = AppColors.primary;
const _kGrey   = AppColors.textSecondary;
const _kGreen  = AppColors.success;
// Legacy aliases — kept for inline widgets not yet migrated to context.tText
const _kDark   = AppColors.textPrimary;  // Color(0xFF0F172A)

// ─────────────────────────────────────────────────────────────────
// Unified topic status — every hero banner reports one of the shared
// DeviceStatus states (online/warning/alarm/offline) via the same
// AppStatusColors palette used everywhere else in the app.
// ─────────────────────────────────────────────────────────────────
Widget _topicStatusDot(DeviceStatus status) => Container(
  width: 7, height: 7,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: AppStatusColors.dot(status),
  ),
);

String _topicStatusWord(DeviceStatus status, dynamic s) => switch (status) {
  DeviceStatus.online  => s.normalStatus,
  DeviceStatus.warning => s.cyberStatusWarning,
  DeviceStatus.alarm   => s.cyberStatusWarning,
  DeviceStatus.offline => s.statusOffline,
  _                    => s.normalStatus,
};

// Theme-aware card decoration — always call with a BuildContext.
BoxDecoration _card(BuildContext ctx, {double? radius}) => BoxDecoration(
  color: ctx.tCard,
  borderRadius: BorderRadius.circular(radius ?? AppBorderRadius.r16),
  boxShadow: ctx.isLight ? AppShadows.md : AppShadows.dark,
  border: Border.all(
    color: ctx.isLight ? AppColors.lightBorder : AppColors.darkBorder.withValues(alpha: 0.6),
    width: 1,
  ),
);

// ─────────────────────────────────────────────────────────────────
// HomeScreen — swipeable across 2 pages. Which sections live on
// which page is chosen by the user via the "customize" sheet.
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _migrateLayout());
  }

  // One-time cleanup for devices with a layout persisted before the
  // "rooms" section was retired and before home-screen paging existed.
  void _migrateLayout() async {
    final provider = context.read<LayoutProvider>();
    provider.ensureLayout(DashboardId.home, DashboardDefaults.home);
    provider.pruneObsoleteTypes(DashboardId.home, const {'rooms'});
    provider.syncNewItems(DashboardId.home, DashboardDefaults.home);
    provider.applyDefaultPagesIfUnset(DashboardId.home, DashboardDefaults.homePage0Types);

    // One-time forced re-sync of order/page to the canonical
    // DashboardDefaults.home values. syncNewItems only ADDS missing items —
    // it never corrects the order/page of items a device already has
    // persisted from an older app version. Instead of a manually-bumped
    // version number (easy to forget when the defaults change again — this
    // happened once already this session), the migration key is derived
    // from the defaults list itself: any future edit to order/page in
    // DashboardDefaults.home automatically produces a new key and forces a
    // fresh re-sync, with no separate constant to remember to update.
    final prefs = await SharedPreferences.getInstance();
    final signature = DashboardDefaults.home
        .map((i) => '${i.id}:${i.order}:${i.page}')
        .join('|');
    final migrationKey = 'ft_home_order_synced_${signature.hashCode}';
    if (!(prefs.getBool(migrationKey) ?? false)) {
      for (final item in DashboardDefaults.home) {
        provider.setItemOrder(DashboardId.home, item.id, item.order);
        provider.setItemPage(DashboardId.home, item.id, item.page);
      }
      await prefs.setBool(migrationKey, true);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  static Widget _buildItem(BuildContext ctx, LayoutItem item) {
    final Widget body = switch (item.type) {
      'ai_hero'       => const _AiHeroCard(),
      'weather'       => const _WeatherEnergyRow(),
      'security'      => const _SecurityBanner(),
      'cameras'       => const _CamerasSection(),
      'quick_actions' => const _SmartHomeBanner(),
      'home_management' => const _HomeManagementBanner(),
      'system_status' => const _SystemStatusSection(),
      'store'         => const _StoreBanner(),
      'ad_banner'     => const _AdBanner(),
      'media'         => const _MediaBanner(),
      _               => const SizedBox.shrink(),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            final content = Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _TopBar(),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      ReorderableDashboard(
                        dashboardId: DashboardId.home,
                        defaultItems: DashboardDefaults.home,
                        nameResolver: DashboardDefaults.nameOf,
                        iconResolver: DashboardDefaults.iconOf,
                        padding: const EdgeInsets.only(bottom: 40),
                        page: 0,
                        itemBuilder: _buildItem,
                      ),
                      ReorderableDashboard(
                        dashboardId: DashboardId.home,
                        defaultItems: DashboardDefaults.home,
                        nameResolver: DashboardDefaults.nameOf,
                        iconResolver: DashboardDefaults.iconOf,
                        padding: const EdgeInsets.only(bottom: 40),
                        page: 1,
                        itemBuilder: _buildItem,
                      ),
                    ],
                  ),
                ),
                _HomePageDots(current: _page),
              ],
            );
            if (!isLandscape) return content;
            // Landscape: center content with max 600px so cards stay readable
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomePageDots extends StatelessWidget {
  final int current;
  const _HomePageDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(2, (i) {
          final selected = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: selected ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: selected ? _kOrange : context.tTextSecondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final firstName = state.userFirstName.isNotEmpty ? state.userFirstName : 'FantaTech';

    void openAddDevice() => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddDeviceScreen()));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 14, AppSpacing.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand bar ────────────────────────────────────────────
          Row(
            children: [
              // Wordmark
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _kOrange,
                        borderRadius: BorderRadius.circular(AppBorderRadius.r8),
                        boxShadow: AppShadows.glow(_kOrange, intensity: 0.6),
                      ),
                      child: const Icon(Symbols.home, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: 'Fanta',
                                style: AppTypography.headlineMd.copyWith(
                                  color: context.tText, letterSpacing: -0.5),
                              ),
                              TextSpan(
                                text: 'Tech',
                                style: AppTypography.headlineMd.copyWith(
                                  color: _kOrange, letterSpacing: -0.5),
                              ),
                            ]),
                          ),
                          Text(
                            s.appTagline,
                            style: AppTypography.labelSm.copyWith(
                              color: context.tTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              FtButton.iconOnly(
                icon: Symbols.add,
                variant: FtButtonVariant.neutral,
                onTap: openAddDevice,
              ),
              const SizedBox(width: AppSpacing.s4),
              FtButton.iconOnly(
                icon: Symbols.tune,
                variant: FtButtonVariant.neutral,
                onTap: () => showDashboardCustomizeSheet(
                  context,
                  dashboardId: DashboardId.home,
                  nameResolver: DashboardDefaults.nameOf,
                  iconResolver: DashboardDefaults.iconOf,
                  showPageToggle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          // ── Greeting row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('👋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.greetingPrefix} $firstName',
                      style: AppTypography.headlineMd.copyWith(color: context.tText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.homeGreetingSub,
                      style: AppTypography.bodyMd.copyWith(color: context.tTextSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const _CompactWeatherChip(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Compact weather chip — sits next to the greeting in the top bar
// ─────────────────────────────────────────────────────────────────
class _CompactWeatherChip extends StatefulWidget {
  const _CompactWeatherChip();

  @override
  State<_CompactWeatherChip> createState() => _CompactWeatherChipState();
}

class _CompactWeatherChipState extends State<_CompactWeatherChip> {
  WeatherInfo? _weather;
  bool _refreshing = false;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _load();
    // "Live" — refresh automatically every 10 minutes, and on tap.
    _autoRefresh = Timer.periodic(const Duration(minutes: 10), (_) => _load());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _refreshing = true);
    final info = await WeatherService.fetch();
    if (!mounted) return;
    setState(() {
      _weather    = info;
      _refreshing = false;
    });
  }

  ({IconData icon, Color color}) _glyph() {
    final w = _weather;
    if (w == null) return (icon: Symbols.wb_sunny, color: const Color(0xFFFFCC00));
    final c = w.weatherCode;
    if (c == 0) {
      return w.isDay
          ? (icon: Symbols.wb_sunny, color: const Color(0xFFFFCC00))
          : (icon: Symbols.nightlight_round, color: const Color(0xFF90A4D4));
    }
    if (c <= 3)  return (icon: Symbols.wb_cloudy, color: const Color(0xFFB0BEC5));
    if (c <= 48) return (icon: Symbols.foggy, color: const Color(0xFFB0BEC5));
    if (c <= 67 || (c >= 80 && c <= 82)) return (icon: Symbols.grain, color: const Color(0xFF4FC3F7));
    if (c <= 77 || (c >= 85 && c <= 86)) return (icon: Symbols.ac_unit, color: const Color(0xFF81D4FA));
    return (icon: Symbols.thunderstorm, color: const Color(0xFF7986CB));
  }

  @override
  Widget build(BuildContext context) {
    final g = _glyph();
    final temp     = _weather != null ? '${_weather!.temperatureC.round()}°' : '—°';
    final humidity = _weather != null ? '${_weather!.humidityPct}%' : '—';

    final city = _weather?.city;
    final showCity = city != null && city.isNotEmpty && city != '—';

    return GestureDetector(
      onTap: _refreshing ? null : _load,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(AppBorderRadius.r16),
          border: Border.all(
            color: context.isLight ? AppColors.lightBorder : AppColors.darkBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _refreshing
                ? SizedBox(
                    width: 22, height: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: g.color),
                    ),
                  )
                : Icon(g.icon, color: g.color, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(temp, style: AppTypography.titleMd.copyWith(color: context.tText)),
                    const SizedBox(width: 6),
                    Icon(Symbols.humidity_percentage, size: 10, color: context.tTextSecondary),
                    const SizedBox(width: 2),
                    Text(humidity, style: AppTypography.labelSm.copyWith(color: context.tTextSecondary)),
                  ],
                ),
                if (showCity)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.location_on, size: 10, color: context.tTextSecondary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSm.copyWith(color: context.tTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Energy row (standalone — weather now lives next to the greeting)
// ─────────────────────────────────────────────────────────────────
class _WeatherEnergyRow extends StatelessWidget {
  const _WeatherEnergyRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _EnergyCard(),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard();

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EnergySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final todayKwh = todayEnergyKwh(state);
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: AppSpacing.card,
        decoration: _card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.energyToday,
                  style: AppTypography.caption.copyWith(color: context.tTextSecondary),
                ),
                const Spacer(),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppBorderRadius.r8),
                  ),
                  child: const Icon(Symbols.bolt, color: _kOrange, size: 14),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              todayKwh != null ? '${todayKwh.toStringAsFixed(1)} kWh' : s.noResults,
              style: AppTypography.displaySm.copyWith(color: context.tText),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Energy + Breakers Bottom Sheet
// ─────────────────────────────────────────────────────────────────
class _EnergySheet extends StatelessWidget {
  const _EnergySheet();

  Color _breakerColor(Device d) => d.status == DeviceStatus.alarm
      ? AppColors.statusAlarm
      : (d.isOn ? AppColors.statusOnline : _kGrey);

  String _breakerLabel(S s, Device d) => d.status == DeviceStatus.alarm
      ? s.breakerTripped
      : (d.isOn ? s.breakerOn : s.breakerOff);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    // Real breaker devices only — no gateway currently reports circuit
    // breakers, so this list is empty for virtually everyone today. That's
    // shown honestly (see below) rather than filled with invented rooms.
    final breakerDevices =
        state.devices.where((d) => d.type == DeviceType.circuitBreaker).toList();
    final trippedCount =
        breakerDevices.where((d) => d.status == DeviceStatus.alarm).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: context.tBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _kGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Today's Energy — real data: device counts +
                  // whatever actual energy/solar readings exist. Unlike the
                  // section below, this never shows an invented number.
                  Row(
                    children: [
                      const Icon(Symbols.today, color: _kOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(state.strings.energyToday,
                          style: const TextStyle(
                              color: _kDark, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _TodaysEnergyCards(),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  // ── Breakers ────────────────────────────────
                  Row(
                    children: [
                      const Icon(Symbols.electrical_services,
                          color: _kDark, size: 20),
                      const SizedBox(width: 8),
                      Text(s.breakersTitle,
                          style: const TextStyle(
                              color: _kDark, fontSize: 17, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (trippedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusAlarm.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$trippedCount ${s.breakerTripped}',
                            style: const TextStyle(
                                color: AppColors.statusAlarm,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Breakers grid — real devices only. No gateway currently
                  // reports circuit breakers, so this is honestly empty for
                  // almost everyone rather than showing invented rooms.
                  if (breakerDevices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.tCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.tBorder),
                      ),
                      child: Row(children: [
                        Icon(Symbols.electrical_services,
                            color: _kGrey, size: 18),
                        const SizedBox(width: 10),
                        Text(s.notConnectedLabel,
                            style: const TextStyle(color: _kGrey, fontSize: 13)),
                      ]),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: breakerDevices.map((d) {
                        final col = _breakerColor(d);
                        final tripped = d.status == DeviceStatus.alarm;
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tripped
                                ? AppColors.statusAlarm.withValues(alpha: 0.08)
                                : context.tCard,
                            borderRadius: BorderRadius.circular(14),
                            border: tripped
                                ? Border.all(
                                    color: AppColors.statusAlarm.withValues(alpha: 0.4),
                                    width: 1.5)
                                : Border.all(color: context.tBorder),
                            boxShadow: context.isLight
                                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)]
                                : const [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: col),
                              ),
                              const SizedBox(height: 6),
                              Text(d.name,
                                  style: TextStyle(color: _kDark, fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center),
                              Text(_breakerLabel(s, d),
                                  style: TextStyle(
                                      color: col, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  // ── Navigation button ──────────────────────────
                  // Solar System is now its own interactive card in the
                  // "Today's Energy" section above — this button used to
                  // duplicate that exact destination.
                  Row(children: [
                    Expanded(
                      child: FtButton(
                        label: s.breakersTitle,
                        leadingIcon: Symbols.electrical_services,
                        variant: FtButtonVariant.secondary,
                        expand: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const BreakersScreen()));
                        },
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Today's Energy — two real-data cards: smart switch/plug count (+ actual
// energy readings when the devices report them) and solar system status.
// Deliberately shows "no data" rather than a placeholder number — this
// section is the one part of the energy sheet that's fully live.
// ─────────────────────────────────────────────────────────────────
// Sum of today's real energy-meter readings (kWh only — a power meter in W
// reports instantaneous draw, not accumulated energy, and summing the two
// would silently produce a meaningless number). Null when no real energy
// meter reports anything, so callers show an honest "no data" state instead
// of a placeholder number. Shared by every energy widget on this screen so
// there's exactly one definition of "today's energy" in the app.
double? todayEnergyKwh(AppState state) {
  final energyReadings = state.devices
      .where((d) => d.type == DeviceType.energyMeter)
      .where((d) => (d.attributes['unit'] as String?)?.toLowerCase() == 'kwh')
      .map((d) => (d.attributes['reading'] as num?)?.toDouble())
      .whereType<double>()
      .toList();
  return energyReadings.isEmpty
      ? null
      : energyReadings.fold<double>(0.0, (a, b) => a + b);
}

class _TodaysEnergyCards extends StatelessWidget {
  const _TodaysEnergyCards();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final switchDevices = state.devices.where((d) =>
        d.type == DeviceType.smartSwitch || d.type == DeviceType.smartPlug).toList();
    final todayKwh = todayEnergyKwh(state);

    // Solar: no inverter integration is actually wired up yet (SolarScreen
    // itself only ever shows real data post-connection, currently never
    // populated) — show a real "not connected" state instead of a fake
    // production/battery number.

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SmartSwitchHubScreen())),
            child: _TodayEnergyCard(
              icon: Symbols.toggle_on,
              iconColor: AppColors.plugColor,
              title: s.switchesCategory,
              lines: [
                '${switchDevices.length} ${s.devicesUnit}',
                todayKwh != null
                    ? '${todayKwh.toStringAsFixed(1)} kWh ${s.energyToday}'
                    : s.noResults,
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SolarScreen())),
            child: _TodayEnergyCard(
              icon: Symbols.solar_power,
              iconColor: const Color(0xFFFFB800),
              title: s.solarTitle,
              lines: [s.notConnectedLabel],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayEnergyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> lines;
  const _TodayEnergyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: context.tText, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line,
                  style: TextStyle(color: context.tText2(0.6), fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Unread-notification badge — wraps a banner's icon avatar so it
// reports a count, same pattern used by the quick-actions row.
// ─────────────────────────────────────────────────────────────────
class _TopicBadge extends StatelessWidget {
  final int count;
  const _TopicBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: AppColors.statusAlarm,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Widget _iconAvatarWithBadge({
  required Widget avatar,
  required int badgeCount,
}) =>
    Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (badgeCount > 0)
          Positioned(
            top: -4, right: -4,
            child: _TopicBadge(count: badgeCount),
          ),
      ],
    );

// ─────────────────────────────────────────────────────────────────
// Small "quick settings" gear shown on every topic banner — jumps
// straight to the most useful action for that topic (not just the
// same destination as tapping the banner).
// ─────────────────────────────────────────────────────────────────
class _BannerGearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BannerGearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Symbols.settings,
          color: Colors.white, size: 17,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AI Hero Card — Fanta AI front and center. Tapping the card or the
// mic opens the full assistant; the chip row underneath dispatches
// compact search-bar style: one tap anywhere opens the full assistant.
// No quick-action chips here — those add real device-control weight to
// a home-screen element that's meant to be a lightweight entry point.
// ─────────────────────────────────────────────────────────────────
class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard();

  void _openAi(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const FantaAIScreen()));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _openAi(context),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: context.tCard,
            borderRadius: BorderRadius.circular(100),
            boxShadow: context.isLight ? AppShadows.md : AppShadows.dark,
            border: Border.all(
              color: context.isLight
                  ? AppColors.lightBorder
                  : AppColors.darkBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(_kOrange, intensity: 0.5),
                ),
                child: const Icon(Symbols.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.aiSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd
                      .copyWith(color: context.tTextSecondary),
                ),
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Symbols.mic, color: _kOrange, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Security Banner — PRIMARY hero card. Most important element.
// ─────────────────────────────────────────────────────────────────
class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    final state       = context.watch<AppState>();
    final s           = state.strings;
    final armed       = state.isSecured;
    final devices     = state.devices;
    final sensors     = devices.where((d) =>
        d.type == DeviceType.motionSensor ||
        d.type == DeviceType.doorSensor   ||
        d.type == DeviceType.windowSensor ||
        d.type == DeviceType.smokeSensor  ||
        d.type == DeviceType.glassBreakSensor).length;
    final locks       = devices.where((d) => d.type == DeviceType.smartLock).length;
    final cameras     = state.cameras.where((c) => c.isOnline).length;
    final intercoms   = devices.where((d) => d.type == DeviceType.intercom).length;

    const securityTypes = {
      DeviceType.smartLock, DeviceType.doorSensor, DeviceType.windowSensor,
      DeviceType.motionSensor, DeviceType.smokeSensor, DeviceType.gasSensor,
      DeviceType.waterLeakSensor, DeviceType.glassBreakSensor,
      DeviceType.camera, DeviceType.alarmPanel,
      DeviceType.intercom, DeviceType.garage,
    };
    final unreadAlerts = state.notifications
        .where((n) => !n.isRead && securityTypes.contains(n.deviceType))
        .length;

    final Color baseColor   = armed ? const Color(0xFF006064) : const Color(0xFFB71C1C);
    final List<Color> gradColors = armed
        ? [const Color(0xFF006064), const Color(0xFF00838F)]
        : [const Color(0xFFC62828), const Color(0xFFB71C1C)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        label: '${s.securitySystemLabel} — ${armed ? s.secArmedShort : s.secDisarmedShort}',
        button: true,
        child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppBorderRadius.cardLg,
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: baseColor.withValues(alpha: 0.20),
                blurRadius: 48,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Main row ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20, AppSpacing.s20, AppSpacing.s16, AppSpacing.s16),
                child: Row(
                  children: [
                    // Animated lock icon
                    _iconAvatarWithBadge(
                      badgeCount: unreadAlerts,
                      avatar: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        ),
                        child: Icon(
                          armed ? Symbols.lock : Symbols.lock_open,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    // Status text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.securitySystemLabel,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.70),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            armed ? s.secArmedShort : s.secDisarmedShort,
                            style: AppTypography.displaySm.copyWith(
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Row(
                            children: [
                              _topicStatusDot(
                                  armed ? DeviceStatus.online : DeviceStatus.warning),
                              const SizedBox(width: AppSpacing.s4),
                              Text(
                                s.allOkLabel,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quick settings gear → open Security screen directly
                    _BannerGearButton(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SecurityScreen())),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    // Chevron
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.chevron_right,
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Stats strip ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.s12, 0, AppSpacing.s12, AppSpacing.s12),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  borderRadius: AppBorderRadius.card,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SecurityStat(
                        icon: Symbols.sensors,
                        value: '$sensors',
                        label: s.statusSensors,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SensorHubScreen()))),
                    const _SecurityDivider(),
                    _SecurityStat(
                        icon: Symbols.lock,
                        value: '$locks',
                        label: s.qaLock,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SmartLockHubScreen()))),
                    const _SecurityDivider(),
                    _SecurityStat(
                        icon: Symbols.videocam,
                        value: '$cameras',
                        label: s.navCameras,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CamerasScreen()))),
                    const _SecurityDivider(),
                    _SecurityStat(
                        icon: Symbols.doorbell,
                        value: '$intercoms',
                        label: s.planIntercomLabel,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const IntercomHubScreen()))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),   // GestureDetector
      ),   // Semantics
    );
  }
}

class _SecurityStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _SecurityStat({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.70), size: 16),
          const SizedBox(height: AppSpacing.s4),
          Text(
            value,
            style: AppTypography.titleMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
                color: Colors.white.withValues(alpha: 0.55)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SecurityDivider extends StatelessWidget {
  const _SecurityDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Smart Home Banner — hero card for all smart home devices
// ─────────────────────────────────────────────────────────────────
class _SmartHomeBanner extends StatelessWidget {
  const _SmartHomeBanner();

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final s       = state.strings;
    final devices = state.devices;

    bool isGw(Device d) => d.source == 'gateway';

    final lightsOn    = devices.where((d) => isGw(d) && d.type == DeviceType.light && d.isOn).length;
    final lightsAll   = devices.where((d) => isGw(d) && d.type == DeviceType.light).length;
    final switchesOn  = devices.where((d) => isGw(d) && d.type == DeviceType.smartSwitch && d.isOn).length;
    final plugsOn     = devices.where((d) => isGw(d) && d.type == DeviceType.smartPlug && d.isOn).length;
    final heaterOn    = devices.where((d) => isGw(d) && d.type == DeviceType.waterHeater && d.isOn).length;

    final totalAll    = devices.where(isGw).length;
    final totalActive = lightsOn + switchesOn + plugsOn + heaterOn;
    final anyOffline  = devices.where(isGw).any((d) => d.status == DeviceStatus.offline);

    const smartHomeTypes = {
      DeviceType.light, DeviceType.blind, DeviceType.smartPlug,
      DeviceType.smartSwitch, DeviceType.waterHeater,
      DeviceType.smartTv, DeviceType.matterDevice,
    };
    final unreadAlerts = state.notifications
        .where((n) => !n.isRead && smartHomeTypes.contains(n.deviceType))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        label: s.smartHomeTitle,
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SmartHomeScreen())),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2F00), Color(0xFF3A1200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorderRadius.cardLg,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2F00).withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF7B2F00).withValues(alpha: 0.20),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Main row ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20, AppSpacing.s20, AppSpacing.s16, AppSpacing.s16),
                  child: Row(
                    children: [
                      // Home IoT icon
                      _iconAvatarWithBadge(
                        badgeCount: unreadAlerts,
                        avatar: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: const Icon(
                            Symbols.home_iot_device,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      // Status text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.smartHomeTitle,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.70),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              s.deviceCountFmt.replaceAll('{n}', '$totalAll'),
                              style: AppTypography.displaySm.copyWith(
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Row(
                              children: [
                                _topicStatusDot(
                                    anyOffline ? DeviceStatus.warning : DeviceStatus.online),
                                const SizedBox(width: AppSpacing.s4),
                                Text(
                                  '$totalActive ${s.devicesOn}',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Quick settings gear → jump straight to add device
                      _BannerGearButton(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      // Chevron
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Symbols.chevron_right,
                          color: Colors.white, size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Device category strip ──────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(
                      AppSpacing.s12, 0, AppSpacing.s12, AppSpacing.s12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8, vertical: AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: AppBorderRadius.card,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ShStat(
                          icon: Symbols.lightbulb,
                          value: '$lightsOn/$lightsAll',
                          label: s.qaLights,
                          color: AppColors.lightColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LightsHubScreen()))),
                      const _ShDivider(),
                      _ShStat(
                          icon: Symbols.toggle_on,
                          value: '$switchesOn',
                          label: s.switchesCategory,
                          color: AppColors.plugColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SmartSwitchHubScreen()))),
                      const _ShDivider(),
                      _ShStat(
                          icon: Symbols.power,
                          value: '$plugsOn',
                          label: s.qaPlugs,
                          color: AppColors.plugColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PlugsHubScreen()))),
                      const _ShDivider(),
                      _ShStat(
                          icon: Symbols.water_drop,
                          value: '$heaterOn',
                          label: s.qaWaterHeater,
                          color: AppColors.networkColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const DevicesScreen(
                                  initialCategory: DeviceType.waterHeater)))),
                    ],
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

class _ShStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ShStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: AppSpacing.s4),
          Text(
            value,
            style: AppTypography.titleMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
                color: Colors.white.withValues(alpha: 0.55)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShDivider extends StatelessWidget {
  const _ShDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Home Management Banner — household members, PIN, invites
// ─────────────────────────────────────────────────────────────────
class _HomeManagementBanner extends StatelessWidget {
  const _HomeManagementBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s     = state.strings;
    final members = state.homeUsers.length;
    final status  = state.hasHomeManager ? DeviceStatus.online : DeviceStatus.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        label: s.homeManagementTitle,
        button: true,
        child: GestureDetector(
          onTap: () => showHomeManagementSheet(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s16, AppSpacing.s16, AppSpacing.s16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorderRadius.cardLg,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                      ),
                      child: const Icon(
                        Symbols.groups,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.homeManagementTitle,
                            style: AppTypography.titleMd.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _topicStatusDot(status),
                              const SizedBox(width: AppSpacing.s4),
                              Text(
                                '$members ${s.usersTitle} · ${_topicStatusWord(status, s)}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quick settings gear → open household management sheet
                    _BannerGearButton(
                      onTap: () => showHomeManagementSheet(context),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Symbols.chevron_right,
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                // ── Sub-links: rooms + energy + AC ────────────────
                Row(
                  children: [
                    Expanded(
                      child: _HmSubLink(
                        icon: Symbols.door_front,
                        label: s.roomsHeader,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RoomsScreen())),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _HmSubLink(
                        icon: Symbols.bolt,
                        label: s.energyTitle,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EnergyScreen())),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _HmSubLink(
                        icon: Symbols.thermostat,
                        label: s.qaAc,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ACHubScreen())),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HmSubLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HmSubLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: AppBorderRadius.card,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSm.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Store Banner — plans, add-ons and accessories
// ─────────────────────────────────────────────────────────────────
class _StoreBanner extends StatelessWidget {
  const _StoreBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        label: s.storeTitle,
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StoreScreen())),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s16, AppSpacing.s16, AppSpacing.s16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCC6200), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorderRadius.cardLg,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCC6200).withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: const Icon(
                    Symbols.storefront,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Text(
                    s.storeTitle,
                    style: AppTypography.titleMd.copyWith(color: Colors.white),
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.chevron_right,
                    color: Colors.white, size: 20,
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

// ─────────────────────────────────────────────────────────────────
// Media Banner — speakers, casting, now-playing
// ─────────────────────────────────────────────────────────────────
class _MediaBanner extends StatelessWidget {
  const _MediaBanner();

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final s       = state.strings;
    final devices = state.mediaDevices;

    final online   = devices.where((d) => d.isOnline).length;
    final playing  = devices.where((d) => d.isPlaying).toList();
    final nowPlaying = playing.isNotEmpty ? playing.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Semantics(
        label: s.mediaTitle,
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MediaScreen())),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s16, AppSpacing.s16, AppSpacing.s16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5E5A), Color(0xFF12857E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppBorderRadius.cardLg,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F5E5A).withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Icon(
                    nowPlaying != null ? Symbols.music_note : Symbols.speaker,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.mediaTitle,
                        style: AppTypography.titleMd.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nowPlaying != null
                            ? '${nowPlaying.track} · ${nowPlaying.artist}'
                            : '$online ${s.mediaSpeakers}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.chevron_right,
                    color: Colors.white, size: 20,
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

// ─────────────────────────────────────────────────────────────────
// Cameras Section
// ─────────────────────────────────────────────────────────────────
class _CamerasSection extends StatelessWidget {
  const _CamerasSection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cameras = state.cameras;
    final s = state.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(title: s.navCameras, actionLabel: s.showAll, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CamerasScreen()));
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cameras.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _CameraCard(
                cam: cameras[i],
                liveLabel: s.liveLabel,
                motionLabel: s.camMotion,
                onlineLabel: s.camOnline,
                offlineLabel: s.camOffline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  final Camera cam;
  final String liveLabel;
  final String motionLabel;
  final String onlineLabel;
  final String offlineLabel;
  const _CameraCard({
    required this.cam,
    required this.liveLabel,
    required this.motionLabel,
    required this.onlineLabel,
    required this.offlineLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CameraPlayerScreen(camera: cam)),
      ),
      child: Container(
      width: 152,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2535), Color(0xFF2C3E55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Faint camera icon
          Center(
            child: Icon(Symbols.videocam,
                color: Colors.white.withValues(alpha: 0.15), size: 52),
          ),
          // LIVE badge
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(liveLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
          // Name + status
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.select((AppState st) => st.strings).translateCameraName(cam.name),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cam.isOnline
                              ? (cam.motionDetection
                                  ? AppColors.statusWarning
                                  : AppColors.statusOnline)
                              : AppColors.statusAlarm,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          cam.isOnline
                              ? (cam.motionDetection ? motionLabel : onlineLabel)
                              : offlineLabel,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
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
    ),   // Container
    );   // GestureDetector
  }
}


// ─────────────────────────────────────────────────────────────────
// Quick Actions Section
// ─────────────────────────────────────────────────────────────────
class _QuickActionsSection extends StatefulWidget {
  const _QuickActionsSection();

  @override
  State<_QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<_QuickActionsSection> {
  int _sel = -1; // -1 = no panel open

  void _select(int i) {
    final next = (_sel == i) ? -1 : i; // tap same button again → close
    setState(() => _sel = next);
  }

  Widget _buildActionBtn(
    BuildContext context,
    int i,
    ({IconData icon, String label}) a,
    int badge,
    bool sel,
  ) {
    return GestureDetector(
      onTap: () {
        if (i == 7) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BreakersScreen()));
          return;
        }
        _select(i);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? _kOrange : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (sel ? _kOrange : Colors.black)
                          .withValues(alpha: sel ? 0.28 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(a.icon,
                    color: sel ? Colors.white : _kGrey, size: 26),
              ),
              if (badge > 0)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : _kOrange,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: sel ? _kOrange : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sel ? _kOrange : _kDark,
              fontSize: 11,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    // Status badges per button — only real gateway devices
    bool isGw(Device d) => d.source == 'gateway';
    final lockCount   = state.devices.where((d) => isGw(d) &&
        (d.type == DeviceType.smartLock || d.type == DeviceType.doorSensor)).length;
    final lightCount  = state.devices.where((d) => isGw(d) && d.type == DeviceType.light && d.isOn).length;
    final acCount     = state.devices.where((d) => isGw(d) && d.type == DeviceType.airConditioner && d.isOn).length;
    final camOnline   = state.cameras.where((c) => c.isOnline).length;
    final alertCount  = state.notifications.where((n) => !n.isRead).length;
    final plugCount   = state.devices.where((d) => isGw(d) && d.type == DeviceType.smartPlug && d.isOn).length;
    final heaterCount = state.devices.where((d) => isGw(d) && d.type == DeviceType.waterHeater && d.isOn).length;

    final intercomCount = state.devices.where((d) => isGw(d) && d.type == DeviceType.intercom && d.isOn).length;

    final badges = [lockCount, lightCount, acCount, camOnline, alertCount, plugCount, heaterCount, 0, intercomCount];

    final actions = <({IconData icon, String label})>[
      (icon: Symbols.lock,           label: s.qaLock),
      (icon: Symbols.lightbulb,      label: s.qaLights),
      (icon: Symbols.thermostat,     label: s.qaAc),
      (icon: Symbols.videocam,       label: s.qaCameras),
      (icon: Symbols.notifications,  label: s.qaAlerts),
      (icon: Symbols.power,          label: s.qaPlugs),
      (icon: Symbols.water_drop,     label: s.qaWaterHeater),
      (icon: Symbols.electrical_services, label: s.qaBreakers),
      (icon: Symbols.doorbell,       label: s.planIntercomLabel),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: s.quickActions,
            actionLabel: s.showAll,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DevicesScreen())),
          ),
          const SizedBox(height: 14),
          // ── 2-row quick action grid (5 + 4 items, smaller icons) ──
          Column(
            children: [
              Row(
                children: List.generate(5, (i) => Expanded(
                  child: Center(
                    child: _buildActionBtn(
                        context, i, actions[i], badges[i], i == _sel),
                  ),
                )),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ...List.generate(4, (i) => Expanded(
                    child: Center(
                      child: _buildActionBtn(
                          context, i + 5, actions[i + 5], badges[i + 5], (i + 5) == _sel),
                    ),
                  )),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Content panel ──────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _sel >= 0
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_sel),
                      child: _QaPanel(sel: _sel, state: state, s: s),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _QaPanel extends StatelessWidget {
  final int sel;
  final AppState state;
  final dynamic s;
  const _QaPanel({required this.sel, required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: _card(context),
      child: switch (sel) {
        0 => _QaDevicesPanel(
            types: const [DeviceType.smartLock, DeviceType.doorSensor],
            state: state, s: s),
        1 => _QaDevicesPanel(
            types: const [DeviceType.light],
            state: state, s: s),
        2 => _QaDevicesPanel(
            types: const [DeviceType.airConditioner],
            state: state, s: s),
        3 => _QaCamerasPanel(state: state, s: s, context: context),
        4 => _QaAlertsPanel(state: state, s: s),
        5 => _QaDevicesPanel(
            types: const [DeviceType.smartPlug],
            state: state, s: s),
        6 => _QaDevicesPanel(
            types: const [DeviceType.waterHeater],
            state: state, s: s),
        8 => _QaDevicesPanel(
            types: const [DeviceType.intercom],
            state: state, s: s),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// Devices (Lock / Lights / AC / Plugs)
class _QaDevicesPanel extends StatelessWidget {
  final List<DeviceType> types;
  final AppState state;
  final dynamic s;
  const _QaDevicesPanel({required this.types, required this.state, required this.s});

  static const _toggleableTypes = {
    DeviceType.smartPlug, DeviceType.smartSwitch, DeviceType.light,
    DeviceType.airConditioner, DeviceType.waterHeater, DeviceType.smartLock,
    DeviceType.blind, DeviceType.intercom,
  };

  bool get _canToggle => types.any(_toggleableTypes.contains);

  @override
  Widget build(BuildContext context) {
    final devs = state.devices
        .where((d) => types.contains(d.type))
        .toList();
    if (devs.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.qaNoDevices,
                  style: const TextStyle(color: _kGrey, fontSize: 13)),
              FtButton(
                label: s.qaScanDevice,
                leadingIcon: Symbols.add,
                size: FtButtonSize.sm,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        ...devs.take(4).map((d) {
          final toggleable = _toggleableTypes.contains(d.type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // ── Icon + name — long-press zone for edit ────────
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => _showEdit(context, d),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: (d.isOn ? _kOrange : _kGrey).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_iconForType(d.type),
                              color: d.isOn ? _kOrange : _kGrey, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(d.name,
                              style: AppTypography.titleSm.copyWith(
                                  color: context.tText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Toggle pill — isolated tap zone ───────────────
                const SizedBox(width: 8),
                if (toggleable)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => state.toggleDevice(d.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: d.isOn
                            ? _kOrange
                            : _kGrey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: d.isOn
                            ? [
                                BoxShadow(
                                  color: _kOrange.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : const [],
                      ),
                      child: Text(
                        d.isOn ? s.deviceOn : s.deviceOff,
                        style: TextStyle(
                          color: d.isOn ? Colors.white : _kGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: d.isOn
                          ? _kOrange.withValues(alpha: 0.10)
                          : _kGrey.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(d.isOn ? s.deviceOn : s.deviceOff,
                        style: TextStyle(
                            color: d.isOn ? _kOrange : _kGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 2),
        // All on / all off buttons
        if (_canToggle) ...[
          Row(children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  for (final d in devs) {
                    if (!d.isOn) state.toggleDevice(d.id);
                  }
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.power_settings_new,
                          size: 12, color: _kOrange),
                      const SizedBox(width: 4),
                      Text(s.plugsAllOn,
                          style: const TextStyle(
                              color: _kOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  for (final d in devs) {
                    if (d.isOn) state.toggleDevice(d.id);
                  }
                },
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kGrey.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.power_off,
                          size: 12, color: _kGrey),
                      const SizedBox(width: 4),
                      Text(s.plugsAllOff,
                          style: const TextStyle(
                              color: _kGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FtButton(
              label: s.qaScanDevice,
              leadingIcon: Symbols.add_circle,
              variant: FtButtonVariant.ghost,
              size: FtButtonSize.sm,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
            ),
          ],
        ),
      ],
    );
  }

  IconData _iconForType(DeviceType t) => switch (t) {
    DeviceType.light          => Symbols.lightbulb,
    DeviceType.airConditioner => Symbols.thermostat,
    DeviceType.smartLock      => Symbols.lock,
    DeviceType.doorSensor     => Symbols.sensor_door,
    DeviceType.smartPlug      => Symbols.power,
    DeviceType.waterHeater    => Symbols.water_drop,
    DeviceType.intercom       => Symbols.doorbell,
    _                         => Symbols.devices,
  };

  void _showEdit(BuildContext context, Device d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DeviceQuickEditSheet(device: d, state: state, s: s),
    );
  }
}

// Quick edit sheet for home-screen QA panel devices
class _DeviceQuickEditSheet extends StatefulWidget {
  final Device device;
  final AppState state;
  final dynamic s;
  const _DeviceQuickEditSheet(
      {required this.device, required this.state, required this.s});

  @override
  State<_DeviceQuickEditSheet> createState() => _DeviceQuickEditSheetState();
}

class _DeviceQuickEditSheetState extends State<_DeviceQuickEditSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.device.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s     = widget.s;
    final color = _kOrange;

    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: context.tText2(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Icon + type label
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Symbols.power, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              s.deviceNameLabel,
              style: TextStyle(
                  color: context.tText2(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ]),
          const SizedBox(height: 16),
          // Name field
          TextField(
            controller: _ctrl,
            autofocus: true,
            textDirection: TextDirection.rtl,
            style: TextStyle(
                color: context.tText, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.tText2(0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: color.withValues(alpha: 0.50), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save / Cancel
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final name = _ctrl.text.trim();
                  if (name.isNotEmpty) {
                    widget.state.updateDeviceName(widget.device.id, name);
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(s.save,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.tText2(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(
                            color: context.tText2(0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Remove device
          GestureDetector(
            onTap: () {
              widget.state.removeDevice(widget.device.id);
              Navigator.pop(context);
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.unsecured.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.unsecured.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.delete,
                      color: AppColors.unsecured, size: 17),
                  const SizedBox(width: 7),
                  Text(s.remove,
                      style: TextStyle(
                          color: AppColors.unsecured,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cameras
class _QaCamerasPanel extends StatelessWidget {
  final AppState state;
  final dynamic s;
  final BuildContext context;
  const _QaCamerasPanel({required this.state, required this.s, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final cams = state.cameras;
    return Column(
      children: [
        ...cams.take(3).map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.videocam, color: _kOrange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(c.name,
                    style: AppTypography.titleSm.copyWith(color: ctx.tText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.isOnline
                      ? AppColors.statusOnline
                      : AppColors.statusOffline,
                ),
              ),
              const SizedBox(width: 6),
              Text(c.isOnline ? s.camOnline : s.camOffline,
                  style: AppTypography.labelSm.copyWith(
                      color: c.isOnline
                          ? AppColors.statusOnline
                          : AppColors.statusOffline)),
            ],
          ),
        )),
        const SizedBox(height: 4),
        FtButton(
          label: s.qaScanDevice,
          leadingIcon: Symbols.radar,
          variant: FtButtonVariant.secondary,
          expand: true,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ScanDiscoveryScreen(cameraOnly: true))),
        ),
      ],
    );
  }
}

// Alerts
class _QaAlertsPanel extends StatelessWidget {
  final AppState state;
  final dynamic s;
  const _QaAlertsPanel({required this.state, required this.s});

  @override
  Widget build(BuildContext context) {
    final notifs = state.notifications.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notifs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Symbols.notifications_none, color: _kGrey, size: 18),
                const SizedBox(width: 8),
                Text(s.qaNoAlerts,
                    style: const TextStyle(color: _kGrey, fontSize: 13)),
              ],
            ),
          )
        else
          ...notifs.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Symbols.notifications,
                      color: _kOrange, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: AppTypography.bodyMd.copyWith(
                              color: n.isRead
                                  ? context.tTextSecondary
                                  : context.tText,
                              fontWeight: n.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        _relativeTime(n.timestamp, s),
                        style: const TextStyle(color: _kGrey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kOrange,
                    ),
                  ),
              ],
            ),
          )),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: FtButton(
                label: s.qaResetAll,
                variant: FtButtonVariant.danger,
                size: FtButtonSize.sm,
                expand: true,
                onTap: () => state.clearNotifications(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FtButton(
                label: s.save,
                variant: FtButtonVariant.secondary,
                size: FtButtonSize.sm,
                expand: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _relativeTime(DateTime t, S s) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return s.timeNow;
    if (diff.inMinutes < 60) return s.timeMinAgo.replaceAll('{n}', '${diff.inMinutes}');
    if (diff.inHours < 24) return s.timeHrAgo.replaceAll('{n}', '${diff.inHours}');
    return s.timeDayAgo.replaceAll('{n}', '${diff.inDays}');
  }
}

// ─────────────────────────────────────────────────────────────────
// System Status Section
// ─────────────────────────────────────────────────────────────────
class _SystemStatusSection extends StatefulWidget {
  const _SystemStatusSection();
  @override
  State<_SystemStatusSection> createState() => _SystemStatusSectionState();
}

class _SystemStatusSectionState extends State<_SystemStatusSection> {
  bool _gwExpanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _toggleGw() {
    _collapseTimer?.cancel();
    setState(() => _gwExpanded = !_gwExpanded);
    if (_gwExpanded) {
      _collapseTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _gwExpanded = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final gateways = context.watch<GatewayManager>();
    final s = state.strings;

    final connectedGws = gateways.connections.where((c) => c.isConnected).toList();
    final totalGws     = gateways.connections.length;
    final hasInternet  = connectedGws.isNotEmpty;
    final gwDevices    = state.devices.where((d) => d.source == 'gateway').toList();
    final totalDevices = gwDevices.length;
    final onlineDev    = gwDevices.where((d) => d.status == DeviceStatus.online).length;
    final totalCams    = state.cameras.length;
    final onlineCams   = state.cameras.where((c) => c.isOnline).length;

    void openGateways() {
      _collapseTimer?.cancel();
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GatewayHubScreen()));
    }

    void openSensors() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SensorHubScreen()));
    void openCameras() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CamerasScreen()));

    final items = <({IconData icon, String label, String value, bool ok, VoidCallback onTap})>[
      (
        icon:  Symbols.language,
        label: s.statusInternet,
        value: hasInternet ? s.connectedLabel : s.statusOffline,
        ok:    hasInternet,
        onTap: openGateways,
      ),
      (
        icon:  Symbols.sensors,
        label: s.statusSensors,
        // Show real counts only while at least one gateway is connected.
        // Disconnected state means the counts are stale.
        value: !hasInternet || totalDevices == 0 ? '—' : '$onlineDev/$totalDevices',
        ok:    !hasInternet || totalDevices == 0 || onlineDev == totalDevices,
        onTap: openSensors,
      ),
      (
        icon:  Symbols.videocam,
        label: s.navCameras,
        value: !hasInternet || totalCams == 0 ? '—' : '$onlineCams/$totalCams',
        ok:    !hasInternet || totalCams == 0 || onlineCams == totalCams,
        onTap: openCameras,
      ),
    ];

    Widget statusCard({
      required IconData icon,
      required String label,
      required String value,
      required bool ok,
      required VoidCallback onTap,
    }) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
          child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 112,
            padding: AppSpacing.p12,
            decoration: _card(context, radius: AppBorderRadius.r12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Icon(icon, color: context.tTextSecondary, size: 14),
                  const Spacer(),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ok ? _kGreen : AppColors.alert,
                      boxShadow: [
                        BoxShadow(
                          color: (ok ? _kGreen : AppColors.alert)
                              .withValues(alpha: 0.40),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.s8),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSm.copyWith(color: context.tText)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                        color: context.tTextSecondary)),
              ],
            ),
          ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionHeader(
            title: s.systemStatus,
            actionLabel: s.gatewaysManage,
            onTap: openGateways,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // ── Gateways card (expandable) ──────────────────
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: GestureDetector(
                  onTap: _toggleGw,
                  child: Container(
                    width: 112,
                    padding: AppSpacing.p12,
                    decoration: _card(context, radius: AppBorderRadius.r12).copyWith(
                      border: Border.all(
                        color: _gwExpanded
                            ? _kOrange.withValues(alpha: 0.60)
                            : (context.isLight
                                ? AppColors.lightBorder
                                : AppColors.darkBorder.withValues(alpha: 0.6)),
                        width: _gwExpanded ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(children: [
                          Icon(Symbols.hub,
                              color: context.tTextSecondary, size: 14),
                          const Spacer(),
                          Icon(
                            _gwExpanded
                                ? Symbols.keyboard_arrow_up
                                : Symbols.keyboard_arrow_down,
                            color: context.tTextSecondary, size: 14,
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.s8),
                        Text(s.gatewaysTitle,
                            style: AppTypography.titleSm.copyWith(
                                color: context.tText)),
                        Text(
                          totalGws == 0
                              ? '—'
                              : '${connectedGws.length}/$totalGws',
                          style: AppTypography.caption.copyWith(
                            color: connectedGws.isNotEmpty
                                ? _kGreen
                                : AppColors.alert,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Status cards ────────────────────────────────
              for (final it in items)
                statusCard(
                  icon: it.icon, label: it.label,
                  value: it.value, ok: it.ok, onTap: it.onTap,
                ),
            ],
          ),
        ),
        // ── Gateways expanded panel ─────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: _gwExpanded
              ? _GatewayStatusPanel(
                  connections: gateways.connections,
                  onManage: openGateways,
                  s: s,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _GatewayStatusPanel extends StatelessWidget {
  final List<GatewayConnection> connections;
  final VoidCallback onManage;
  final S s;

  const _GatewayStatusPanel({
    required this.connections,
    required this.onManage,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
      padding: AppSpacing.card,
      decoration: _card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (connections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Center(
                child: Text(
                  s.statusOffline,
                  style: AppTypography.bodyMd.copyWith(
                      color: context.tTextSecondary),
                ),
              ),
            )
          else
            ...connections.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.isConnected ? _kGreen : AppColors.alert,
                    boxShadow: [
                      BoxShadow(
                        color: (c.isConnected ? _kGreen : AppColors.alert)
                            .withValues(alpha: 0.40),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    c.displayName.isNotEmpty ? c.displayName : c.type.name,
                    style: AppTypography.titleSm.copyWith(
                        color: context.tText),
                  ),
                ),
                Text(
                  c.isConnected ? s.connectedLabel : s.statusOffline,
                  style: AppTypography.caption.copyWith(
                    color: c.isConnected ? _kGreen : AppColors.alert,
                  ),
                ),
              ]),
            )),
          const SizedBox(height: 8),
          FtButton(
            label: s.gatewaysManage,
            variant: FtButtonVariant.secondary,
            expand: true,
            onTap: onManage,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Ad Banner
// ─────────────────────────────────────────────────────────────────
class _AdProduct {
  final String name;
  final String price;
  final IconData icon;
  const _AdProduct(this.name, this.price, this.icon);
}

class _AdBanner extends StatefulWidget {
  const _AdBanner();
  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  // Product count is fixed regardless of language — used by the timer.
  static const int _productCount = 5;

  // Returns localized product list — built fresh on each build() call.
  static List<_AdProduct> _buildProducts(S s) => [
    _AdProduct(s.devBulb,          '₪79',  Symbols.lightbulb),
    _AdProduct(s.smartLocksTitle,  '₪399', Symbols.lock),
    _AdProduct(s.qaCameras,        '₪249', Symbols.videocam),
    _AdProduct(s.prodMotionSensor, '₪89',  Symbols.sensors),
    _AdProduct(s.prodSmartPlug,    '₪69',  Symbols.power),
  ];

  String? _customUrl;

  // Rotating "sponsored" highlight — cycles every 3.5s.
  int _featured = 0;
  Timer? _rotTimer;

  @override
  void initState() {
    super.initState();
    _rotTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _featured = (_featured + 1) % _productCount);
    });
  }

  @override
  void dispose() {
    _rotTimer?.cancel();
    super.dispose();
  }

  void _showAddLink() {
    final ctrl = TextEditingController(text: _customUrl ?? '');
    showDialog(
      context: context,
      builder: (_) {
        final s = context.read<AppState>().strings;
        return AlertDialog(
          title: Text(s.adAddLink),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(hintText: 'https://...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.cancel)),
            TextButton(
              onPressed: () {
                setState(() => _customUrl = ctrl.text.trim().isEmpty
                    ? null
                    : ctrl.text.trim());
                Navigator.pop(context);
              },
              child: Text(s.save,
                  style: const TextStyle(color: _kOrange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final products = _buildProducts(s);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kOrange.withValues(alpha: 0.18)),
          boxShadow: context.isLight
              ? const [BoxShadow(color: Color(0x0E000000), blurRadius: 10, offset: Offset(0, 3))]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: _kOrange, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Symbols.storefront, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.storeTitle,
                        style: const TextStyle(
                            color: _kDark, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  // Custom link button
                  FtButton(
                    label: _customUrl != null ? s.adCustomLink : s.adAddLink,
                    leadingIcon: _customUrl != null
                        ? Symbols.link
                        : Symbols.add_link,
                    variant: _customUrl != null
                        ? FtButtonVariant.secondary
                        : FtButtonVariant.neutral,
                    size: FtButtonSize.sm,
                    onTap: _showAddLink,
                  ),
                ],
              ),
            ),
            // Large rotating sponsored ad (auto-cycles every 3.5s) — the only
            // promo element; tapping it opens the store.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StoreScreen())),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey(_featured),
                    width: double.infinity,
                    height: 130,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kOrange.withValues(alpha: 0.18),
                          _kOrange.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kOrange.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: _kOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(products[_featured].icon,
                              color: _kOrange, size: 38),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(products[_featured].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headlineSm.copyWith(
                                      color: context.tText)),
                              const SizedBox(height: 4),
                              Text(products[_featured].price,
                                  style: const TextStyle(
                                      color: _kOrange,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const Icon(Symbols.arrow_forward_ios,
                            color: _kOrange, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared: Section Header
// ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, this.actionLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: AppTypography.headlineSm.copyWith(color: context.tText)),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
              child: Text(actionLabel!,
                  style: AppTypography.labelMd.copyWith(color: _kOrange)),
            ),
          ),
      ],
    );
  }
}
