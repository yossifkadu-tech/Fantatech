import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// IntercomHubScreen — video doorbell & intercom management
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/device_edit_sheet.dart';
import '../cameras/mjpeg_view.dart';

class IntercomHubScreen extends StatelessWidget {
  const IntercomHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _IntercomView();
  }
}

class _IntercomView extends StatefulWidget {
  const _IntercomView();

  @override
  State<_IntercomView> createState() => _IntercomViewState();
}

class _IntercomViewState extends State<_IntercomView> {
  // Simulated incoming-ring state: deviceId of the ringing intercom, or null
  String? _ringingId;
  Timer?  _ringTimer;

  @override
  void dispose() {
    _ringTimer?.cancel();
    super.dispose();
  }

  List<Device> _intercoms(AppState state) => state.devices
      .where((d) => d.type == DeviceType.intercom)
      .toList();

  void _simulateRing(Device device) {
    HapticFeedback.heavyImpact();
    setState(() => _ringingId = device.id);
    _ringTimer?.cancel();
    // Auto-dismiss after 25 s if not answered
    _ringTimer = Timer(const Duration(seconds: 25), () {
      if (mounted) setState(() => _ringingId = null);
    });
  }

  void _answer(AppState state, Device device) {
    _ringTimer?.cancel();
    setState(() => _ringingId = null);
    // Turn device on = "answered / door opened"
    state.toggleDevice(device.id);
    _showAnswered(device);
  }

  void _decline() {
    _ringTimer?.cancel();
    setState(() => _ringingId = null);
  }

  void _unlock(AppState state, Device device) {
    state.toggleDevice(device.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<AppState>().strings.intercomUnlockDoor),
        backgroundColor: AppColors.secured,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAnswered(Device device) {
    final s = context.read<AppState>().strings;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Symbols.check_circle, color: Color(0xFF4CAF50), size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(
            device.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          )),
        ]),
        content: Text(
          s.intercomUnlockDoor,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.okButton, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final s        = state.strings;
    final intercoms = _intercoms(state);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            _TopBar(title: s.intercomTitle),

            // ── Ringing banner ─────────────────────────────────────────────
            if (_ringingId != null) ...[
              _RingingBanner(
                device: intercoms.firstWhere(
                  (d) => d.id == _ringingId,
                  orElse: () => intercoms.first,
                ),
                onAnswer: () => _answer(state, intercoms.firstWhere((d) => d.id == _ringingId!)),
                onDecline: _decline,
                s: s,
              ),
            ],

            // ── Device list ────────────────────────────────────────────────
            Expanded(
              child: intercoms.isEmpty
                  ? _EmptyState(hint: s.intercomHint, label: s.intercomNoDevices)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: intercoms.length,
                      itemBuilder: (ctx, i) => _IntercomCard(
                        device: intercoms[i],
                        isRinging: _ringingId == intercoms[i].id,
                        onRing: () => _simulateRing(intercoms[i]),
                        onUnlock: () => _unlock(state, intercoms[i]),
                        s: s,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
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
              width: 38, height: 38,
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
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ringing banner — appears at top when doorbell is pressed
// ─────────────────────────────────────────────────────────────────────────────
class _RingingBanner extends StatefulWidget {
  final Device device;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;
  final dynamic s;

  const _RingingBanner({
    required this.device,
    required this.onAnswer,
    required this.onDecline,
    required this.s,
  });

  @override
  State<_RingingBanner> createState() => _RingingBannerState();
}

class _RingingBannerState extends State<_RingingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF1A2E1A),
            const Color(0xFF2E3A1A),
            _pulse.value,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Color.lerp(AppColors.secured, AppColors.primary, _pulse.value)!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.secured.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.doorbell, color: AppColors.secured, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    widget.s.intercomRinging,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Decline
            GestureDetector(
              onTap: widget.onDecline,
              child: Container(
                width: 44, height: 44,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.unsecured,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Symbols.call_end, color: Colors.white, size: 20),
              ),
            ),
            // Answer
            GestureDetector(
              onTap: widget.onAnswer,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.secured,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Symbols.call, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intercom device card
// ─────────────────────────────────────────────────────────────────────────────
class _IntercomCard extends StatelessWidget {
  final Device device;
  final bool isRinging;
  final VoidCallback onRing;
  final VoidCallback onUnlock;
  final dynamic s;

  const _IntercomCard({
    required this.device,
    required this.isRinging,
    required this.onRing,
    required this.onUnlock,
    required this.s,
  });

  String? _mjpegUrl() => device.attributes['mjpegUrl'] as String?
      ?? device.attributes['snapshotUrl'] as String?;

  @override
  Widget build(BuildContext context) {
    final online = device.status == DeviceStatus.online;
    final mjpeg  = _mjpegUrl();

    return GestureDetector(
      onLongPress: () => showDeviceEditSheet(context,
          device: device, state: context.read<AppState>()),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRinging
              ? AppColors.secured.withValues(alpha: 0.7)
              : context.tText2(0.08),
          width: isRinging ? 2 : 1,
        ),
        boxShadow: isRinging
            ? [BoxShadow(
                color: AppColors.secured.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Camera preview (if available) ─────────────────────────────
          if (mjpeg != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 180,
                child: MjpegView(url: mjpeg),
              ),
            ),

          // ── Info & controls ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: online ? AppColors.secured : AppColors.unsecured,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.name,
                        style: TextStyle(
                          color: context.tText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (device.room.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.tText2(0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          device.room,
                          style: TextStyle(color: context.tText2(0.6), fontSize: 11),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  online ? s.camOnline : s.camOffline,
                  style: TextStyle(
                    color: online ? AppColors.secured : context.tText2(0.45),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Action buttons ──────────────────────────────────────
                Row(
                  children: [
                    // Ring button
                    Expanded(
                      child: _ActionButton(
                        icon: Symbols.doorbell,
                        label: s.intercomRing,
                        color: AppColors.primary,
                        onTap: online ? onRing : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Unlock door
                    Expanded(
                      child: _ActionButton(
                        icon: Symbols.lock_open,
                        label: s.intercomUnlockDoor,
                        color: AppColors.secured,
                        onTap: online ? onUnlock : null,
                      ),
                    ),
                  ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.13)
              : context.tText2(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.40)
                : context.tText2(0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? color : context.tText2(0.28), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : context.tText2(0.28),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String label;
  final String hint;
  const _EmptyState({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.doorbell,
              size: 64,
              color: context.tText2(0.18),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: context.tText2(0.55),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(color: context.tText2(0.35), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
