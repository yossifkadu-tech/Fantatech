// ─────────────────────────────────────────────────────────────────────────────
// Discovery Manager
// Orchestrates all four scanners in the correct order and exposes a single
// ChangeNotifier interface to the Flutter widget tree.
//
// Scan pipeline:
//   1. WiFi Scanner     — fast parallel TCP probe of the /24 subnet
//   2. BLE Scanner      — 10-second Bluetooth LE advertisement window
//   3. Matter Discovery — mDNS queries for all known service types
//   4. Gateway Discovery— deep HTTP fingerprint of WiFi-found hosts
//   5. Device Identifier— enrichment pass on every found device
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../l10n/strings.dart';
import 'discovery_models.dart';
import 'wifi_scanner.dart';
import 'ble_scanner.dart';
import 'matter_discovery.dart';
import 'gateway_discovery.dart';
import 'device_identifier.dart';

export 'discovery_models.dart';

class DiscoveryManager extends ChangeNotifier {
  // ── Localization ──────────────────────────────────────────────────────────
  S? _strings;

  /// Call before startScan() to localise all progress/log messages.
  void setStrings(S s) { _strings = s; }

  /// Replaces '{n}' placeholder in a format string.
  String _fmt(String template, int n) => template.replaceAll('{n}', '$n');

  // ── State ─────────────────────────────────────────────────────────────────
  DiscoveryStatus _status = DiscoveryStatus.idle;
  double _progress = 0.0;
  String _progressMessage = '';
  String? _lastError;

  final List<DiscoveredDevice> _devices = [];
  final List<String> _log = [];

  // Which scanners are currently active
  bool _wifiRunning = false;
  bool _bleRunning = false;
  bool _matterRunning = false;
  bool _gatewayRunning = false;

  StreamSubscription<ScannerEvent>? _activeSubscription;

  // ── Scanners ──────────────────────────────────────────────────────────────
  final WiFiScanner _wifi = WiFiScanner();
  final BLEScanner _ble = BLEScanner();
  final MatterDiscovery _matter = MatterDiscovery();
  final GatewayDiscovery _gateway = GatewayDiscovery();
  final DeviceIdentifier _identifier = DeviceIdentifier();

  // ── Config ─────────────────────────────────────────────────────────────────
  bool enableWifi = true;
  bool enableBle = true;
  bool enableMatter = true;
  bool enableGatewayProbe = true;

