// ─────────────────────────────────────────────────────────────────────────────
// CustomScene — a user-created scene.
//
// Each action is nullable: null = "leave as-is", true/false = set on/off.
// Activating the scene applies every non-null action to the matching devices.
// ─────────────────────────────────────────────────────────────────────────────

class CustomScene {
  final String id;
  String name;
  int iconCode;   // Material icon codePoint
  int colorValue; // ARGB

  bool? lights;   // turn lights on/off
  bool? plugs;    // smart plugs on/off
  bool? ac;       // air conditioner on/off
  double? acTemp; // optional AC target temperature
  bool? blindsOpen; // true = open, false = close
  bool? arm;      // security armed/disarmed

  CustomScene({
    required this.id,
    required this.name,
    this.iconCode = 0xe5ca, // check
    this.colorValue = 0xFF1A73E8,
    this.lights,
    this.plugs,
    this.ac,
    this.acTemp,
    this.blindsOpen,
    this.arm,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'lights': lights,
        'plugs': plugs,
        'ac': ac,
        'acTemp': acTemp,
        'blindsOpen': blindsOpen,
        'arm': arm,
      };

  factory CustomScene.fromJson(Map<String, dynamic> j) => CustomScene(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Scene',
        iconCode: j['iconCode'] as int? ?? 0xe5ca,
        colorValue: j['colorValue'] as int? ?? 0xFF1A73E8,
        lights: j['lights'] as bool?,
        plugs: j['plugs'] as bool?,
        ac: j['ac'] as bool?,
        acTemp: (j['acTemp'] as num?)?.toDouble(),
        blindsOpen: j['blindsOpen'] as bool?,
        arm: j['arm'] as bool?,
      );
}
