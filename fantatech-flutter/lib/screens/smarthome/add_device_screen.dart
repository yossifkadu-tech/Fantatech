import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import 'scan_discovery_screen.dart';

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────
class _DeviceItem {
  final String id;
  final IconData icon;
  final String name;
  final String category;
  final Color color;
  const _DeviceItem({
    required this.id,
    required this.icon,
    required this.name,
    required this.category,
    required this.color,
  });
}

class _CatalogSection {
  final String title;
  final String categoryKey;
  final List<_DeviceItem> items;
  const _CatalogSection({
    required this.title,
    required this.categoryKey,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class AddDeviceScreen extends StatefulWidget {
  /// When non-null, opened from a gateway's "Discover Devices" button.
  final Device? gateway;
  const AddDeviceScreen({super.key, this.gateway});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = ''; // empty = all
  final Set<String> _addedIds = {};

  static const _networkColor = Color(0xFF00B4D8);

  // ── Catalog ─────────────────────────────────────────────────
  static List<_CatalogSection> _buildCatalog(S s) => [
    _CatalogSection(title: s.catalogLights, categoryKey: 'lights', items: [
      _DeviceItem(id: 'bulb',  icon: Icons.lightbulb_outlined,    name: s.devBulb,  category: s.catLight, color: AppColors.lightColor),
      _DeviceItem(id: 'strip', icon: Icons.wb_iridescent_outlined, name: s.devStrip, category: s.catLight, color: AppColors.lightColor),
    ]),
    _CatalogSection(title: s.catalogSwitches, categoryKey: 'switches', items: [
      _DeviceItem(id: 'switch1', icon: Icons.toggle_on_outlined,    name: s.devSwitch, category: s.catSwitch, color: AppColors.plugColor),
      _DeviceItem(id: 'dimmer',  icon: Icons.brightness_6_outlined, name: s.devDimmer, category: s.catSwitch, color: AppColors.plugColor),
      _DeviceItem(id: 'plug',    icon: Icons.power_outlined,        name: s.devPlug,   category: s.catPlug,   color: AppColors.plugColor),
    ]),
    _CatalogSection(title: s.catalogSensors, categoryKey: 'sensors', items: [
      _DeviceItem(id: 'motion', icon: Icons.sensors_outlined,      name: s.devMotionSensor,  category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'door',   icon: Icons.sensor_door_outlined,  name: s.devDoorSensor,    category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'window', icon: Icons.window_outlined,       name: s.devWindowSensor,  category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'smoke',  icon: Icons.crisis_alert_outlined, name: s.devSmokeDetector, category: s.catSensor, color: AppColors.unsecured),
    ]),
    _CatalogSection(title: s.catalogCameras, categoryKey: 'cameras', items: [
      _DeviceItem(id: 'cam_in',  icon: Icons.videocam_outlined,       name: s.devIndoorCam,  category: s.catCamera, color: AppColors.cameraColor),
      _DeviceItem(id: 'cam_out', icon: Icons.camera_outdoor_outlined, name: s.devOutdoorCam, category: s.catCamera, color: AppColors.cameraColor),
    ]),
    _CatalogSection(title: s.catalogAC, categoryKey: 'climate', items: [
      _DeviceItem(id: 'ac',        icon: Icons.hvac,                     name: s.devSmartAC,     category: s.catClimate,       color: AppColors.acColor),
      _DeviceItem(id: 'heater',    icon: Icons.water_drop_outlined,      name: s.devWaterHeater, category: s.catClimate,       color: AppColors.acColor),
      _DeviceItem(id: 'thermo',    icon: Icons.thermostat_outlined,      name: s.devThermostat,  category: s.catClimate,       color: AppColors.acColor),
      _DeviceItem(id: 'ac_remote', icon: Icons.settings_remote_outlined, name: s.acRemoteName,   category: s.acRemoteCategory, color: AppColors.acColor),
      _DeviceItem(id: 'ac_wifi',   icon: Icons.wifi_outlined,            name: s.acWifiName,     category: s.acWifiCategory,   color: AppColors.acColor),
    ]),
    _CatalogSection(title: s.catalogBlinds, categoryKey: 'blinds', items: [
      _DeviceItem(id: 'blind', icon: Icons.blinds_outlined, name: s.devSmartBlind, category: s.catBlind, color: AppColors.primary),
      _DeviceItem(id: 'gate',  icon: Icons.garage_outlined, name: s.devSmartGate,  category: s.catGate,  color: AppColors.primary),
    ]),
    _CatalogSection(title: s.catalogNetwork, categoryKey: 'network', items: [
      _DeviceItem(id: 'router_wifi', icon: Icons.router_outlined,         name: s.devRouterWifi, category: s.catRouter,  color: _networkColor),
      _DeviceItem(id: 'gw_zigbee',   icon: Icons.hub_outlined,            name: s.devGwZigbee,   category: s.catGateway, color: _networkColor),
      _DeviceItem(id: 'gw_wifi',     icon: Icons.wifi_tethering_outlined, name: s.devGwWifi,     category: s.catGateway, color: _networkColor),
      _DeviceItem(id: 'gw_matter',   icon: Icons.hub_outlined,            name: s.devGwMatter,   category: s.catGateway, color: _networkColor),
    ]),
  ];

  // ── Map catalog ID → DeviceType ──────────────────────────────
  static DeviceType _typeFor(String id) {
    switch (id) {
      case 'bulb':
      case 'strip':      return DeviceType.light;
      case 'switch1':
      case 'dimmer':     return DeviceType.smartSwitch;
      case 'plug':
      case 'ac_remote':
      case 'ac_wifi':    return DeviceType.smartPlug;
      case 'motion':
      case 'smoke':      return DeviceType.motionSensor;
      case 'door':       return DeviceType.doorSensor;
      case 'window':     return DeviceType.windowSensor;
      case 'cam_in':
      case 'cam_out':    return DeviceType.camera;
      case 'ac':
      case 'thermo':     return DeviceType.airConditioner;
      case 'heater':     return DeviceType.waterHeater;
      case 'blind':
      case 'gate':       return DeviceType.blind;
      case 'router_wifi': return DeviceType.router;
      case 'gw_zigbee':
      case 'gw_wifi':
      case 'gw_matter':  return DeviceType.gateway;
      default:           return DeviceType.smartPlug;
    }
  }

  // ── Protocol label per device id ────────────────────────────
  static String _protocolFor(String id) {
    switch (id) {
      case 'gw_matter':   return 'Matter 1.2';
      case 'gw_zigbee':   return 'Zigbee 3.0';
      case 'gw_wifi':
      case 'router_wifi': return 'WiFi 802.11ax';
      case 'cam_in':
      case 'cam_out':     return 'RTSP / WiFi';
      case 'ac':
      case 'ac_wifi':     return 'WiFi / IR';
      case 'motion':
      case 'door':
      case 'window':
      case 'smoke':       return 'Zigbee 3.0';
      default:            return 'WiFi / BLE';
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Show connect flow ────────────────────────────────────────
  void _showConnectFlow(_DeviceItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DeviceConnectSheet(
        item: item,
        protocol: _protocolFor(item.id),
        onConfirm: (id, name) {
          final state = context.read<AppState>();
          final device = Device(
            id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            type: _typeFor(id),
            status: DeviceStatus.online,
            isOn: _typeFor(id) != DeviceType.router &&
                  _typeFor(id) != DeviceType.gateway,
            attributes: const {},
          );
          state.addDevice(device);
          setState(() => _addedIds.add(id));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name — ${state.strings.added}'),
              backgroundColor: AppColors.secured,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 2000),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );

          // After the sheet pops (from inside), go back to devices list
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) Navigator.maybePop(context);
          });
        },
      ),
    );
  }

  // ── Filtered items ───────────────────────────────────────────
  List<_DeviceItem> _filteredItems(List<_CatalogSection> catalog) {
    return catalog
        .where((sec) =>
            _selectedCategory.isEmpty || sec.categoryKey == _selectedCategory)
        .expand((sec) => sec.items)
        .where((item) =>
            _query.isEmpty ||
            item.name.toLowerCase().contains(_query) ||
            item.category.toLowerCase().contains(_query))
        .toList();
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    final catalog = _buildCatalog(s);
    final items = _filteredItems(catalog);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────
            _TopBar(title: s.addDeviceTitle),

            // ── Gateway context banner ────────────────────────
            if (widget.gateway != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _networkColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _networkColor.withValues(alpha: 0.28)),
                  ),
                  child: Row(children: [
                    Icon(
                      widget.gateway!.type == DeviceType.router
                          ? Icons.router_outlined
                          : Icons.hub_outlined,
                      color: _networkColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.scanViaGateway}: ${widget.gateway!.name}',
                        style: TextStyle(
                          color: _networkColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.secured),
                    ),
                  ]),
                ),
              ),

            // ── Search bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child:
                  _SearchBar(controller: _searchCtrl, hintText: s.searchHint),
            ),

            // ── Scan Network banner ───────────────────────────
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _ScanNetworkBanner(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanDiscoveryScreen(),
                    ),
                  ),
                ),
              ),

            // ── Category chips ────────────────────────────────
            if (_query.isEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    _CategoryChip(
                      label: s.allDevices,
                      icon: Icons.grid_view_rounded,
                      selected: _selectedCategory.isEmpty,
                      onTap: () => setState(() => _selectedCategory = ''),
                    ),
                    ...catalog.map((sec) => _CategoryChip(
                          label: sec.title,
                          icon: _iconForCategory(sec.categoryKey),
                          selected: _selectedCategory == sec.categoryKey,
                          onTap: () => setState(
                              () => _selectedCategory = sec.categoryKey),
                        )),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ── Device grid ───────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              color: context.tText2(0.24), size: 44),
                          const SizedBox(height: 12),
                          Text(s.noResults,
                              style: TextStyle(
                                  color: context.tText2(0.38),
                                  fontSize: 14)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final added = _addedIds.contains(item.id);
                        return _DeviceCard(
                          item: item,
                          added: added,
                          onTap: () => added ? null : _showConnectFlow(item),
                          addLabel: s.add,
                          addedLabel: s.added,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String key) {
    switch (key) {
      case 'lights':   return Icons.lightbulb_outlined;
      case 'switches': return Icons.toggle_on_outlined;
      case 'sensors':  return Icons.sensors_outlined;
      case 'cameras':  return Icons.videocam_outlined;
      case 'climate':  return Icons.hvac;
      case 'blinds':   return Icons.blinds_outlined;
      case 'network':  return Icons.router_outlined;
      default:         return Icons.devices_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Connect flow sheet
// ─────────────────────────────────────────────────────────────
enum _ConnectPhase { scanning, found, linking }

class _DeviceConnectSheet extends StatefulWidget {
  final _DeviceItem item;
  final String protocol;
  final void Function(String id, String name) onConfirm;

  const _DeviceConnectSheet({
    required this.item,
    required this.protocol,
    required this.onConfirm,
  });

  @override
  State<_DeviceConnectSheet> createState() => _DeviceConnectSheetState();
}

class _DeviceConnectSheetState extends State<_DeviceConnectSheet>
    with TickerProviderStateMixin {
  _ConnectPhase _phase = _ConnectPhase.scanning;

  late final AnimationController _pulseCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _foundCtrl;

  @override
  void initState() {
    super.initState();

    // Pulsing rings during scan
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Progress bar during scan (completes in ~2.8 s)
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _scanCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _phase = _ConnectPhase.found);
      _foundCtrl.forward();
    });

    // Scale-in for "found" icon
    _foundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _foundCtrl.dispose();
    super.dispose();
  }

  void _onLink() {
    setState(() => _phase = _ConnectPhase.linking);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onConfirm(widget.item.id, widget.item.name);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    final c = widget.item.color;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.24),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 28),

          // ── Animated visual ────────────────────────────────
          SizedBox(
            width: 130, height: 130,
            child: _phase == _ConnectPhase.scanning
                ? _PulseRingsWidget(
                    ctrl: _pulseCtrl,
                    color: c,
                    icon: widget.item.icon,
                  )
                : _phase == _ConnectPhase.linking
                    ? Center(
                        child: SizedBox(
                          width: 64, height: 64,
                          child: CircularProgressIndicator(
                            color: AppColors.secured,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _foundCtrl,
                          curve: Curves.elasticOut,
                        ),
                        child: _FoundBadgeWidget(
                          color: AppColors.secured,
                          icon: widget.item.icon,
                        ),
                      ),
          ),

          const SizedBox(height: 22),

          // ── Status text ────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _phase == _ConnectPhase.scanning
                  ? s.searching
                  : _phase == _ConnectPhase.linking
                      ? 'מתחבר...'
                      : s.deviceFound,
              key: ValueKey(_phase),
              style: TextStyle(
                color: _phase == _ConnectPhase.found
                    ? AppColors.secured
                    : context.tText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Device name
          Text(
            widget.item.name,
            style: TextStyle(
                color: context.tText2(0.50), fontSize: 14),
          ),

          // ── Scanning progress bar ──────────────────────────
          if (_phase == _ConnectPhase.scanning) ...[
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _scanCtrl.value,
                  backgroundColor: context.tText2(0.08),
                  color: c,
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.protocol,
              style: TextStyle(
                  color: context.tText2(0.30),
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ],

          // ── Found: details + button ────────────────────────
          if (_phase == _ConnectPhase.found) ...[
            const SizedBox(height: 18),
            // Signal / protocol info row
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secured.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.secured.withValues(alpha: 0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.secured),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Signal: ████ · ${widget.protocol}',
                    style: TextStyle(
                        color: AppColors.secured.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: Icon(Icons.link_rounded, size: 19),
                label: Text(
                  s.linkDevice,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _onLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secured,
                  foregroundColor: context.tText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                s.cancel,
                style: TextStyle(
                    color: context.tText2(0.38), fontSize: 13),
              ),
            ),
          ],

          if (_phase == _ConnectPhase.linking) const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pulse rings animation widget
// ─────────────────────────────────────────────────────────────
class _PulseRingsWidget extends StatelessWidget {
  final AnimationController ctrl;
  final Color color;
  final IconData icon;

  const _PulseRingsWidget({
    required this.ctrl,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Opacity(
              opacity: ((1.0 - t) * 0.35).clamp(0.0, 1.0),
              child: Container(
                width: 60 + 70 * t,
                height: 60 + 70 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.2),
                ),
              ),
            ),
            // Middle ring (half-phase offset)
            Opacity(
              opacity: (math.sin(t * math.pi) * 0.4).clamp(0.0, 1.0),
              child: Container(
                width: 50 + 50 * t,
                height: 50 + 50 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.0),
                ),
              ),
            ),
            // Center icon bubble
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(
                    color: color.withValues(alpha: 0.45), width: 1.8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Found badge widget
// ─────────────────────────────────────────────────────────────
class _FoundBadgeWidget extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _FoundBadgeWidget({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 104, height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(icon, color: color, size: 44),
        ),
        Positioned(
          bottom: 6, right: 6,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border:
                    Border.all(color: context.tCard, width: 2.5)),
            child: Icon(Icons.check_rounded,
                color: context.tText, size: 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Device card (compact grid cell)
// ─────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final _DeviceItem item;
  final bool added;
  final VoidCallback? onTap;
  final String addLabel;
  final String addedLabel;

  const _DeviceCard({
    required this.item,
    required this.added,
    required this.onTap,
    required this.addLabel,
    required this.addedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = item.color;
    return GestureDetector(
      onTap: added ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: added
                ? AppColors.secured.withValues(alpha: 0.40)
                : c.withValues(alpha: 0.18),
            width: 1.1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon bubble
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.secured.withValues(alpha: 0.12)
                      : c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  item.icon,
                  color: added ? AppColors.secured : c,
                  size: 13,
                ),
              ),
              // Device name
              Text(
                item.name,
                style: TextStyle(
                  color: added
                      ? context.tText2(0.55)
                      : context.tText2(0.90),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Add / Added chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: added
                      ? AppColors.secured.withValues(alpha: 0.12)
                      : c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: added
                        ? AppColors.secured.withValues(alpha: 0.30)
                        : c.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      added ? Icons.check : Icons.add,
                      size: 11,
                      color: added ? AppColors.secured : c,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      added ? addedLabel : addLabel,
                      style: TextStyle(
                        color: added ? AppColors.secured : c,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category chip
// ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.tCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : context.tText2(0.09),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? context.tText : context.tText2(0.38),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? context.tText : context.tText2(0.38),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scan Network banner
// ─────────────────────────────────────────────────────────────
class _ScanNetworkBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanNetworkBanner({required this.onTap});

  @override
  State<_ScanNetworkBanner> createState() => _ScanNetworkBannerState();
}

class _ScanNetworkBannerState extends State<_ScanNetworkBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              const Color(0xFF7B68EE).withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            // Animated radar icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 38, height: 38,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _MiniRadarPainter(
                      angle: _ctrl.value * 2 * math.pi,
                    ),
                  ),
                ),
              ),
            ),
            // Text column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'סרוק את הרשת',
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WiFi · BLE · Matter · Zigbee',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRadarPainter extends CustomPainter {
  final double angle;
  const _MiniRadarPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 1;

    // Rings
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final frac in [0.40, 0.75, 1.0]) {
      canvas.drawCircle(Offset(cx, cy), r * frac, ringPaint);
    }

    // Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.2,
        endAngle: angle,
        colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.40)],
        transform: GradientRotation(angle - 1.2),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, sweepPaint);

    // Line
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.85)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(
        Offset(cx, cy), 2.5, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_MiniRadarPainter old) => old.angle != angle;
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right,
                  color: context.tText2(0.7), size: 20),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const _SearchBar({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.09)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.tText, fontSize: 13),
        textDirection: context.watch<AppState>().isRtl
            ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              color: context.tText2(0.30), fontSize: 13),
          prefixIcon: Icon(Icons.search,
              color: context.tText2(0.35), size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(Icons.close,
                      color: context.tText2(0.35), size: 16))
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
