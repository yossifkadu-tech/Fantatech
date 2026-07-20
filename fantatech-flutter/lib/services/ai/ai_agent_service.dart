// ─────────────────────────────────────────────────────────────────────────────
// AiAgentService — real Claude-powered smart-home agent.
//
// Replaces keyword matching with an actual tool-use loop against Anthropic's
// Messages API (proxied through the `ai-agent` Supabase Edge Function, which
// holds the API key — never on-device).
//
// Flow per user message:
//   1. Send the running conversation + current device inventory to the
//      edge function.
//   2. Claude replies with text and/or `tool_use` blocks.
//   3. Every tool_use is executed HERE, against the real AppState/
//      DeviceCommander methods — this is the only place with gateway access.
//   4. Results are fed back as `tool_result` blocks; loop until Claude stops
//      requesting tools and returns a final text reply.
//
// The agent never reports success on its own — every "it worked" comes from
// a real awaited bool returned by AppState's command methods.
// ─────────────────────────────────────────────────────────────────────────────
import '../../backend/backend_service.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';

class AgentReply {
  final String text;
  const AgentReply(this.text);
}

class AiAgentService {
  AiAgentService();

  final List<Map<String, dynamic>> _history = [];

  static const _maxToolRounds = 5;

  void clearHistory() => _history.clear();

  /// Sends [userText] to the agent, executing any tool calls it requests
  /// against [state], and returns its final conversational reply.
  Future<AgentReply> send(String userText, AppState state) async {
    if (!BackendService.isReady) {
      return AgentReply(state.strings.aiBackendNotConfigured);
    }

    _history.add({
      'role': 'user',
      'content': userText,
    });

    try {
      for (var round = 0; round < _maxToolRounds; round++) {
        final res = await BackendService.client.functions.invoke(
          'ai-agent',
          body: {
            'messages': _history,
            'devices': _deviceSummaries(state),
            'locale': state.locale.name,
          },
        );

        final data = res.data;
        if (data is! Map || data['content'] is! List) {
          return AgentReply(state.strings.aiRequestFailed);
        }

        final content = (data['content'] as List).cast<Map<String, dynamic>>();
        _history.add({'role': 'assistant', 'content': content});

        final toolUses = content.where((b) => b['type'] == 'tool_use').toList();
        if (toolUses.isEmpty) {
          final text = content
              .where((b) => b['type'] == 'text')
              .map((b) => b['text'] as String? ?? '')
              .join(' ')
              .trim();
          return AgentReply(text.isEmpty ? state.strings.aiEmptyReply : text);
        }

        // Execute every requested tool for real, then report the true
        // outcome back — the agent must never assume success.
        final toolResults = <Map<String, dynamic>>[];
        for (final call in toolUses) {
          final outcome = await _executeTool(
            call['name'] as String? ?? '',
            (call['input'] as Map?)?.cast<String, dynamic>() ?? const {},
            state,
          );
          toolResults.add({
            'type': 'tool_result',
            'tool_use_id': call['id'],
            'content': outcome,
          });
        }
        _history.add({'role': 'user', 'content': toolResults});
      }
      return AgentReply(state.strings.aiTooManySteps);
    } catch (e) {
      return AgentReply(state.strings.aiRequestFailed);
    }
  }

  // ── Tool execution — every branch calls a real, awaited AppState method ──

  Future<String> _executeTool(
      String name, Map<String, dynamic> input, AppState state) async {
    switch (name) {
      case 'set_power':
        final id = input['device_id'] as String?;
        final on = input['on'] as bool?;
        if (id == null || on == null) return 'error: missing device_id or on';
        final ok = await state.setDevicePower(id, on);
        return ok ? 'success' : 'failed: device did not confirm the command';

      case 'set_brightness':
        final id = input['device_id'] as String?;
        final pct = (input['percent'] as num?)?.toInt();
        if (id == null || pct == null) return 'error: missing device_id or percent';
        final ok = await state.agentSetBrightness(id, pct.clamp(0, 100));
        return ok ? 'success' : 'failed: device did not confirm the command';

      case 'set_cover_position':
        final id = input['device_id'] as String?;
        final pos = (input['position'] as num?)?.toInt();
        if (id == null || pos == null) return 'error: missing device_id or position';
        final ok = await state.agentSetCoverPosition(id, pos.clamp(0, 100));
        return ok ? 'success' : 'failed: device did not confirm the command';

      case 'set_climate':
        final id = input['device_id'] as String?;
        if (id == null) return 'error: missing device_id';
        final ok = await state.agentSetClimate(
          id,
          hvacMode: input['hvac_mode'] as String?,
          temperature: (input['temperature'] as num?)?.toDouble(),
          fanMode: input['fan_mode'] as String?,
        );
        return ok ? 'success' : 'failed: device did not confirm the command';

      case 'set_security_mode':
        final mode = _parseSecurityMode(input['mode'] as String?);
        if (mode == null) return 'error: unknown security mode';
        state.setSecurityMode(mode);
        return 'success';

      default:
        return 'error: unknown tool "$name"';
    }
  }

  SecurityMode? _parseSecurityMode(String? raw) => switch (raw) {
        'disarmed' => SecurityMode.disarmed,
        'armedHome' => SecurityMode.armedHome,
        'armedAway' => SecurityMode.armedAway,
        _ => null,
      };

  List<Map<String, dynamic>> _deviceSummaries(AppState state) => state.devices
      .map((Device d) => {
            'id': d.id,
            'name': d.name,
            'type': d.type.name,
            'room': d.room,
            'isOn': d.isOn,
            'status': d.status.name,
          })
      .toList();
}
