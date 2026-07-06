import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_nav.dart';
import '../../l10n/strings.dart';

class BlindHubScreen extends StatelessWidget {
  const BlindHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final blinds = state.devices
        .where((d) => d.type == DeviceType.blind)
        .toList();

    final allOpen   = blinds.isNotEmpty && blinds.every((d) => d.isOn);
    final allClosed = blinds.isNotEmpty && blinds.every((d) => !d.isOn);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.blindsHubTitle),

            if (blinds.isNotEmpty) ...[
              _StatusBanner(
                allOpen: allOpen,
                allClosed: allClosed,
                count: blinds.length,
                s: s,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: s.openAll,
                        icon: Symbols.expand_less,
                        color: const Color(0xFF8E63CE),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          for (final b in blinds) {
                            if (!b.isOn) state.toggleDevice(b.id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: s.coverStop,
                        icon: Symbols.stop,
                        color: AppColors.statusWarning,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          for (final b in blinds) {
                            state.stopCover(b.id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: s.closeAll,
                        icon: Symbols.expand_more,
                        color: context.tText2(0.6),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          for (final b in blinds) {
                            if (b.isOn) state.toggleDevice(b.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: blinds.isEmpty
                  ? _EmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      addAutomaticKeepAlives: false,
                      itemCount: blinds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _BlindCard(
                        device: blinds[i],
                        s: s,
                        state: state,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const FtBackButton(),
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
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status banner
// ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final bool allOpen;
  final bool allClosed;
  final int count;
  final S s;

  const _StatusBanner({
    required this.allOpen,
    required this.allClosed,
    required this.count,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final color = allOpen
        ? const Color(0xFF8E63CE)
        : allClosed
            ? context.tText2(0.45)
            : AppColors.statusWarning;
    final icon = allOpen
        ? Symbols.blinds
        : allClosed
            ? Symbols.blinds_closed
            : Symbols.blinds;
    final label = allOpen
        ? s.coverOpen.replaceAll('▲  ', '')
        : allClosed
            ? s.coverClose.replaceAll('▼  ', '')
            : s.coverStop.replaceAll('■  ', '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$count ${s.devicesUnit}',
                      style: TextStyle(
                          color: context.tText2(0.45), fontSize: 12)),
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
// Action button
// ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Blind card
// ─────────────────────────────────────────────────────────────
class _BlindCard extends StatefulWidget {
  final Device device;
  final S s;
  final AppState state;

  const _BlindCard({
    required this.device,
    required this.s,
    required this.state,
  });

  @override
  State<_BlindCard> createState() => _BlindCardState();
}

class _BlindCardState extends State<_BlindCard> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = _currentPosition.toDouble();
  }

  @override
  void didUpdateWidget(_BlindCard old) {
    super.didUpdateWidget(old);
    if (old.device.attributes['position'] != widget.device.attributes['position']) {
      _sliderValue = _currentPosition.toDouble();
    }
  }

  int get _currentPosition {
    final pos = widget.device.attributes['position'];
    if (pos is int) return pos;
    if (pos is double) return pos.round();
    return widget.device.isOn ? 100 : 0;
  }

  Color get _accentColor => const Color(0xFF8E63CE);

  @override
  Widget build(BuildContext context) {
    final device  = widget.device;
    final s       = widget.s;
    final isOpen  = device.isOn;
    final isOnline = device.status == DeviceStatus.online;
    final hasPosition = device.attributes.containsKey('position') || device.id.startsWith('ha_');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isOpen ? Symbols.blinds : Symbols.blinds_closed,
                  color: _accentColor, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.secured : AppColors.statusOffline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasPosition
                              ? s.positionFmt.replaceAll('{n}', '$_currentPosition')
                              : (isOpen
                                  ? s.coverOpen.replaceAll('▲  ', '')
                                  : s.coverClose.replaceAll('▼  ', '')),
                          style: TextStyle(
                              color: context.tText2(0.5),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Room label
              if (device.room.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.tText2(0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(device.room,
                      style: TextStyle(
                          color: context.tText2(0.5),
                          fontSize: 11)),
                ),
            ],
          ),

          // ── Position slider ──────────────────────────────────────
          if (hasPosition) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Symbols.expand_more,
                    size: 16, color: context.tText2(0.35)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accentColor,
                      inactiveTrackColor: context.tText2(0.12),
                      thumbColor: _accentColor,
                      overlayColor: _accentColor.withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _sliderValue.clamp(0, 100),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (v) => setState(() => _sliderValue = v),
                      onChangeEnd: (v) {
                        widget.state.setCoverPosition(device.id, v.round());
                      },
                    ),
                  ),
                ),
                Icon(Symbols.expand_less,
                    size: 16, color: context.tText2(0.35)),
              ],
            ),
          ],

          // ── Control buttons ──────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CtrlBtn(
                  label: s.coverOpen.replaceAll('▲  ', ''),
                  icon: Symbols.expand_less,
                  color: _accentColor,
                  enabled: isOnline,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (!device.isOn) widget.state.toggleDevice(device.id);
                    widget.state.setCoverPosition(device.id, 100);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CtrlBtn(
                  label: s.coverStop.replaceAll('■  ', ''),
                  icon: Symbols.stop,
                  color: AppColors.statusWarning,
                  enabled: isOnline,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.state.stopCover(device.id);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CtrlBtn(
                  label: s.coverClose.replaceAll('▼  ', ''),
                  icon: Symbols.expand_more,
                  color: context.tText2(0.55),
                  enabled: isOnline,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (device.isOn) widget.state.toggleDevice(device.id);
                    widget.state.setCoverPosition(device.id, 0);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final S s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.tText2(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.blinds,
                size: 38,
                color: context.tText2(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.noBlindsFound,
                style: TextStyle(
                    color: context.tText,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.blindsHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.tText2(0.45),
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}
