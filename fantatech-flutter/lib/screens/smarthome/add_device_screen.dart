import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_button.dart';
import '../../services/discovery/real_discovery_engine.dart';
import '../../services/discovery/discovery_models.dart';
import 'scan_discovery_screen.dart';
import 'wiz_setup_screen.dart';
import 'matter_commission_screen.dart';
import 'sensor_brand_picker_screen.dart';

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
      _DeviceItem(id: 'bulb',  icon: Symbols.lightbulb,    name: s.devBulb,  category: s.catLight, color: AppColors.lightColor),
      _DeviceItem(id: 'strip', icon: Symbols.wb_iridescent, name: s.devStrip, category: s.catLight, color: AppColors.lightColor),
    ]),
    _CatalogSection(title: s.catalogSwitches, categoryKey: 'switches', items: [
      _DeviceItem(id: 'switch1', icon: Symbols.toggle_on,    name: s.devSwitch, category: s.catSwitch, color: AppColors.plugColor),
      _DeviceItem(id: 'dimmer',  icon: Symbols.brightness_6, name: s.devDimmer, category: s.catSwitch, color: AppColors.plugColor),
      _DeviceItem(id: 'plug',    icon: Symbols.power,        name: s.devPlug,   category: s.catPlug,   color: AppColors.plugColor),
    ]),
    _CatalogSection(title: s.catalogSensors, categoryKey: 'sensors', items: [
      _DeviceItem(id: 'motion', icon: Symbols.sensors,      name: s.devMotionSensor,  category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'door',   icon: Symbols.sensor_door,  name: s.devDoorSensor,    category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'window', icon: Symbols.window,       name: s.devWindowSensor,  category: s.catSensor, color: AppColors.motionColor),
      _DeviceItem(id: 'smoke',  icon: Symbols.crisis_alert, name: s.devSmokeDetector, category: s.catSensor, color: AppColors.unsecured),
    ]),
    _CatalogSection(title: s.catalogCameras, categoryKey: 'cameras', items: [
      _DeviceItem(id: 'cam_in',  icon: Symbols.videocam,       name: s.devIndoorCam,  category: s.catCamera, color: AppColors.cameraColor),
      _DeviceItem(id: 'cam_out', icon: Symbols.camera_outdoor, name: s.devOutdoorCam, category: s.catCamera, color: AppColors.cameraColor),
      _DeviceItem(id: 'intercom', icon: Symbols.doorbell,      name: s.planIntercomLabel, category: s.catCamera, color: AppColors.cameraColor),
    ]),
    _CatalogSection(title: s.catalogAC, categoryKey: 'climate', items: [
      _DeviceItem(id: 'ac_wifi',   icon: Symbols.wifi,            name: s.acWifiName,   category: s.acWifiCategory,   color: AppColors.acColor),
      _DeviceItem(id: 'ac',        icon: Symbols.hvac,                     name: s.devSmartAC,   category: s.catClimate,       color: AppColors.acColor),
      _DeviceItem(id: 'ac_remote', icon: Symbols.settings_remote, name: s.acRemoteName, category: s.acRemoteCategory, color: AppColors.acColor),
    ]),
    _CatalogSection(title: s.devWaterHeater, categoryKey: 'boiler', items: [
      _DeviceItem(id: 'heater', icon: Symbols.water_drop,    name: s.devWaterHeater, category: s.catClimate, color: AppColors.acColor),
      _DeviceItem(id: 'thermo', icon: Symbols.thermostat,    name: s.devThermostat,  category: s.catClimate, color: AppColors.acColor),
    ]),
    _CatalogSection(title: s.catalogBlinds, categoryKey: 'blinds', items: [
      _DeviceItem(id: 'blind', icon: Symbols.blinds, name: s.devSmartBlind, category: s.catBlind, color: AppColors.primary),
      _DeviceItem(id: 'gate',  icon: Symbols.garage, name: s.devSmartGate,  category: s.catGate,  color: AppColors.primary),
    ]),
    _CatalogSection(title: s.catalogNetwork, categoryKey: 'network', items: [
      _DeviceItem(id: 'router_wifi', icon: Symbols.router,         name: s.devRouterWifi, category: s.catRouter,  color: _networkColor),
      _DeviceItem(id: 'gw_zigbee',   icon: Symbols.hub,            name: s.devGwZigbee,   category: s.catGateway, color: _networkColor),
      _DeviceItem(id: 'gw_wifi',     icon: Symbols.wifi_tethering, name: s.devGwWifi,     category: s.catGateway, color: _networkColor),
      _DeviceItem(id: 'gw_matter',   icon: Symbols.hub,            name: s.devGwMatter,   category: s.catGateway, color: _networkColor),
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
      case 'motion':     return DeviceType.motionSensor;
      case 'smoke':      return DeviceType.smokeSensor;
      case 'door':       return DeviceType.doorSensor;
      case 'window':     return DeviceType.windowSensor;
      case 'cam_in':
      case 'cam_out':    return DeviceType.camera;
      case 'intercom':   return DeviceType.intercom;
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

  // ── Barcode / QR scan → fill search to find the matching product ─────────────
  Future<void> _scanBarcode(String title) async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('נדרשת הרשאת מצלמה'),
          action: SnackBarAction(label: 'הגדרות', onPressed: openAppSettings),
        ),
      );
      return;
    }
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BarcodeScannerScreen(title: title),
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final resolved = _resolveBarcode(code);
    if (resolved != null) {
      _searchCtrl.text = resolved;
    } else {
      // Unknown barcode — clear search so all devices show, and notify user
      _searchCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('המכשיר לא זוהה — בחר סוג ידנית'),
          backgroundColor: const Color(0xFF8E8E93),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Barcode → search query resolver ─────────────────────────
  // Maps a raw scanned value (QR URL, EAN, model string) to a keyword
  // that matches one of the catalog entries. Returns null if unrecognised.
  static String? _resolveBarcode(String raw) {
    final v = raw.toLowerCase();
    // Lights
    if (v.contains('shelly') && (v.contains('bulb') || v.contains('duo') || v.contains('rgbw'))) return 'bulb';
    if (v.contains('wiz') || v.contains('lifx') || v.contains('hue') || v.contains('tradfri') || v.contains('bulb')) return 'bulb';
    if (v.contains('strip') || v.contains('led') || v.contains('rgb')) return 'strip';
    // Switches / plugs
    if (v.contains('shelly') && (v.contains('plug') || v.contains('em'))) return 'plug';
    if (v.contains('shelly'))   return 'switch';
    if (v.contains('sonoff') && v.contains('plug')) return 'plug';
    if (v.contains('sonoff'))   return 'switch';
    if (v.contains('tasmota'))  return 'switch';
    if (v.contains('tuya') || v.contains('smart life') || v.contains('smartlife')) return 'switch';
    if (v.contains('plug'))     return 'plug';
    if (v.contains('dimmer'))   return 'dimmer';
    // Sensors
    if (v.contains('motion') || v.contains('pir'))   return 'motion';
    if (v.contains('door')   || v.contains('contact')) return 'door';
    if (v.contains('window'))  return 'window';
    if (v.contains('smoke')  || v.contains('fire'))   return 'smoke';
    if (v.contains('leak')   || v.contains('water'))  return 'leak';
    // Cameras
    if (v.contains('reolink') || v.contains('hikvision') || v.contains('dahua') ||
        v.contains('tapo')    || v.contains('amcrest')   || v.contains('foscam') ||
        v.contains('camera')  || v.contains('onvif'))    return 'camera';
    if (v.contains('doorbell') || v.contains('intercom')) return 'intercom';
    // Climate
    if (v.contains('heater') || v.contains('boiler') || v.contains('solamax')) return 'heater';
    if (v.contains('thermo') || v.contains('thermostat')) return 'thermo';
    if (v.contains(' ac ') || v.contains('hvac') || v.contains('aircon') || v.contains('conditioner')) return 'ac';
    // Blinds
    if (v.contains('blind') || v.contains('shutter') || v.contains('curtain') || v.contains('roller')) return 'blind';
    if (v.contains('gate')  || v.contains('garage')) return 'gate';
    // Hubs / gateways
    if (v.contains('dirigera') || v.contains('conbee') || v.contains('matter') || v.contains('zigbee')) return 'gateway';
    return null;
  }

  // ── Show connect flow ────────────────────────────────────────
  void _showConnectFlow(_DeviceItem item) {
    // Matter commissioning has its own dedicated screen
    if (item.id == 'gw_matter') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MatterCommissionScreen()),
      );
      return;
    }

    // Sensors, plugs, and switches → brand/protocol picker
    if (item.id == 'motion' || item.id == 'door' || item.id == 'window' ||
        item.id == 'smoke' || item.id == 'plug' || item.id == 'switch1' ||
        item.id == 'dimmer') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SensorBrandPickerScreen(
            deviceId: item.id,
            deviceName: item.name,
            deviceIcon: item.icon,
            deviceColor: item.color,
            onConfirm: (name) {
              final state = context.read<AppState>();
              final device = Device(
                id: '${item.id}_${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
                name: name,
                type: _typeFor(item.id),
                status: DeviceStatus.online,
                isOn: true,
                attributes: const {},
              );
              state.addDevice(device);
              setState(() => _addedIds.add(item.id));
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
              Future.delayed(const Duration(milliseconds: 400), () {
                if (mounted) Navigator.maybePop(context);
              });
            },
          ),
        ),
      );
      return;
    }

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
            id: '${id}_${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
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
    final s = context.select((AppState st) => st.strings);
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
                          ? Symbols.router
                          : Symbols.hub,
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

            // ── Real WiZ bulb (works on LAN, no cloud) ────────
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WizSetupScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Symbols.lightbulb,
                            color: Color(0xFFFF6B00), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.addWizBulb,
                                  style: TextStyle(
                                      color: context.tText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(s.addWizBulbSub,
                                  style: TextStyle(
                                      color: context.tText2(0.6), fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Symbols.arrow_forward_ios,
                            color: Color(0xFFFF6B00), size: 14),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Barcode / QR — add a device by scanning its code ──
            if (_query.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  onTap: () => _scanBarcode(s.scanBarcode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.40)),
                    ),
                    child: Row(
                      children: [
                        Icon(Symbols.qr_code_scanner,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.scanBarcode,
                              style: TextStyle(
                                  color: context.tText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Icon(Symbols.arrow_forward_ios,
                            color: AppColors.primary, size: 14),
                      ],
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
                      icon: Symbols.grid_view,
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
                          Icon(Symbols.search_off,
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
      case 'lights':   return Symbols.lightbulb;
      case 'switches': return Symbols.toggle_on;
      case 'sensors':  return Symbols.sensors;
      case 'cameras':  return Symbols.videocam;
      case 'climate':  return Symbols.hvac;
      case 'boiler':   return Symbols.water_drop;
      case 'blinds':   return Symbols.blinds;
      case 'network':  return Symbols.router;
      default:         return Symbols.devices;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Connect flow sheet  — real scan, honest results
// ─────────────────────────────────────────────────────────────
enum _ConnectPhase { scanning, found, notFound, manualAdd, linking }

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
  late final AnimationController _foundCtrl;

  // Real network scanner
  final RealDiscoveryEngine _engine = RealDiscoveryEngine();
  List<DiscoveredDevice> _matchedDevices = [];
  int _selectedIdx = 0;

  // Manual-add form
  late final TextEditingController _nameCtrl;
  final TextEditingController _ipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _foundCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _nameCtrl = TextEditingController(text: widget.item.name);
    _engine.addListener(_onEngineUpdate);
    _startScan();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _foundCtrl.dispose();
    _engine
      ..removeListener(_onEngineUpdate)
      ..stopScan();
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  // ── Engine listener ──────────────────────────────────────────
  void _onEngineUpdate() {
    if (!mounted) return;
    _matchedDevices = _engine.found
        .where((d) => _typeMatches(d.type, widget.item.id))
        .toList();

    // Scan finished → decide phase
    if (!_engine.isScanning && _phase == _ConnectPhase.scanning) {
      if (_matchedDevices.isNotEmpty) {
        _foundCtrl
          ..reset()
          ..forward();
        setState(() => _phase = _ConnectPhase.found);
      } else {
        setState(() => _phase = _ConnectPhase.notFound);
      }
    } else {
      setState(() {});
    }
  }

  void _startScan() {
    _foundCtrl.reset();
    setState(() {
      _phase = _ConnectPhase.scanning;
      _matchedDevices = [];
      _selectedIdx = 0;
    });
    _engine.startScan();
  }

  // ── Actions ──────────────────────────────────────────────────
  void _onLink() {
    final name = _matchedDevices.isNotEmpty
        ? _matchedDevices[_selectedIdx].displayName
        : widget.item.name;
    setState(() => _phase = _ConnectPhase.linking);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      widget.onConfirm(widget.item.id, name);
      Navigator.pop(context);
    });
  }

  void _onManualAdd() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _phase = _ConnectPhase.linking);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onConfirm(widget.item.id, name);
      Navigator.pop(context);
    });
  }

  // ── Device type matching ──────────────────────────────────────
  static bool _typeMatches(DiscoveredDeviceType dt, String itemId) {
    switch (itemId) {
      case 'bulb':
      case 'strip':
        return dt == DiscoveredDeviceType.light;
      case 'switch1':
      case 'dimmer':
        return dt == DiscoveredDeviceType.smartSwitch ||
               dt == DiscoveredDeviceType.light;
      case 'plug':
        return dt == DiscoveredDeviceType.socket ||
               dt == DiscoveredDeviceType.smartSwitch;
      case 'motion':
        return dt == DiscoveredDeviceType.motionSensor ||
               dt == DiscoveredDeviceType.sensor;
      case 'smoke':
        return dt == DiscoveredDeviceType.smokeSensor ||
               dt == DiscoveredDeviceType.sensor;
      case 'door':
        return dt == DiscoveredDeviceType.doorSensor ||
               dt == DiscoveredDeviceType.windowSensor ||
               dt == DiscoveredDeviceType.sensor;
      case 'window':
        return dt == DiscoveredDeviceType.windowSensor ||
               dt == DiscoveredDeviceType.doorSensor ||
               dt == DiscoveredDeviceType.sensor;
      case 'cam_in':
      case 'cam_out':
        return dt == DiscoveredDeviceType.camera;
      case 'ac':
      case 'thermo':
        return dt == DiscoveredDeviceType.thermostat;
      case 'heater':
        return dt == DiscoveredDeviceType.boiler ||
               dt == DiscoveredDeviceType.thermostat;
      case 'blind':
      case 'gate':
        return dt == DiscoveredDeviceType.smartSwitch;
      case 'router_wifi':
        return dt == DiscoveredDeviceType.router;
      case 'gw_zigbee':
      case 'gw_wifi':
      case 'gw_matter':
        return dt == DiscoveredDeviceType.gateway;
      default:
        return false;
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    final c = widget.item.color;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24, right: 24, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.tText2(0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // ── Animated visual ────────────────────────────────
          SizedBox(
            width: 130, height: 130,
            child: switch (_phase) {
              _ConnectPhase.scanning  => _PulseRingsWidget(ctrl: _pulseCtrl, color: c, icon: widget.item.icon),
              _ConnectPhase.found     => ScaleTransition(
                  scale: CurvedAnimation(parent: _foundCtrl, curve: Curves.elasticOut),
                  child: _FoundBadgeWidget(color: AppColors.secured, icon: widget.item.icon),
                ),
              _ConnectPhase.notFound  => _NotFoundWidget(color: c, icon: widget.item.icon),
              _ConnectPhase.manualAdd => _ManualBadgeWidget(color: c, icon: widget.item.icon),
              _ConnectPhase.linking   => Center(
                  child: SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(color: AppColors.secured, strokeWidth: 3),
                  ),
                ),
            },
          ),
          const SizedBox(height: 22),

          // ── Status text ────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              switch (_phase) {
                _ConnectPhase.scanning  => s.searching,
                _ConnectPhase.found     => s.deviceFound,
                _ConnectPhase.notFound  => s.deviceNotFoundStatus,
                _ConnectPhase.manualAdd => s.manualAddStatus,
                _ConnectPhase.linking   => s.connecting,
              },
              key: ValueKey(_phase),
              style: TextStyle(
                color: switch (_phase) {
                  _ConnectPhase.found    => AppColors.secured,
                  _ConnectPhase.notFound => AppColors.unsecured,
                  _                      => context.tText,
                },
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(widget.item.name, style: TextStyle(color: context.tText2(0.50), fontSize: 14)),

          // ── Scanning: real progress ────────────────────────
          if (_phase == _ConnectPhase.scanning) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                // null = indeterminate until the engine reports progress
                value: _engine.progress > 0 ? _engine.progress : null,
                backgroundColor: context.tText2(0.08),
                color: c,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _engine.status.isNotEmpty ? _engine.status : widget.protocol,
              style: TextStyle(color: context.tText2(0.30), fontSize: 11, fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ],

          // ── Found: device selector + link ─────────────────
          if (_phase == _ConnectPhase.found) ...[
            const SizedBox(height: 12),
            if (_matchedDevices.length > 1)
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _matchedDevices.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d   = _matchedDevices[i];
                    final sel = _selectedIdx == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIdx = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.secured.withValues(alpha: 0.12)
                              : context.tText2(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.secured.withValues(alpha: 0.45)
                                : context.tText2(0.12),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(d.displayName,
                                style: TextStyle(color: context.tText, fontSize: 11, fontWeight: FontWeight.w700)),
                            if (d.ip != null)
                              Text(d.ip!,
                                  style: TextStyle(color: context.tText2(0.45), fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secured.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secured.withValues(alpha: 0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secured)),
                    const SizedBox(width: 10),
                    Flexible(child: Text(
                      '${_matchedDevices.first.displayName}'
                      '${_matchedDevices.first.ip != null ? ' · ${_matchedDevices.first.ip}' : ''}'
                      ' · ${widget.protocol}',
                      style: TextStyle(
                          color: AppColors.secured.withValues(alpha: 0.85),
                          fontSize: 11, fontFamily: 'monospace'),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            FtButton(
              label:       s.linkDevice,
              leadingIcon: Symbols.link,
              onTap:       _onLink,
              color:       AppColors.secured,
              expand:      true,
            ),
            const SizedBox(height: 12),
            FtButton(
              label:   s.cancel,
              variant: FtButtonVariant.ghost,
              onTap:   () => Navigator.pop(context),
            ),
          ],

          // ── Not found: clear message + actions ─────────────
          if (_phase == _ConnectPhase.notFound) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.unsecured.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.unsecured.withValues(alpha: 0.22)),
              ),
              child: Text(
                s.deviceNotFoundHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.unsecured.withValues(alpha: 0.85), fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: FtButton(
                  label:       s.rescan,
                  leadingIcon: Symbols.refresh,
                  variant:     FtButtonVariant.secondary,
                  onTap:       _startScan,
                  expand:      true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FtButton(
                  label:       s.manualAddLabel,
                  leadingIcon: Symbols.edit,
                  onTap:       () => setState(() => _phase = _ConnectPhase.manualAdd),
                  color:       c,
                  expand:      true,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            FtButton(
              label:   s.cancel,
              variant: FtButtonVariant.ghost,
              onTap:   () => Navigator.pop(context),
            ),
          ],

          // ── Manual add form ───────────────────────────────
          if (_phase == _ConnectPhase.manualAdd) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: context.tText),
              decoration: InputDecoration(
                labelText: s.deviceNameLabel,
                labelStyle: TextStyle(color: context.tText2(0.55)),
                prefixIcon: Icon(widget.item.icon, color: c, size: 20),
                filled: true, fillColor: context.tCardAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.tBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.tBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c, width: 1.5)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ipCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.tText),
              decoration: InputDecoration(
                labelText: s.ipAddressOptional,
                labelStyle: TextStyle(color: context.tText2(0.55)),
                prefixIcon: Icon(Symbols.lan, color: context.tText2(0.45), size: 20),
                filled: true, fillColor: context.tCardAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.tBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.tBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c, width: 1.5)),
              ),
            ),
            const SizedBox(height: 18),
            FtButton(
              label:       s.addDeviceBtn,
              leadingIcon: Symbols.add,
              onTap:       _onManualAdd,
              color:       c,
              expand:      true,
            ),
            const SizedBox(height: 10),
            FtButton(
              label:   s.back,
              variant: FtButtonVariant.ghost,
              onTap:   () => setState(() => _phase = _ConnectPhase.notFound),
            ),
          ],

          if (_phase == _ConnectPhase.linking) const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Not-found badge
