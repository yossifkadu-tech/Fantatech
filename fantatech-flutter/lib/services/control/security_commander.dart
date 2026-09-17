// ─────────────────────────────────────────────────────────────────────────────
// SecurityCommander — sends a real arm/disarm command to whichever alarm
// panel gateway (Ajax / Risco / PIMA) is connected, if any.
//
// Unlike DeviceCommander, this isn't keyed by a Device id — arming/disarming
// is a whole-panel action, not scoped to one device (see AlarmButtonSpec's
// own doc comment for why AppState.securityMode, not a Device, is the right
// home for this state). None of these three panel APIs expose a distinct
// home/away/night mode (Ajax and PIMA are binary arm/disarm; Risco arms a
// partition) — mapping FantaTech's armedHome/armedAway/armedNight all onto
// the panel's single "arm" is an honest simplification, not a shortcut: the
// three-way distinction stays real and local-only (SecurityMode itself),
// it just isn't invented at the protocol level where it doesn't exist.
//
// If no alarm-panel gateway is connected, [armDisarm] returns true
// immediately — that's the existing (pre-this-file) behavior for every user
// without a real panel, preserved so this doesn't regress anyone.
// ─────────────────────────────────────────────────────────────────────────────
import '../gateways/gateway_manager.dart';
import '../gateways/gateway_model.dart';
import '../gateways/gateway_types.dart';
import '../gateways/clients/ajax_client.dart';
import '../gateways/clients/risco_client.dart';
import '../gateways/clients/pima_client.dart';
import '../../models/device.dart';

abstract class SecurityCommander {
  SecurityCommander._();

  static Future<bool> armDisarm(
    bool arm, {
    required GatewayManager gateways,
    required List<Device> devices,
  }) async {
    final ajax = _gateway(gateways, GatewayType.ajax);
    if (ajax != null) {
      final email    = ajax.credentials['email'];
      final password = ajax.credentials['password'];
      final apiKey   = ajax.credentials['apiKey'];
      if (email == null || password == null) return false;
      // hubId lives on the imported devices' attributes (see
      // gateway_manager.dart's Ajax _doImport), not on the connection's own
      // credentials — any device from this hub carries the same hubId.
      final hubId = _findAttribute(devices, 'ajax-', 'hubId');
      if (hubId == null || hubId.isEmpty) return false;
      final client = AjaxClient(
        email: email,
        password: password,
        apiKey: (apiKey == null || apiKey.isEmpty) ? null : apiKey,
      );
      final ok = await client.login();
      if (!ok) return false;
      return arm ? client.arm(hubId) : client.disarm(hubId);
    }

    final risco = _gateway(gateways, GatewayType.risco);
    if (risco != null) {
      final username = risco.credentials['username'];
      final password = risco.credentials['password'];
      final pin      = risco.credentials['pin'];
      if (username == null || password == null || pin == null) return false;
      final client = RiscoClient(username: username, password: password, pin: pin);
      final ok = await client.login();
      if (!ok) return false;
      return arm ? client.arm() : client.disarm();
    }

    final pima = _gateway(gateways, GatewayType.pima);
    if (pima != null) {
      final ip   = pima.credentials['ip'];
      final code = pima.credentials['code'];
      if (ip == null || code == null) return false;
      final port = int.tryParse(pima.credentials['port'] ?? '') ?? 9999;
      final client = PimaClient(ip: ip, code: code, port: port);
      return arm ? client.arm() : client.disarm();
    }

    // No real alarm-panel gateway connected — local-only security mode.
    return true;
  }

  /// Returns whether a real alarm-panel gateway (Ajax/Risco/PIMA) is
  /// currently connected — callers use this to decide whether to show a
  /// "local mode only" hint alongside the confirmation dialog.
  static bool hasRealPanel(GatewayManager gateways) =>
      _gateway(gateways, GatewayType.ajax) != null ||
      _gateway(gateways, GatewayType.risco) != null ||
      _gateway(gateways, GatewayType.pima) != null;

  static String? _findAttribute(List<Device> devices, String idPrefix, String key) {
    for (final d in devices) {
      if (d.id.startsWith(idPrefix)) {
        final v = d.attributes[key];
        if (v != null) return v.toString();
      }
    }
    return null;
  }

  static GatewayConnection? _gateway(GatewayManager m, GatewayType type) {
    for (final c in m.connections) {
      if (c.type == type && c.isConnected) return c;
    }
    return null;
  }
}
