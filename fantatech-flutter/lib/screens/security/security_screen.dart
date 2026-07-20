import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../models/layout_item.dart';
import '../../theme/app_theme.dart';
import '../../l10n/strings.dart';
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import '../../providers/layout_provider.dart';
import '../../widgets/edit_mode/reorderable_dashboard.dart';
import '../../widgets/ft_button.dart';
import '../cyber/cyber_screen.dart';
import '../smarthome/sensor_brand_picker_screen.dart';
import 'smart_lock_hub_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shieldCtrl;
  late Animation<double> _shieldScale;
  late Animation<double> _shieldGlow;

  @override
  void initState() {
    super.initState();
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shieldScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );
    _shieldGlow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shieldCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;

    final doorSensor = state.devices
        .where((d) => d.type == DeviceType.doorSensor)
        .firstOrNull;
    final windowSensor = state.devices
        .where((d) => d.type == DeviceType.windowSensor)
        .firstOrNull;
    final motionSensors = state.devices
        .where((d) => d.type == DeviceType.motionSensor)
        .toList();
    final smokeSensors = state.devices
        .where((d) => d.type == DeviceType.smokeSensor)
        .toList();
    final waterSensors = state.devices
        .where((d) => d.type == DeviceType.waterLeakSensor)
        .toList();
    final locks = state.devices
        .where((d) => d.type == DeviceType.smartLock)
        .toList();

    final allOk = state.isSecured &&
        (doorSensor?.attributes['open'] != true) &&
        (windowSensor?.attributes['open'] != true) &&
        motionSensors.every((m) => m.attributes['detected'] != true) &&
        smokeSensors.every((m) => m.attributes['smoke'] != true) &&
        waterSensors.every((m) => m.attributes['water_leak'] != true);

    // ── Section widgets ────────────────────────────────────────────
    final zonesSection = Column(
      children: [
        _SensorRow(
          icon: Symbols.lock,
          label: s.doorSensor,
          status: _sensorStatusLabel(doorSensor, s),
          color: _sensorColor(doorSensor),
          statusIcon: _sensorIcon(doorSensor, true),
          onTap: () => _showSensorDetail(context, s, s.doorSensor,
              _sensorStatusLabel(doorSensor, s),
              _sensorColor(doorSensor), Symbols.lock,
              doorSensor, 'door'),
        ),
        const SizedBox(height: 10),
        _SensorRow(
          icon: Symbols.window,
          label: s.windowsSensor,
          status: _sensorStatusLabel(windowSensor, s),
          color: _sensorColor(windowSensor),
          statusIcon: _sensorIcon(windowSensor, true),
          onTap: () => _showSensorDetail(context, s, s.windowsSensor,
              _sensorStatusLabel(windowSensor, s),
              _sensorColor(windowSensor), Symbols.window,
              windowSensor, 'window'),
        ),
      ],
    );

    final sensorsSection = Column(
      children: [
        _SensorRow(
          icon: Symbols.sensors,
          label: s.motionSensors,
          status: motionSensors.isEmpty
              ? s.offlineLabel
              : motionSensors.any(
                      (m) => m.attributes['detected'] == true)
                  ? s.activeStatus
                  : s.normalStatus,
          color: motionSensors.any(
                  (m) => m.attributes['detected'] == true)
              ? AppColors.unsecured
              : AppColors.secured,
          statusIcon: Symbols.sensors,
          onTap: () => _showSensorDetail(
              context,
              s,
              s.motionSensors,
              motionSensors.isEmpty ? s.offlineLabel : s.normalStatus,
              motionSensors.any(
                      (m) => m.attributes['detected'] == true)
                  ? AppColors.unsecured
                  : AppColors.secured,
              Symbols.sensors,
              motionSensors.isEmpty ? null : motionSensors.first,
              'motion'),
        ),
        const SizedBox(height: 10),
        _SensorRow(
          icon: Symbols.smoke_free,
          label: s.smokeDetector,
          status: smokeSensors.isEmpty
              ? s.offlineLabel
              : smokeSensors.any((m) => m.attributes['smoke'] == true)
                  ? s.activeStatus
                  : s.normalStatus,
          color: smokeSensors.any((m) => m.attributes['smoke'] == true)
              ? AppColors.unsecured
              : AppColors.secured,
          statusIcon: smokeSensors.any((m) => m.attributes['smoke'] == true)
              ? Symbols.warning_amber
              : Symbols.verified,
          onTap: () => _showSensorDetail(
              context, s, s.smokeDetector,
              smokeSensors.isEmpty ? s.offlineLabel : s.normalStatus,
              AppColors.secured, Symbols.smoke_free,
              smokeSensors.isEmpty ? null : smokeSensors.first,
              'smoke'),
        ),
        const SizedBox(height: 10),
        _SensorRow(
          icon: Symbols.water_damage,
          label: s.waterLeakSensor,
          status: waterSensors.isEmpty
              ? s.offlineLabel
              : waterSensors.any((m) => m.attributes['water_leak'] == true)
                  ? s.activeStatus
                  : s.normalStatus,
          color: waterSensors.any((m) => m.attributes['water_leak'] == true)
              ? AppColors.unsecured
              : AppColors.secured,
          statusIcon: waterSensors.any((m) => m.attributes['water_leak'] == true)
              ? Symbols.warning_amber
              : Symbols.verified,
          onTap: () => _showSensorDetail(
              context, s, s.waterLeakSensor,
              waterSensors.isEmpty ? s.offlineLabel : s.normalStatus,
              AppColors.secured, Symbols.water_damage,
              waterSensors.isEmpty ? null : waterSensors.first),
        ),
      ],
    );

    final locksSection = _SmartLocksCard(s: s, locks: locks);

    final eventLogSection = GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CyberScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.cyberColor.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.cyberColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Symbols.gpp_good,
                  color: Color(0xFF00E5FF), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.cyberTitle,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(s.cyberNetProtected,
                      style: TextStyle(
                          color: context.tText2(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Symbols.chevron_left,
                color: context.tText2(0.35), size: 22),
          ],
        ),
      ),
    );

    // ── Pinned header: TopBar + AnimatedShield + GuestModeBar ─────────
    final pinnedHeader = Column(
      children: [
        _TopBar(title: s.securityTitle),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: _AnimatedShield(
            isSecured: allOk,
            scaleAnim: _shieldScale,
            glowAnim: _shieldGlow,
            onToggle: state.toggleSecurity,
            onLongPress: () => _showSecurityOptions(context, state, s),
            securedText: s.homeSecured,
            notSecuredText: s.homeNotSecured,
            activeText: s.allSystemsActive,
            tapText: s.tapToActivate,
          ),
        ),
        if (state.isGuestMode)
          _GuestModeBar(
            secondsLeft: state.guestSecondsLeft,
            activeLabel: s.welcomeGuestActive,
            timerTemplate: s.welcomeGuestTimer,
            cancelLabel: s.welcomeGuestCancel,
            onCancel: state.cancelGuestMode,
          ),
      ],
    );

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableDashboard(
                dashboardId: DashboardId.security,
                defaultItems: DashboardDefaults.security,
                nameResolver: DashboardDefaults.nameOf,
                iconResolver: DashboardDefaults.iconOf,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                header: pinnedHeader,
                itemBuilder: (ctx, item) => switch (item.type) {
                  'zones'     => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: zonesSection,
                    ),
                  'sensors'   => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: sensorsSection,
                    ),
                  'locks'     => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: locksSection,
                    ),
                  'event_log' => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: eventLogSection,
                    ),
                  'arm_status' => const SizedBox.shrink(), // pinned to header
                  _           => const SizedBox.shrink(),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _WelcomeGuestButton(
                      label: s.welcomeGuestBtn,
                      hint: s.welcomeGuestHint,
                      isActive: state.isGuestMode,
                      onTap: () {
                        if (state.isGuestMode) {
                          state.cancelGuestMode();
                        } else {
                          _showGuestOptions(context, state, s);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PanicButton(
                      onLongPress: () => _showPanicConfirm(context, state, s),
                      panicLabel: s.panicLabel,
                      warningLabel: s.panicWarning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sensor types with a real brand/pairing catalog in SensorBrandPickerScreen
  // (see add_device_screen.dart's catalog — 'motion'/'door'/'window'/'smoke').
  // Water-leak isn't in that catalog yet, so it gets no add button here.
  static const _addableDeviceTypes = {
    'motion': DeviceType.motionSensor,
    'door': DeviceType.doorSensor,
    'window': DeviceType.windowSensor,
    'smoke': DeviceType.smokeSensor,
  };

  void _showSensorDetail(BuildContext context, S s, String label,
      String status, Color color, IconData icon, Device? device,
      [String? addDeviceId]) {
    HapticFeedback.lightImpact();
    final battery = device?.attributes['battery'];
    final online = device != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: context.tText2(0.24),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 22),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 16),
            Text(label,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(status,
                style: TextStyle(color: color, fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 22),
            _detailRow(Symbols.wifi, s.normalStatus,
                online ? s.activeStatus : s.offlineLabel,
                online ? AppColors.secured : context.tText2(0.38)),
            if (battery != null) ...[
              const SizedBox(height: 10),
              _detailRow(Symbols.battery_full, '🔋', '$battery%',
                  AppColors.secured),
            ],
            if (!online && addDeviceId != null) ...[
              const SizedBox(height: 22),
              FtButton(
                label: s.scanNetworkTitle,
                leadingIcon: Symbols.sensors,
                color: color,
                expand: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SensorBrandPickerScreen(
                        deviceId: addDeviceId,
                        deviceName: label,
                        deviceIcon: icon,
                        deviceColor: color,
                        onConfirm: (name) {
                          final type = _addableDeviceTypes[addDeviceId];
                          if (type == null) return;
                          context.read<AppState>().upsertDevice(Device(
                                id: '${addDeviceId}_${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
                                name: name,
                                type: type,
                                status: DeviceStatus.online,
                                isOn: true,
                                attributes: const {},
                              ));
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(color: context.tText, fontSize: 13)),
          ),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _sensorStatusLabel(Device? d, S s) {
    final status = _sensorStatus(d);
    switch (status) {
      case _SensorStatus.secured:
        return s.securedStatus;
      case _SensorStatus.open:
        return s.openStatus;
      case _SensorStatus.notConnected:
        return s.offlineLabel;
    }
  }

  _SensorStatus _sensorStatus(Device? d) {
    // No physical sensor paired yet → treat the zone as secured (the home
    // defaults to "always secure"), rather than showing it as disconnected.
    if (d == null) return _SensorStatus.secured;
    if (d.status == DeviceStatus.offline) return _SensorStatus.secured;
    final open = d.attributes['open'] as bool? ?? false;
    return open ? _SensorStatus.open : _SensorStatus.secured;
  }

  Color _sensorColor(Device? d) {
    final s = _sensorStatus(d);
    switch (s) {
      case _SensorStatus.secured:
        return AppColors.secured;
      case _SensorStatus.open:
        return AppColors.unsecured;
      case _SensorStatus.notConnected:
        return AppColors.statusOffline;
    }
  }

  IconData _sensorIcon(Device? d, bool isDoor) {
    final s = _sensorStatus(d);
    if (s == _SensorStatus.open) return isDoor ? Symbols.lock_open : Symbols.window;
    if (s == _SensorStatus.notConnected) return Symbols.link_off;
    return isDoor ? Symbols.lock : Symbols.shield;
  }

  void _showSecurityOptions(BuildContext context, AppState state, S s) {
    HapticFeedback.mediumImpact();
    final provider = context.read<LayoutProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SecurityOptionsSheet(
        provider: provider,
        state: state,
        s: s,
        onEditLayout: () {
          Navigator.pop(ctx);
          provider.toggleEditMode(DashboardId.security);
        },
        onToggleSections: () {
          Navigator.pop(ctx);
          _showSectionVisibility(context, provider, s);
        },
        onRestoreDefaults: () {
          Navigator.pop(ctx);
          _confirmRestoreDefaults(context, provider, s);
        },
        onSystemTest: () {
          Navigator.pop(ctx);
          _runSystemTest(context, state, s);
        },
        onEventLog: () {
          Navigator.pop(ctx);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CyberScreen()));
        },
      ),
    );
  }

  void _showSectionVisibility(
      BuildContext context, LayoutProvider provider, S s) {
    final sectionNames = <String, String>{
      'zones':     s.doorSensor,
      'sensors':   s.motionSensors,
      'locks':     s.smartLocksTitle,
      'event_log': s.cyberTitle,
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) {
          final current = provider.getItems(
              DashboardId.security, allItems: true);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: context.tText2(0.2),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 18),
                Text(
                  s.showHideSections,
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...current
                    .where((i) => sectionNames.containsKey(i.type))
                    .map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        provider.toggleVisibility(
                            DashboardId.security, item.id);
                        setSt(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.tText2(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: context.tText2(item.visible ? 0.12 : 0.06)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.visible
                                  ? Symbols.visibility
                                  : Symbols.visibility_off,
                              color: item.visible
                                  ? AppColors.secured
                                  : context.tText2(0.35),
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                sectionNames[item.type] ?? item.type,
                                style: TextStyle(
                                  color: item.visible
                                      ? context.tText
                                      : context.tText2(0.35),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: item.visible,
                              activeTrackColor: AppColors.secured,
                              onChanged: (_) {
                                provider.toggleVisibility(
                                    DashboardId.security, item.id);
                                setSt(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmRestoreDefaults(
      BuildContext context, LayoutProvider provider, S s) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Symbols.restore,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(s.restoreDefaults,
              style: const TextStyle(fontSize: 16)),
        ]),
        content: Text(
            s.restoreDefaultsConfirm,
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              provider.restoreDefaults(
                  DashboardId.security, DashboardDefaults.security);
            },
            child: Text(s.restore,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _runSystemTest(BuildContext context, AppState state, S s) {
    HapticFeedback.lightImpact();
    final devices = state.devices;
    final sensors = devices.where((d) =>
        d.type == DeviceType.doorSensor ||
        d.type == DeviceType.windowSensor ||
        d.type == DeviceType.motionSensor ||
        d.type == DeviceType.smokeSensor ||
        d.type == DeviceType.waterLeakSensor ||
        d.type == DeviceType.smartLock).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: context.tText2(0.2),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secured.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Symbols.radar,
                      color: AppColors.secured, size: 20),
                ),
                const SizedBox(width: 12),
                Text(s.systemTest,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (sensors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(s.noSensorsFound,
                    style: TextStyle(
                        color: context.tText2(0.4), fontSize: 14)),
              )
            else
              ...sensors.map((d) {
                final online = d.status != DeviceStatus.offline;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.tText2(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.tText2(0.07)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: (online ? AppColors.secured : AppColors.statusOffline)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            online
                                ? Symbols.check_circle
                                : Symbols.link_off,
                            color: online ? AppColors.secured : AppColors.statusOffline,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(d.name,
                              style: TextStyle(
                                  color: context.tText, fontSize: 14)),
                        ),
                        Text(
                          online ? s.activeStatus : s.offlineLabel,
                          style: TextStyle(
                              color: online
                                  ? AppColors.secured
                                  : AppColors.statusOffline,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showGuestOptions(BuildContext context, AppState state, S s) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GuestOptionsSheet(
        title: s.welcomeGuestChoose,
        options: [
          _GuestOption(minutes: 5,  label: s.guestOptShort,  unit: s.guestMinutes),
          _GuestOption(minutes: 15, label: s.guestOptMedium, unit: s.guestMinutes),
          _GuestOption(minutes: 30, label: s.guestOptLong,   unit: s.guestMinutes),
        ],
        onSelect: (minutes) {
          Navigator.pop(ctx);
          state.welcomeGuest(minutes: minutes);
        },
      ),
    );
  }

  void _showPanicConfirm(BuildContext context, AppState state, S s) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PanicSheet(
        title: s.panicButton,
        question: s.panicWarning,
        cancelLabel: s.cancel,
        confirmLabel: s.panicActivate,
        onConfirm: () {
          state.activateEmergencyMode();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.emergencyActivated),
              backgroundColor: AppColors.unsecured,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

enum _SensorStatus { secured, open, notConnected }

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Symbols.chevron_right, color: context.tText, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 38), // balance the back-button on the left
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated Shield
// ─────────────────────────────────────────────────────────────
class _AnimatedShield extends StatelessWidget {
  final bool isSecured;
  final Animation<double> scaleAnim;
  final Animation<double> glowAnim;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final String securedText;
  final String notSecuredText;
  final String activeText;
  final String tapText;

  const _AnimatedShield({
    required this.isSecured,
    required this.scaleAnim,
    required this.glowAnim,
    required this.onToggle,
    this.onLongPress,
    required this.securedText,
    required this.notSecuredText,
    required this.activeText,
    required this.tapText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSecured ? AppColors.secured : AppColors.unsecured;

    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnim, glowAnim]),
      builder: (ctx, _) {
        return GestureDetector(
          onTap: onToggle,
          onLongPress: onLongPress,
          child: Column(
            children: [
              Transform.scale(
                scale: scaleAnim.value,
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: 0.07 * glowAnim.value),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Middle pulse ring
                      Container(
                        width: 182,
                        height: 182,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: 0.13 * glowAnim.value),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Inner glow circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25 * glowAnim.value),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.40),
                            color.withValues(alpha: 0.18),
                          ],
                        ).createShader(bounds),
                        child: Icon(
                          isSecured ? Symbols.shield : Symbols.shield,
                          size: 130,
                          color: context.tText,
                        ),
                      ),

                      Icon(
                        isSecured ? Symbols.check : Symbols.close,
                        color: color,
                        size: 48,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  isSecured ? securedText : notSecuredText,
                  key: ValueKey(isSecured),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  isSecured ? activeText : tapText,
                  key: ValueKey('sub_$isSecured'),
                  style: TextStyle(
                    color: context.tText2(0.4),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sensor row
// ─────────────────────────────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color color;
  final IconData statusIcon;
  final VoidCallback? onTap;

  const _SensorRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.color,
    required this.statusIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: color.withValues(alpha: 0.6), width: 3),
            top: BorderSide(color: context.tText2(0.07)),
            right: BorderSide(color: context.tText2(0.07)),
            bottom: BorderSide(color: context.tText2(0.07)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color.withValues(alpha: 0.75), size: 19),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.tText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Text(
              status,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(statusIcon, color: color, size: 17),
            ),

            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Symbols.chevron_left,
                  color: context.tText2(0.3), size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Smart Locks card (entry point)
// ─────────────────────────────────────────────────────────────
class _SmartLocksCard extends StatelessWidget {
  final S s;
  final List<Device> locks;
  const _SmartLocksCard({required this.s, required this.locks});

  @override
  Widget build(BuildContext context) {
    final allLocked = locks.isNotEmpty && locks.every((d) => d.isOn);
    final color = locks.isEmpty
        ? context.tText2(0.35)
        : allLocked
            ? AppColors.secured
            : AppColors.unsecured;
    final statusText = locks.isEmpty
        ? s.noLocksFound
        : allLocked
            ? s.lockedStatus
            : s.unlockedStatus;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SmartLockHubScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: locks.isEmpty
                ? context.tText2(0.07)
                : color.withValues(alpha: 0.30),
            width: locks.isEmpty ? 1.0 : 1.5,
          ),
          boxShadow: locks.isNotEmpty && !allLocked
              ? [
                  BoxShadow(
                    color: AppColors.unsecured.withValues(alpha: 0.10),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                allLocked && locks.isNotEmpty
                    ? Symbols.lock
                    : Symbols.lock_open,
                color: color, size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.smartLocksTitle,
                      style: TextStyle(
                          color: context.tText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    locks.isEmpty
                        ? statusText
                        : '${locks.length} ${s.devicesUnit} · $statusText',
                    style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_left, color: context.tText2(0.35), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PANIC button
// ─────────────────────────────────────────────────────────────
class _PanicButton extends StatefulWidget {
  final VoidCallback onLongPress;
  final String panicLabel;
  final String warningLabel;
  const _PanicButton({required this.onLongPress, required this.panicLabel, required this.warningLabel});

  @override
  State<_PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<_PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (ctx, _) {
        final g = ((_pulseAnim.value - 0.97) / 0.03).clamp(0.0, 1.0);
        return Transform.scale(
        scale: _pulseAnim.value,
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.warningLabel),
              duration: const Duration(seconds: 2),
            ),
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00)
                      .withValues(alpha: 0.18 + 0.30 * g),
                  blurRadius: 10 + 22 * g,
                  spreadRadius: 0 + 3 * g,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.tText2(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Symbols.warning_amber,
                    color: context.tText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.panicLabel,
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      widget.warningLabel,
                      style: TextStyle(
                        color: context.tText2(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );  // Transform.scale
      }, // builder
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Security options sheet (long-press shield)
// ─────────────────────────────────────────────────────────────
class _SecurityOptionsSheet extends StatelessWidget {
  final LayoutProvider provider;
  final AppState state;
  final S s;
  final VoidCallback onEditLayout;
  final VoidCallback onToggleSections;
  final VoidCallback onRestoreDefaults;
  final VoidCallback onSystemTest;
  final VoidCallback onEventLog;

  const _SecurityOptionsSheet({
    required this.provider,
    required this.state,
    required this.s,
    required this.onEditLayout,
    required this.onToggleSections,
    required this.onRestoreDefaults,
    required this.onSystemTest,
    required this.onEventLog,
  });

  @override
  Widget build(BuildContext context) {
    final isEditMode = provider.editModeFor(DashboardId.security);
    final accent = Theme.of(context).colorScheme.primary;

    final options = [
      _SheetOption(
        icon: isEditMode ? Symbols.check : Symbols.drag_indicator,
        color: accent,
        label: isEditMode ? 'סיום עריכה' : 'ערוך סדר אזורים',
        subtitle: 'גרור כדי לסדר מחדש',
        onTap: onEditLayout,
      ),
      _SheetOption(
        icon: Symbols.visibility,
        color: const Color(0xFF5C6BC0),
        label: s.showHideSections,
        subtitle: 'בחר אילו חלקים יופיעו',
        onTap: onToggleSections,
      ),
      _SheetOption(
        icon: Symbols.radar,
        color: AppColors.secured,
        label: s.systemTest,
        subtitle: 'סטטוס כל החיישנים והנעילות',
        onTap: onSystemTest,
      ),
      _SheetOption(
        icon: Symbols.history,
        color: AppColors.cyberColor,
        label: 'יומן אירועים',
        subtitle: 'היסטוריה ואיומי סייבר',
        onTap: onEventLog,
      ),
      _SheetOption(
        icon: Symbols.restore,
        color: AppColors.unsecured,
        label: 'שחזר ברירת מחדל',
        subtitle: 'אפס את סידור הלוח',
        onTap: onRestoreDefaults,
        isDestructive: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.2),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.tune,
                  color: context.tText2(0.5), size: 18),
              const SizedBox(width: 8),
              Text('הגדרות מסך אבטחה',
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 18),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: opt.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: opt.isDestructive
                      ? AppColors.unsecured.withValues(alpha: 0.05)
                      : context.tText2(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: opt.isDestructive
                        ? AppColors.unsecured.withValues(alpha: 0.20)
                        : context.tText2(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.label,
                              style: TextStyle(
                                  color: opt.isDestructive
                                      ? AppColors.unsecured
                                      : context.tText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          if (opt.subtitle.isNotEmpty)
                            Text(opt.subtitle,
                                style: TextStyle(
                                    color: context.tText2(0.4),
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Symbols.chevron_left,
                        color: context.tText2(0.25), size: 18),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _SheetOption {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetOption({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle = '',
    required this.onTap,
    this.isDestructive = false,
  });
}

// ─────────────────────────────────────────────────────────────
// Guest options picker (bottom sheet)
// ─────────────────────────────────────────────────────────────
class _GuestOption {
  final int minutes;
  final String label;
  final String unit;
  const _GuestOption({required this.minutes, required this.label, required this.unit});
}

class _GuestOptionsSheet extends StatelessWidget {
  final String title;
  final List<_GuestOption> options;
  final ValueChanged<int> onSelect;

  const _GuestOptionsSheet({
    required this.title,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.2),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00897B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Symbols.person,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: options
                .map((opt) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: opt == options.first ? 0 : 6,
                          right: opt == options.last ? 0 : 6,
                        ),
                        child: _GuestOptionCard(
                          option: opt,
                          onTap: () => onSelect(opt.minutes),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GuestOptionCard extends StatelessWidget {
  final _GuestOption option;
  final VoidCallback onTap;

  const _GuestOptionCard({required this.option, required this.onTap});

  IconData get _icon {
    if (option.minutes <= 5) return Symbols.flash_on;
    if (option.minutes <= 15) return Symbols.person;
    return Symbols.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00C853), Color(0xFF00897B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C853).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              '${option.minutes}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.0),
            ),
            Text(
              option.unit,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Welcome Guest button
// ─────────────────────────────────────────────────────────────
class _WelcomeGuestButton extends StatelessWidget {
  final String label;
  final String hint;
  final bool isActive;
  final VoidCallback onTap;

  const _WelcomeGuestButton({
    required this.label,
    required this.hint,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor  = AppColors.secured;
    const inactiveFrom = Color(0xFF00C853);
    const inactiveTo   = Color(0xFF00897B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [activeColor.withValues(alpha: 0.55), activeColor.withValues(alpha: 0.35)]
                : [inactiveFrom, inactiveTo],
          ),
          borderRadius: BorderRadius.circular(18),
          border: isActive
              ? Border.all(color: activeColor.withValues(alpha: 0.6), width: 1.5)
              : null,
          boxShadow: isActive ? null : [
            BoxShadow(
              color: inactiveTo.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.tText2(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Symbols.person_off : Symbols.person,
                color: context.tText,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    hint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.tText2(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Guest mode active bar (shown in pinned header)
// ─────────────────────────────────────────────────────────────
class _GuestModeBar extends StatelessWidget {
  final int secondsLeft;
  final String activeLabel;
  final String timerTemplate;
  final String cancelLabel;
  final VoidCallback onCancel;

  const _GuestModeBar({
    required this.secondsLeft,
    required this.activeLabel,
    required this.timerTemplate,
    required this.cancelLabel,
    required this.onCancel,
  });

  String _formatTime() {
    final m = (secondsLeft / 60).ceil().clamp(0, 99);
    return timerTemplate.replaceAll('{n}', '$m');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.person,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activeLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(_formatTime(),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(cancelLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Panic confirmation sheet
// ─────────────────────────────────────────────────────────────
class _PanicSheet extends StatelessWidget {
  final String title;
  final String question;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PanicSheet({
    required this.title,
    required this.question,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.unsecured.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.warning_amber,
              color: AppColors.unsecured,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.tText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText2(0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FtButton(
                  label:   cancelLabel,
                  variant: FtButtonVariant.secondary,
                  onTap:   onCancel,
                  expand:  true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FtButton(
                  label:   confirmLabel,
                  variant: FtButtonVariant.danger,
                  onTap:   onConfirm,
                  expand:  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