// ─────────────────────────────────────────────────────────────
class _NotFoundWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _NotFoundWidget({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 104, height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.unsecured.withValues(alpha: 0.10),
            border: Border.all(color: AppColors.unsecured.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(icon, color: AppColors.unsecured.withValues(alpha: 0.55), size: 44),
        ),
        Positioned(
          bottom: 6, right: 6,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.unsecured,
              border: Border.all(color: context.tCard, width: 2.5),
            ),
            child: const Icon(Symbols.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Manual-add badge
// ─────────────────────────────────────────────────────────────
class _ManualBadgeWidget extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _ManualBadgeWidget({required this.color, required this.icon});

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
              border: Border.all(color: context.tCard, width: 2.5),
            ),
            child: const Icon(Symbols.edit, color: Colors.white, size: 16),
          ),
        ),
      ],
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
            child: Icon(Symbols.check,
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
                      added ? Symbols.check : Symbols.add,
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
        margin: const EdgeInsetsDirectional.only(end: 8),
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
    final s = context.select((AppState st) => st.strings);
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
                    s.scanNetworkTitle,
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
              padding: const EdgeInsetsDirectional.only(end: 14),
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
                  Symbols.arrow_forward_ios,
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
              child: Icon(Symbols.chevron_right,
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
        textDirection: context.select((AppState st) => st.isRtl)
            ? TextDirection.rtl : TextDirection.ltr,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              color: context.tText2(0.30), fontSize: 13),
          prefixIcon: Icon(Symbols.search,
              color: context.tText2(0.35), size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(Symbols.close,
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

// ─────────────────────────────────────────────────────────────
// Full-screen barcode scanner screen
// ─────────────────────────────────────────────────────────────
class _BarcodeScannerScreen extends StatefulWidget {
  final String title;
  const _BarcodeScannerScreen({required this.title});

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late MobileScannerController _ctrl;
  bool _detected = false;
  bool _permDenied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = _newController();
    WidgetsBinding.instance.addObserver(this);
    // Only block early for permanently denied — if merely "not yet asked",
    // let MobileScanner trigger the system dialog naturally.
    _checkPermissionInitial();
  }

  /// Called once on open: only sets _permDenied for permanently denied.
  Future<void> _checkPermissionInitial() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    if (status.isPermanentlyDenied) {
      setState(() => _permDenied = true);
    }
  }

  /// Called on resume: re-evaluates full permission state.
  Future<void> _recheckPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      if (_permDenied) {
        // Permission was just granted in Settings — restart scanner.
        _ctrl.dispose();
        setState(() {
          _permDenied = false;
          _detected = false;
          _ctrl = _newController();
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() => _permDenied = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheckPermission();
  }

  MobileScannerController _newController() => MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  Future<void> _retry() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _permDenied = true);
      return;
    }
    _ctrl.dispose();
    setState(() {
      _detected = false;
      _permDenied = false;
      _ctrl = _newController();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildTopBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Symbols.close, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Text(widget.title,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      );

  Widget _buildPermDenied() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.camera_alt, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text('נדרשת הרשאת מצלמה',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('פתח הגדרות → אפליקציות → FantaTech → הרשאות',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              FtButton(
                label:       'פתח הגדרות',
                leadingIcon: Symbols.settings,
                onTap:       openAppSettings,
                expand:      true,
              ),
              const SizedBox(height: 8),
              FtButton(
                label:   'סגור',
                variant: FtButtonVariant.ghost,
                onTap:   () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Show permission UI immediately if we already know it's denied —
    // avoids a flash of the scanner before the errorBuilder fires.
    if (_permDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildPermDenied(),
            _buildTopBar(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed ────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            errorBuilder: (context, error, child) {
              // Treat both explicit permissionDenied and genericError as
              // permission issues — on some Android versions mobile_scanner
              // returns genericError when the CAMERA permission is missing.
              final isPermission =
                  error.errorCode == MobileScannerErrorCode.permissionDenied ||
                  error.errorCode == MobileScannerErrorCode.genericError;

              return ColoredBox(
                color: Colors.black,
                child: isPermission
                    ? _buildPermDenied()
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Symbols.error,
                                color: Colors.white54, size: 56),
                            const SizedBox(height: 16),
                            Text(
                              'שגיאת מצלמה: ${error.errorCode.name}',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            FtButton(
                              label:       'נסה שנית',
                              leadingIcon: Symbols.refresh,
                              onTap:       _retry,
                              expand:      true,
                            ),
                            const SizedBox(height: 8),
                            FtButton(
                              label:   'סגור',
                              variant: FtButtonVariant.ghost,
                              onTap:   () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
              );
            },
            onDetect: (capture) {
              if (_detected) return;
              final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
              if (raw.isNotEmpty) {
                _detected = true;
                Navigator.pop(context, raw);
              }
            },
          ),

          // ── Viewfinder overlay ─────────────────────────────────
          CustomPaint(
            painter: _ViewfinderPainter(),
            child: const SizedBox.expand(),
          ),

          // ── Top bar ────────────────────────────────────────────
          _buildTopBar(),

          // ── Hint text at bottom ────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'כוון את המצלמה לברקוד / QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Draws corner brackets around the scan area
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const boxSize = 240.0;
    const cornerLen = 28.0;
    const r = 6.0;

    final left   = cx - boxSize / 2;
    final top    = cy - boxSize / 2;
    final right  = cx + boxSize / 2;
    final bottom = cy + boxSize / 2;

    // Dim overlay
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), dimPaint);
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), dimPaint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, boxSize), dimPaint);
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, boxSize), dimPaint);

    // Corner brackets
    final p = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(left + r, top), Offset(left + cornerLen, top), p);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + cornerLen), p);
    canvas.drawArc(Rect.fromLTWH(left, top, r * 2, r * 2), 3.14, 1.57, false, p);
    // Top-right
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right - r, top), p);
    canvas.drawLine(Offset(right, top + r), Offset(right, top + cornerLen), p);
    canvas.drawArc(Rect.fromLTWH(right - r * 2, top, r * 2, r * 2), 4.71, 1.57, false, p);
    // Bottom-left
    canvas.drawLine(Offset(left + r, bottom), Offset(left + cornerLen, bottom), p);
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom - r), p);
    canvas.drawArc(Rect.fromLTWH(left, bottom - r * 2, r * 2, r * 2), 1.57, 1.57, false, p);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right - r, bottom), p);
    canvas.drawLine(Offset(right, bottom - cornerLen), Offset(right, bottom - r), p);
    canvas.drawArc(Rect.fromLTWH(right - r * 2, bottom - r * 2, r * 2, r * 2), 0, 1.57, false, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
