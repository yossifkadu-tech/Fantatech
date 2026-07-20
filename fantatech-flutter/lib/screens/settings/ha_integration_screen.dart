import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaIntegrationScreen
//
// Dedicated Home Assistant integration settings.
// The user enters a server URL (local or remote) + Long-Lived Access Token,
// taps "Connect", and the app auto-imports rooms, lights, switches and sensors.
// A live WebSocket indicator shows real-time connection state.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/gateways/clients/ha_gateway_client.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/ha/ha_config.dart';
import '../../services/ha/ha_provider.dart';
import '../../services/storage/secure_cred_service.dart';
import '../../theme/app_theme.dart';
import '../ha/ha_shell.dart';

class HaIntegrationScreen extends StatefulWidget {
  const HaIntegrationScreen({super.key});

  @override
  State<HaIntegrationScreen> createState() => _HaIntegrationScreenState();
}

class _HaIntegrationScreenState extends State<HaIntegrationScreen> {
  final _urlCtrl   = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  bool _loading      = false;
  bool _connected    = false;
  bool _tokenVisible = false;
  String? _error;
  _ImportStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final url   = await SecureCredService.readHaIp()    ?? '';
    final token = await SecureCredService.readHaToken() ?? '';
    if (!mounted) return;
    setState(() {
      _urlCtrl.text   = url;
      _tokenCtrl.text = token;
    });
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; _stats = null; });

    final ip    = _normalizeUrl(_urlCtrl.text.trim());
    final token = _tokenCtrl.text.trim();

    // 1. Ping
    final ok = await HaGatewayClient.ping(ip, token);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error   = 'Cannot reach Home Assistant at $ip.\n'
                   'Check the URL and that your token is valid.';
      });
      return;
    }

    // 2. Fetch all states
    final states = await HaGatewayClient.fetchAllStates(ip, token);
    if (!mounted) return;

    // 3. Fetch areas (best-effort)
    final areas = await HaGatewayClient.fetchAreas(ip, token);
    if (!mounted) return;

    // 4. Save credentials (encrypted) — store as full URL so startup restore works
    await SecureCredService.saveHaCredentials('http://$ip:8123', token);
    if (!mounted) return;

    // 5. Import into AppState
    final appState = context.read<AppState>();
    final stats    = _importIntoApp(appState, states, areas, ip);

    // 6. Register in GatewayManager so DeviceCommander can route commands
    //    and so the live service reconnects automatically on app restart.
    final totalDevices = stats.lights + stats.switches + stats.sensors + stats.others;
    context.read<GatewayManager>().upsertHaConnection(
      ip:          ip,
      token:       token,
      deviceCount: totalDevices,
    );

    // 7. Start real-time WebSocket listener via the canonical HaProvider
    final fullUrl = 'http://$ip:8123';
    unawaited(context.read<HaProvider>().connect(HaConfig(baseUrl: fullUrl, token: token)));

    setState(() {
      _loading   = false;
      _connected = true;
      _stats     = stats;
    });
  }

  _ImportStats _importIntoApp(
    AppState state,
    List<Map<String, dynamic>> states,
    List<Map<String, dynamic>> areas,
    String ip,
  ) {
    // Create room groups from HA areas
    for (final area in areas) {
      final id   = (area['area_id'] as String?)   ?? '';
      final name = (area['name']    as String?)   ?? '';
      final icon = _iconForAreaName(name);
      if (id.isNotEmpty && name.isNotEmpty) {
        state.addRoomGroup(id, name, icon);
        // Add a room for the area if one doesn't already exist
        final exists = state.rooms.any((r) => r['name'] == name);
        if (!exists) state.addRoom(name, icon, parentGroupId: id);
      }
    }

    int lights = 0, switches = 0, sensors = 0, others = 0;

    for (final entity in states) {
      final entityId = (entity['entity_id'] as String?) ?? '';
      final attrs    = (entity['attributes'] as Map<String, dynamic>?) ?? {};
      final stateStr = (entity['state'] as String?) ?? 'off';

      final domain   = entityId.split('.').first;
      final friendly = (attrs['friendly_name'] as String?) ?? entityId;

      // Area mapping
      final areaId = (attrs['area_id']  as String?) ??
                     (entity['area_id'] as String?);

      DeviceType? type;
      switch (domain) {
        case 'light':  type = DeviceType.light;       lights++;   break;
        case 'switch': type = DeviceType.smartSwitch; switches++; break;
        case 'input_boolean':
                       type = DeviceType.smartSwitch; switches++; break;
        case 'binary_sensor':
          type = _sensorType(entityId, attrs);
          sensors++;
          break;
        case 'sensor':
          type = _sensorType(entityId, attrs, fallback: DeviceType.energyMeter);
          sensors++;
          break;
        case 'cover':  type = DeviceType.blind;       others++;   break;
        case 'lock':   type = DeviceType.smartLock;   others++;   break;
        case 'climate':type = DeviceType.airConditioner; others++; break;
        default:       others++; break;
      }

      if (type == null) continue;

      // Skip if already imported
      if (state.devices.any((d) => d.attributes['entityId'] == entityId)) {
        continue;
      }

      // Find room name from area
      String roomName = '';
      if (areaId != null) {
        final area = state.roomGroups.where((g) => g['id'] == areaId).firstOrNull;
        roomName = (area?['name'] as String?) ?? '';
      }

      final isOn = _stateIsOn(stateStr);
      final brightness = attrs['brightness'];

      state.upsertDevice(Device(
        id:         'ha_${entityId.replaceAll('.', '_')}',
        name:       friendly,
        type:       type,
        isOn:       isOn,
        room:       roomName,
        attributes: {
          'entityId':    entityId,
          'deviceClass': (attrs['device_class'] as String?) ?? '',
          'domain':      domain,
          'haIp':        ip,
          if (brightness != null)
            'brightness': ((brightness as num) / 2.55).round(),
          if (attrs['temperature'] != null)
            'temperature': attrs['temperature'],
          // State fields read by the security screen
          if (type == DeviceType.waterLeakSensor) 'water_leak': isOn,
          if (type == DeviceType.smokeSensor)      'smoke':      isOn,
          if (type == DeviceType.motionSensor)     'detected':   isOn,
          if (type == DeviceType.doorSensor)       'open':       isOn,
          if (type == DeviceType.windowSensor)     'open':       isOn,
        },
      ));
    }

    return _ImportStats(
      lights:   lights,
      switches: switches,
      sensors:  sensors,
      others:   others,
      areas:    areas.length,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _normalizeUrl(String raw) {
    var url = raw.replaceAll(RegExp(r'^https?://'), '');
    url = url.split('/').first; // strip path
    url = url.split(':').first; // strip port (we use fixed 8123)
    return url;
  }

  static bool _stateIsOn(String state) =>
      const {'on','open','unlocked','heat','cool','auto'}.contains(state.toLowerCase());

  static DeviceType _sensorType(
    String entityId,
    Map attrs, {
    DeviceType fallback = DeviceType.motionSensor,
  }) {
    final dc = (attrs['device_class'] as String?) ?? '';
    final id = entityId.toLowerCase();
    if (dc == 'motion'   || dc == 'occupancy' || id.contains('motion') || id.contains('occupancy')) return DeviceType.motionSensor;
    if (dc == 'door'     || id.contains('door'))                                                     return DeviceType.doorSensor;
    if (dc == 'window'   || dc == 'opening'   || id.contains('window'))                             return DeviceType.windowSensor;
    if (dc == 'smoke'    || id.contains('smoke'))                                                    return DeviceType.smokeSensor;
    if (dc == 'moisture' || dc == 'water'     || id.contains('water') || id.contains('leak') || id.contains('moisture')) return DeviceType.waterLeakSensor;
    if (dc == 'gas'      || id.contains('gas') || id.contains('co2') || id.contains('co_'))         return DeviceType.gasSensor;
    if (dc == 'vibration' || id.contains('vibration') || id.contains('glass'))                      return DeviceType.glassBreakSensor;
    if (dc == 'energy'   || dc == 'power'     || id.contains('energy') || id.contains('power'))     return DeviceType.energyMeter;
    return fallback;
  }

  static int _iconForAreaName(String name) {
    final k = name.toLowerCase();
    if (k.contains('bed')  || k.contains('sleep')) return 0xe239;  // bed
    if (k.contains('bath') || k.contains('wc'))    return 0xe63d;  // wc
    if (k.contains('kit')  || k.contains('cook'))  return 0xf04c3; // kitchen
    if (k.contains('liv')  || k.contains('salon')) return 0xe318;  // weekend
    if (k.contains('garden')|| k.contains('yard')) return 0xf08d8; // yard
    if (k.contains('garage'))                       return 0xe1b3;  // garage
    if (k.contains('office')|| k.contains('study')) return 0xef53;  // desk
    return 0xe88a; // home
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
                const SizedBox(height: 14),
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.arrow_back_ios_new,
                          color: context.tText2(0.54), size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Home Assistant',
                            style: TextStyle(
                                color:      context.tText,
                                fontSize:   20,
                                fontWeight: FontWeight.bold)),
                        Text('Connect & import devices',
                            style: TextStyle(
                                color:   context.tText2(0.4),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  // Live indicator — reflects the real WebSocket state
                  _LiveDot(connected: _connected),
                ]),

                const SizedBox(height: 28),

                // ── HA logo / hero ───────────────────────────────────────
                _HaBanner(),

                const SizedBox(height: 28),

                // ── Server URL ───────────────────────────────────────────
                _SectionLabel('Server'),
                const SizedBox(height: 8),
                _Field(
                  controller: _urlCtrl,
                  label:       'Server URL or IP',
                  hint:        '192.168.1.82  or  homeassistant.local',
                  icon:        Symbols.dns,
                  keyboard:    TextInputType.url,
                  validator:   (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Symbols.info, size: 13,
                      color: const Color(0xFF18BCEC).withValues(alpha: 0.7)),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Tip: use the IP address for Raspberry Pi — more reliable than homeassistant.local on Android.',
                      style: TextStyle(color: Color(0xFF18BCEC), fontSize: 11),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Token ────────────────────────────────────────────────
                _SectionLabel('Long-Lived Access Token'),
                const SizedBox(height: 8),
                TextFormField(
                  controller:  _tokenCtrl,
                  obscureText: !_tokenVisible,
                  style: TextStyle(color: context.tText, fontSize: 13),
                  maxLines: _tokenVisible ? 3 : 1,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText:      'eyJ0eXAiOiJKV1Qi…',
                    labelText:     'Access Token',
                    labelStyle:    TextStyle(color: context.tText2(0.45), fontSize: 12),
                    hintStyle:     TextStyle(color: context.tText2(0.25), fontSize: 12),
                    prefixIcon:    Icon(Symbols.key,
                                       color: context.tText2(0.38), size: 18),
                    suffixIcon:    IconButton(
                      icon: Icon(
                        _tokenVisible ? Symbols.visibility_off : Symbols.visibility,
                        color: context.tText2(0.38), size: 18),
                      onPressed: () =>
                          setState(() => _tokenVisible = !_tokenVisible),
                    ),
                    filled:        true,
                    fillColor:     context.tText2(0.06),
                    border:        _border(context),
                    enabledBorder: _border(context),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:   const BorderSide(
                          color: AppColors.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),

                // Token hint
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showTokenHelp(context),
                  child: Text(
                    'Where do I get a token? ›',
                    style: TextStyle(
                        color:    AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Error ────────────────────────────────────────────────
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppColors.statusAlarm.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(
                          color: AppColors.statusAlarm.withValues(alpha: 0.30)),
                    ),
                    child: Row(children: [
                      const Icon(Symbols.error,
                          color: AppColors.statusAlarm, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.statusAlarm, fontSize: 12)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Success stats ────────────────────────────────────────
                if (_stats != null) ...[
                  _StatsCard(stats: _stats!),
                  const SizedBox(height: 12),
                  // Open HA Dashboard button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Symbols.dashboard,
                          color: AppColors.primary, size: 18),
                      label: const Text('פתח דשבורד HA',
                          style: TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final url   = _urlCtrl.text.trim();
                        final token = _tokenCtrl.text.trim();
                        // Connect HaProvider with full URL
                        final fullUrl = url.startsWith('http')
                            ? url
                            : 'http://$url:8123';
                        final cfg = HaConfig(baseUrl: fullUrl, token: token);
                        context.read<HaProvider>().connect(cfg);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HaShell(initialConfig: cfg)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Connect button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width:  22, height: 22,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.black))
                        : Text(
                            _connected ? s.haReconnectSync : s.connect,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize:   16)),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Supported entities note ──────────────────────────────
                _InfoNote(
                  icon: Symbols.info,
                  text: 'Imports: lights, switches, binary sensors '
                        '(motion / door / window / smoke / leak), '
                        'covers, locks, climate.\n'
                        'Real-time updates via WebSocket.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(BuildContext ctx) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide:   BorderSide(color: ctx.tText2(0.12)),
  );

  void _showTokenHelp(BuildContext context) {
    showModalBottomSheet(
      context:      context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: context.tText2(0.20),
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('How to get a token',
                style: TextStyle(
                    color:      context.tText,
                    fontSize:   17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              '1. Open Home Assistant in your browser.',
              '2. Click your profile icon (bottom-left).',
              '3. Scroll down to "Long-Lived Access Tokens".',
              '4. Tap "Create Token", give it a name (e.g. FantaTech).',
              '5. Copy the token and paste it here.',
            ].map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22, height: 22,
                    margin: const EdgeInsetsDirectional.only(end: 10, top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(step[0],
                          style: TextStyle(
                              color:      AppColors.primary,
                              fontSize:   11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: Text(step.substring(3),
                        style: TextStyle(
                            color:   context.tText2(0.8),
                            fontSize: 13,
                            height:  1.4)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final bool connected;
  const _LiveDot({required this.connected});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.connected) {
      return Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: context.tText2(0.20), shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10, height: 10,
        decoration: const BoxDecoration(
          color: AppColors.secured, shape: BoxShape.circle),
      ),
    );
  }
}

class _HaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF18BCEC).withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF18BCEC).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color:  const Color(0xFF18BCEC).withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Symbols.home,
              color: Color(0xFF18BCEC), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Home Assistant',
                  style: TextStyle(
                      color:      context.tText,
                      fontSize:   16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Connect your local or remote HA instance.\n'
                'Rooms, lights, switches and sensors are imported automatically.',
                style: TextStyle(
                    color:   context.tText2(0.55),
                    fontSize: 11,
                    height:  1.4),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
        color:          context.tText2(0.40),
        fontSize:       10,
        fontWeight:     FontWeight.w700,
        letterSpacing:  0.8),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboard,
      style:        TextStyle(color: context.tText, fontSize: 13),
      validator:    validator,
      decoration: InputDecoration(
        labelText:     label,
        hintText:      hint,
        labelStyle:    TextStyle(color: context.tText2(0.45), fontSize: 12),
        hintStyle:     TextStyle(color: context.tText2(0.25), fontSize: 12),
        prefixIcon:    Icon(icon, color: context.tText2(0.38), size: 18),
        filled:        true,
        fillColor:     context.tText2(0.06),
        border:        OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide(color: context.tText2(0.12))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide(color: context.tText2(0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(
                color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide(
                color: AppColors.statusAlarm.withValues(alpha: 0.60))),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final _ImportStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.secured.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: AppColors.secured.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Symbols.check_circle,
                color: AppColors.secured, size: 18),
            const SizedBox(width: 8),
            Text('Connected — devices imported',
                style: TextStyle(
                    color:      AppColors.secured,
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              if (stats.areas    > 0) _Chip('${stats.areas} rooms',    Symbols.room),
              if (stats.lights   > 0) _Chip('${stats.lights} lights',   Symbols.lightbulb),
              if (stats.switches > 0) _Chip('${stats.switches} switches', Symbols.toggle_on),
              if (stats.sensors  > 0) _Chip('${stats.sensors} sensors',  Symbols.sensors),
              if (stats.others   > 0) _Chip('${stats.others} other',     Symbols.devices_other),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String  label;
  final IconData icon;
  const _Chip(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        AppColors.secured.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.secured, size: 13),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              color:      AppColors.secured,
              fontSize:   11,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        context.tText2(0.04),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: context.tText2(0.08)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.tText2(0.35), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color:   context.tText2(0.50),
                  fontSize: 11,
                  height:  1.5)),
        ),
      ],
    ),
  );
}

// ── Data class ────────────────────────────────────────────────────────────────
class _ImportStats {
  final int lights, switches, sensors, others, areas;
  const _ImportStats({
    required this.lights,
    required this.switches,
    required this.sensors,
    required this.others,
    required this.areas,
  });
}
