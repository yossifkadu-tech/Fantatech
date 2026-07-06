import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../services/gateways/clients/ha_gateway_client.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_nav.dart';

class LightsHubScreen extends StatelessWidget {
  const LightsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LightsHubView();
  }
}

class _LightsHubView extends StatefulWidget {
  const _LightsHubView();

  @override
  State<_LightsHubView> createState() => _LightsHubViewState();
}

class _LightsHubViewState extends State<_LightsHubView> {
  // Local brightness cache to avoid slider lag
  final Map<String, double> _brightness = {};

  List<Device> _lights(AppState state) =>
      state.devices.where((d) => d.type == DeviceType.light).toList();

  void _allOn(List<Device> lights, AppState state) {
    HapticFeedback.mediumImpact();
    for (final d in lights) {
      if (!d.isOn) state.toggleDevice(d.id);
    }
  }

  void _allOff(List<Device> lights, AppState state) {
    HapticFeedback.mediumImpact();
    for (final d in lights) {
      if (d.isOn) state.toggleDevice(d.id);
    }
  }

  Future<void> _setBrightness(Device d, double pct, AppState state) async {
    state.setDeviceAttribute(d.id, 'brightness', pct.round());
    final gm = context.read<GatewayManager>();
    for (final c in gm.connections) {
      if (c.type == GatewayType.homeAssistant && c.isConnected) {
        final ip    = c.credentials['ip'];
        final token = c.credentials['token'];
        final eid   = d.attributes['entityId'] as String?;
        if (ip != null && token != null && eid != null) {
          await HaGatewayClient.setBrightness(ip, token, eid, pct.round());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final s      = state.strings;
    final lights = _lights(state);
    final onCount = lights.where((d) => d.isOn).length;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  const FtBackButton(),
                  Expanded(
                    child: Text(s.lightsHubTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            if (lights.isNotEmpty) ...[
              // ── Status banner ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: onCount > 0
                          ? [AppColors.lightColor.withValues(alpha: 0.15), AppColors.lightColor.withValues(alpha: 0.05)]
                          : [context.tText2(0.05), context.tText2(0.02)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: onCount > 0
                            ? AppColors.lightColor.withValues(alpha: 0.3)
                            : context.tText2(0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(onCount > 0 ? Symbols.lightbulb : Symbols.lightbulb,
                          color: onCount > 0 ? AppColors.lightColor : context.tText2(0.3),
                          size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$onCount / ${lights.length}  ${s.lightsHubTitle.toLowerCase()}',
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Global action buttons ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: s.lightsAllOn,
                        icon: Symbols.lightbulb,
                        color: AppColors.lightColor,
                        onTap: () => _allOn(lights, state),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        label: s.lightsAllOff,
                        icon: Symbols.lightbulb,
                        color: context.tText2(0.4),
                        onTap: () => _allOff(lights, state),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: lights.isEmpty
                  ? _EmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: lights.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final d = lights[i];
                        final brt = _brightness[d.id] ??
                            (d.attributes['brightness'] as int? ?? 80).toDouble();
                        return _LightCard(
                          device: d,
                          brightness: brt,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            state.toggleDevice(d.id);
                          },
                          onBrightnessChange: (v) =>
                              setState(() => _brightness[d.id] = v),
                          onBrightnessEnd: (v) => _setBrightness(d, v, state),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Light card
// ─────────────────────────────────────────────────────────────
class _LightCard extends StatelessWidget {
  final Device device;
  final double brightness;
  final VoidCallback onToggle;
  final ValueChanged<double> onBrightnessChange;
  final ValueChanged<double> onBrightnessEnd;

  const _LightCard({
    required this.device,
    required this.brightness,
    required this.onToggle,
    required this.onBrightnessChange,
    required this.onBrightnessEnd,
  });

  Color get _activeColor {
    final kelvin = device.attributes['colorTemp'] as int? ?? 0;
    if (kelvin > 0 && kelvin < 3500) return const Color(0xFFFFB347); // warm
    if (kelvin >= 5500) return const Color(0xFFB0D4FF);              // cool
    return AppColors.lightColor;
  }

  @override
  Widget build(BuildContext context) {
    final on    = device.isOn;
    final color = on ? _activeColor : context.tText2(0.2);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: on ? _activeColor.withValues(alpha: 0.35) : context.tText2(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: on ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Symbols.lightbulb, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (device.room.isNotEmpty)
                      Text(device.room,
                          style: TextStyle(
                              color: context.tText2(0.4), fontSize: 12)),
                  ],
                ),
              ),
              // Toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46, height: 26,
                  decoration: BoxDecoration(
                    color: on ? _activeColor : context.tText2(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20, height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (on) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Symbols.brightness_low,
                    color: context.tText2(0.3), size: 14),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: _activeColor,
                      inactiveTrackColor: _activeColor.withValues(alpha: 0.15),
                      thumbColor: _activeColor,
                      overlayColor: _activeColor.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: brightness.clamp(0, 100),
                      min: 0, max: 100, divisions: 20,
                      onChanged: onBrightnessChange,
                      onChangeEnd: onBrightnessEnd,
                    ),
                  ),
                ),
                Icon(Symbols.brightness_high,
                    color: context.tText2(0.5), size: 14),
                const SizedBox(width: 6),
                Text('${brightness.round()}%',
                    style: TextStyle(
                        color: context.tText2(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.lightbulb,
                size: 64, color: context.tText2(0.18)),
            const SizedBox(height: 20),
            Text(s.noLightsFound,
                style: TextStyle(
                    color: context.tText, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.lightsHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.tText2(0.45), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
