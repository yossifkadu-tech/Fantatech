// ─────────────────────────────────────────────────────────────────────────────
// HaPushRule — a single notification trigger rule for a HA entity event
//
// Rules are evaluated against every `state_changed` WebSocket event.
// Pattern matching is prefix-based: "binary_sensor.smoke" matches
// "binary_sensor.smoke_kitchen", exact IDs match exactly.
// ─────────────────────────────────────────────────────────────────────────────

class HaPushRule {
  final String id;

  /// Human-readable rule name shown in the settings UI
  final String name;

  /// entity_id prefix or exact match (e.g. "alarm_control_panel.", "lock.front")
  final String entityPattern;

  /// If non-null, only trigger when the new state matches (e.g. "on", "triggered")
  final String? triggerState;

  /// Notification title. Supports {{friendly_name}} and {{entity_id}} tokens.
  final String titleTemplate;

  /// Notification body. Supports {{state}}, {{friendly_name}}, {{entity_id}}.
  final String bodyTemplate;

  /// Notification priority (0 = default, 1 = high — wakes screen)
  final int priority;

  bool enabled;

  HaPushRule({
    required this.id,
    required this.name,
    required this.entityPattern,
    this.triggerState,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.priority = 1,
    this.enabled = true,
  });

  bool matches(String entityId, String newState) {
    final entityMatch = entityId == entityPattern ||
        entityId.startsWith(entityPattern);
    if (!entityMatch) return false;
    if (triggerState != null && newState != triggerState) return false;
    return true;
  }

  String resolveTitle(String friendlyName, String entityId) =>
      titleTemplate
          .replaceAll('{{friendly_name}}', friendlyName)
          .replaceAll('{{entity_id}}', entityId);

  String resolveBody(String friendlyName, String entityId, String state) =>
      bodyTemplate
          .replaceAll('{{friendly_name}}', friendlyName)
          .replaceAll('{{entity_id}}', entityId)
          .replaceAll('{{state}}', _localiseState(state));

  static String _localiseState(String s) {
    switch (s) {
      case 'on':         return 'פעיל';
      case 'off':        return 'כבוי';
      case 'open':       return 'פתוח';
      case 'closed':     return 'סגור';
      case 'locked':     return 'נעול';
      case 'unlocked':   return 'פתוח';
      case 'triggered':  return 'הופעל!';
      case 'armed_away': return 'מזויין (חוץ)';
      case 'armed_home': return 'מזויין (בית)';
      case 'disarmed':   return 'כובה';
      default:           return s;
    }
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'name':           name,
    'entityPattern':  entityPattern,
    'triggerState':   triggerState,
    'titleTemplate':  titleTemplate,
    'bodyTemplate':   bodyTemplate,
    'priority':       priority,
    'enabled':        enabled,
  };

  factory HaPushRule.fromJson(Map<String, dynamic> j) => HaPushRule(
    id:             j['id']            as String,
    name:           j['name']          as String,
    entityPattern:  j['entityPattern'] as String,
    triggerState:   j['triggerState']  as String?,
    titleTemplate:  j['titleTemplate'] as String,
    bodyTemplate:   j['bodyTemplate']  as String,
    priority:       (j['priority']     as int?) ?? 1,
    enabled:        (j['enabled']      as bool?) ?? true,
  );
}

// ── Built-in rules (always present, can be toggled but not deleted) ───────────

final kDefaultPushRules = <HaPushRule>[
  HaPushRule(
    id:            'alarm_triggered',
    name:          '⚠️ אזעקה הופעלה',
    entityPattern: 'alarm_control_panel.',
    triggerState:  'triggered',
    titleTemplate: '⚠️ אזעקה!',
    bodyTemplate:  '{{friendly_name}} הופעלה',
    priority:      2,
  ),
  HaPushRule(
    id:            'alarm_armed',
    name:          '🔒 מערכת אבטחה מזויינת',
    entityPattern: 'alarm_control_panel.',
    triggerState:  null, // any armed_* or disarmed
    titleTemplate: '🔒 מצב אבטחה',
    bodyTemplate:  '{{friendly_name}}: {{state}}',
    priority:      1,
  ),
  HaPushRule(
    id:            'motion_on',
    name:          '🚶 תנועה זוהתה',
    entityPattern: 'binary_sensor.',
    triggerState:  'on',
    titleTemplate: '🚶 תנועה',
    bodyTemplate:  '{{friendly_name}} זיהה תנועה',
    priority:      1,
    enabled:       false, // off by default (too noisy)
  ),
  HaPushRule(
    id:            'door_open',
    name:          '🚪 דלת/חלון נפתח',
    entityPattern: 'binary_sensor.',
    triggerState:  'on',
    titleTemplate: '🚪 פתיחה',
    bodyTemplate:  '{{friendly_name}} נפתח',
    priority:      1,
    enabled:       false,
  ),
  HaPushRule(
    id:            'water_leak',
    name:          '💧 דליפת מים',
    entityPattern: 'binary_sensor.',
    triggerState:  'on',
    titleTemplate: '💧 דליפת מים!',
    bodyTemplate:  '{{friendly_name}} מזהה דליפה',
    priority:      2,
  ),
  HaPushRule(
    id:            'smoke',
    name:          '🔥 עשן זוהה',
    entityPattern: 'binary_sensor.',
    triggerState:  'on',
    titleTemplate: '🔥 עשן!',
    bodyTemplate:  '{{friendly_name}} זיהה עשן',
    priority:      2,
  ),
  HaPushRule(
    id:            'lock_unlocked',
    name:          '🔓 מנעול נפתח',
    entityPattern: 'lock.',
    triggerState:  'unlocked',
    titleTemplate: '🔓 מנעול',
    bodyTemplate:  '{{friendly_name}} נפתח',
    priority:      1,
  ),
  HaPushRule(
    id:            'co_gas',
    name:          '☁️ גז / CO זוהה',
    entityPattern: 'binary_sensor.',
    triggerState:  'on',
    titleTemplate: '☁️ אזהרת גז!',
    bodyTemplate:  '{{friendly_name}} מזהה גז/CO',
    priority:      2,
  ),
];