  // ── Getters ───────────────────────────────────────────────────────────────
  DiscoveryStatus get status => _status;
  double get progress => _progress;
  String get progressMessage => _progressMessage;
  String? get lastError => _lastError;
  bool get isScanning => _status == DiscoveryStatus.scanning;

  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);
  List<String> get log => List.unmodifiable(_log);

  bool get wifiRunning => _wifiRunning;
  bool get bleRunning => _bleRunning;
  bool get matterRunning => _matterRunning;
  bool get gatewayRunning => _gatewayRunning;

  // ── Filtered views ────────────────────────────────────────────────────────
  List<DiscoveredDevice> byType(DiscoveredDeviceType type) =>
      _devices.where((d) => d.type == type).toList();

  List<DiscoveredDevice> byProtocol(DiscoveryProtocol protocol) =>
      _devices.where((d) => d.protocol == protocol).toList();

  List<DiscoveredDevice> get unregistered =>
      _devices.where((d) => !d.isRegistered).toList();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start a full discovery run.
  Future<void> startScan() async {
    if (_status == DiscoveryStatus.scanning) return;

    _devices.clear();
    _log.clear();
    _lastError = null;
    _setStatus(DiscoveryStatus.scanning);
    _setProgress(0.0, _strings?.scanStarting ?? 'Starting scan…');

    try {
      // ── Phase 1: WiFi scan ───────────────────────────────────────────────
      final wifiDevices = <DiscoveredDevice>[];
      if (enableWifi) {
        _wifiRunning = true;
        notifyListeners();
        _addLog(_strings?.scanWifiLog ?? 'WiFiScanner: starting LAN scan');

        await for (final event in _wifi.scan()) {
          _handleEvent(event, 'WiFi');
          if (event is DeviceFoundEvent) wifiDevices.add(event.device);
        }

        _wifiRunning = false;
        notifyListeners();
        _addLog(_fmt(_strings?.scanWifiDoneFmt ?? 'WiFiScanner: done ({n} hosts)', wifiDevices.length));
      }

      // ── Phase 2: BLE scan (parallel with remaining phases) ───────────────
      Future<void>? bleFuture;
      if (enableBle) {
        _bleRunning = true;
        notifyListeners();
        _addLog(_strings?.scanBleLog ?? 'BLEScanner: starting BLE scan');

        bleFuture = _runBle();
      }

      // ── Phase 3: Matter / mDNS ───────────────────────────────────────────
      if (enableMatter) {
        _matterRunning = true;
        notifyListeners();
        _addLog(_strings?.scanMatterLog ?? 'MatterDiscovery: searching mDNS');

        await for (final event in _matter.scan()) {
          _handleEvent(event, 'Matter');
        }

        _matterRunning = false;
        notifyListeners();
        _addLog(_strings?.scanMatterDone ?? 'MatterDiscovery: done');
      }

      // ── Phase 4: Gateway + device deep probe ─────────────────────────────
      if (enableGatewayProbe && wifiDevices.isNotEmpty) {
        _gatewayRunning = true;
        notifyListeners();
        _addLog(_fmt(_strings?.scanGatewayFmt ?? 'Deep-probing {n} devices', wifiDevices.length));

        await for (final event in _gateway.identify(wifiDevices)) {
          _handleEvent(event, (_strings?.scanGatewayDone ?? 'Probe').split(':').first);
        }

        _gatewayRunning = false;
        notifyListeners();
        _addLog(_strings?.scanGatewayDone ?? 'Deep probe: done');
      }

      // Wait for BLE to finish
      if (bleFuture != null) {
        await bleFuture;
        _bleRunning = false;
        notifyListeners();
        _addLog(_strings?.scanBleDone ?? 'BLEScanner: done');
      }

      // ── Phase 5: Device Identifier (enrichment pass) ──────────────────────
      _addLog(_fmt(_strings?.scanIdentifyingFmt ?? 'Identifying {n} devices…', _devices.length));
      _setProgress(0.97, _strings?.scanIdentifyingProgress ?? 'Identifying devices…');

      for (int i = 0; i < _devices.length; i++) {
        _devices[i] = _identifier.identify(_devices[i]);
      }

      final found = _devices.length;
      _addLog(_fmt(_strings?.scanFinishedFmt ?? 'Scan complete — {n} devices found', found));
      _setStatus(DiscoveryStatus.done);
      _setProgress(1.0, found == 0
          ? (_strings?.scanNoDevicesFound ?? 'No devices found')
          : _fmt(_strings?.scanFoundFmt ?? '{n} devices found', found));
    } catch (e, st) {
      _lastError = e.toString();
      _addLog('FATAL: $e');
      debugPrint('DiscoveryManager error: $e\n$st');
      _setStatus(DiscoveryStatus.error);
    } finally {
      _wifiRunning = false;
      _bleRunning = false;
      _matterRunning = false;
      _gatewayRunning = false;
      notifyListeners();
    }
  }

  /// Cancel any active scan.
  void cancelScan() {
    _activeSubscription?.cancel();
    _activeSubscription = null;
    _wifiRunning = false;
    _bleRunning = false;
    _matterRunning = false;
    _gatewayRunning = false;
    _setStatus(DiscoveryStatus.idle);
    _setProgress(0.0, _strings?.scanCancelledProgress ?? 'Scan cancelled');
    _addLog(_strings?.scanCancelledLog ?? 'Scan cancelled by user');
  }

  /// Mark a device as registered (added to home).
  void registerDevice(String deviceId) {
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx >= 0) {
      _devices[idx] = _devices[idx].copyWith(isRegistered: true);
      notifyListeners();
    }
  }

  /// Clear all discovery results.
  void clear() {
    _devices.clear();
    _log.clear();
    _lastError = null;
    _setStatus(DiscoveryStatus.idle);
    _setProgress(0.0, '');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _runBle() async {
    await for (final event in _ble.scan()) {
      _handleEvent(event, 'BLE');
    }
  }

  void _handleEvent(ScannerEvent event, String source) {
    switch (event) {
      case DeviceFoundEvent():
        final existing = _devices.indexWhere(
            (d) => d.id == event.device.id || d.ip == event.device.ip);
        if (existing >= 0) {
          // Merge: gateway probe may enrich a WiFi-found device
          _devices[existing] = _merge(_devices[existing], event.device);
        } else {
          _devices.add(event.device);
        }

      case ScannerProgressEvent():
        final pct = event.progress >= 0
            ? '${(event.progress * 100).toInt()}% '
            : '';
        _setProgress(event.progress, '[$source] $pct${event.message}');

      case ScannerErrorEvent():
        _lastError = event.message;
        _addLog('[$source] ERROR: ${event.message}');

      case ScannerDoneEvent():
        _addLog('[$source] ✓ done');
    }
    notifyListeners();
  }

  /// Merge two records for the same device (e.g. WiFi scan + gateway probe).
  DiscoveredDevice _merge(DiscoveredDevice existing, DiscoveredDevice newer) {
    return existing.copyWith(
      displayName: newer.type != DiscoveredDeviceType.unknown
          ? newer.displayName
          : existing.displayName,
      type: newer.type != DiscoveredDeviceType.unknown
          ? newer.type
          : existing.type,
      manufacturer: newer.manufacturer ?? existing.manufacturer,
      model: newer.model ?? existing.model,
      openPorts: {
        ...existing.openPorts,
        ...newer.openPorts,
      }.toList(),
      metadata: {
        ...existing.metadata,
        ...newer.metadata,
      },
    );
  }

  void _setStatus(DiscoveryStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setProgress(double p, String message) {
    _progress = p.clamp(0.0, 1.0);
    _progressMessage = message;
    notifyListeners();
  }

  void _addLog(String message) {
    final ts = DateTime.now();
    final line =
        '[${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}] $message';
    _log.add(line);
    debugPrint(line);
  }

  @override
  void dispose() {
    _activeSubscription?.cancel();
    super.dispose();
  }
}
