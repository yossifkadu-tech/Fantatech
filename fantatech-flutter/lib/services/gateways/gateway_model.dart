// ─────────────────────────────────────────────────────────────────────────────
// GatewayConnection — stores a single connected gateway's credentials + state.
// GatewayImportResult — result of importing devices from a gateway.
// ─────────────────────────────────────────────────────────────────────────────
import '../../models/device.dart';
import 'gateway_types.dart';

class GatewayConnection {
  final String id;             // UUID
  final GatewayType type;
  String displayName;
  Map<String, String> credentials; // {ip, token, port, …}
  bool isConnected;
  DateTime? lastSync;
  int deviceCount;
  String? error;

  GatewayConnection({
    required this.id,
    required this.type,
    required this.displayName,
    required this.credentials,
    this.isConnected  = false,
    this.lastSync,
    this.deviceCount  = 0,
    this.error,
  });

  String? get ip    => credentials['ip'];
  String? get token => credentials['token'];

  Map<String, dynamic> toJson() => {
    'id':          id,
    'type':        type.name,
    'displayName': displayName,
    'credentials': credentials,
    'connected':   isConnected,
    'lastSync':    lastSync?.toIso8601String(),
    'deviceCount': deviceCount,
  };

  factory GatewayConnection.fromJson(Map<String, dynamic> j) =>
      GatewayConnection(
        id:           j['id'] as String,
        type:         GatewayType.values.firstWhere(
                          (t) => t.name == j['type']),
        displayName:  j['displayName'] as String,
        credentials:  Map<String, String>.from(
                          j['credentials'] as Map<dynamic, dynamic>),
        isConnected:  j['connected'] as bool? ?? false,
        lastSync:     j['lastSync'] != null
                          ? DateTime.tryParse(j['lastSync'] as String)
                          : null,
        deviceCount:  j['deviceCount'] as int? ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Import result
// ─────────────────────────────────────────────────────────────────────────────
class GatewayImportResult {
  final List<Device> devices;
  final String? error;
  bool get isSuccess => error == null;

  const GatewayImportResult.success(this.devices) : error = null;
  const GatewayImportResult.failure(this.error)   : devices = const [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Connect result — returned after a pairing attempt
// ─────────────────────────────────────────────────────────────────────────────
class GatewayConnectResult {
  final bool success;
  final String? error;
  final Map<String, String>? resolvedCredentials; // e.g. {username} from Hue pairing

  const GatewayConnectResult.ok(this.resolvedCredentials)
      : success = true, error = null;
  const GatewayConnectResult.fail(this.error)
      : success = false, resolvedCredentials = null;
}
