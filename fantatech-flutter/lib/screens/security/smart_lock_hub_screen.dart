import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';
import '../../l10n/strings.dart';
import '../../widgets/ft_button.dart';
import '../../widgets/ft_nav.dart';

class SmartLockHubScreen extends StatelessWidget {
  const SmartLockHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final locks = state.devices
        .where((d) => d.type == DeviceType.smartLock)
        .toList();

    final allLocked = locks.isNotEmpty && locks.every((d) => d.isOn);
    final anyUnlocked = locks.any((d) => !d.isOn);

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: s.smartLocksTitle),

            if (locks.isNotEmpty) ...[
              _StatusBanner(
                allLocked: allLocked,
                anyUnlocked: anyUnlocked,
                lockCount: locks.length,
                s: s,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: s.lockAll,
                        icon: Symbols.lock,
                        color: AppColors.secured,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          for (final lock in locks) {
                            if (!lock.isOn) state.toggleDevice(lock.id);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: s.unlockAll,
                        icon: Symbols.lock_open,
                        color: AppColors.unsecured,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _confirmUnlockAll(context, state, locks, s);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: locks.isEmpty
                  ? _EmptyState(s: s)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: locks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _LockCard(
                        device: locks[i],
                        s: s,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          if (locks[i].isOn) {
                            // Unlocking — confirm
                            _confirmUnlock(context, state, locks[i], s);
                          } else {
                            state.toggleDevice(locks[i].id);
                          }
                        },
                        onTap: () => _showLockDetail(context, state, locks[i], s),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnlock(
      BuildContext context, AppState state, Device lock, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ConfirmSheet(
        title: lock.name,
        message: '${s.unlockedStatus}?',
        icon: Symbols.lock_open,
        color: AppColors.unsecured,
        confirmLabel: s.unlockAll.replaceAll(' All', '').replaceAll(' הכל', ''),
        cancelLabel: s.cancel,
        onConfirm: () {
          Navigator.pop(ctx);
          state.toggleDevice(lock.id);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _confirmUnlockAll(
      BuildContext context, AppState state, List<Device> locks, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ConfirmSheet(
        title: s.unlockAll,
        message: '${locks.length} ${s.devicesUnit}',
        icon: Symbols.lock_open,
        color: AppColors.unsecured,
        confirmLabel: s.unlockAll,
        cancelLabel: s.cancel,
        onConfirm: () {
          Navigator.pop(ctx);
          for (final lock in locks) {
            if (lock.isOn) state.toggleDevice(lock.id);
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showLockDetail(
      BuildContext context, AppState state, Device lock, S s) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LockDetailSheet(device: lock, s: s, state: state),
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
  final bool allLocked;
  final bool anyUnlocked;
  final int lockCount;
  final S s;

  const _StatusBanner({
    required this.allLocked,
    required this.anyUnlocked,
    required this.lockCount,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final color = allLocked ? AppColors.secured : AppColors.unsecured;
    final icon  = DeviceIcons.lockIcon(allLocked);
    final label = allLocked ? s.lockedStatus : s.unlockedStatus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$lockCount ${s.devicesUnit}',
                    style: TextStyle(
                      color: context.tText2(0.5),
                      fontSize: 13,
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
// Action button (Lock All / Unlock All)
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
    return FtButton(
      label:       label,
      leadingIcon: icon,
      onTap:       onTap,
      variant:     FtButtonVariant.secondary,
      expand:      true,
      color:       color,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Lock card
// ─────────────────────────────────────────────────────────────
class _LockCard extends StatelessWidget {
  final Device device;
  final S s;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _LockCard({
    required this.device,
    required this.s,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = device.isOn;
    final isOnline = device.status == DeviceStatus.online;
    final color = isLocked ? AppColors.secured : AppColors.unsecured;
    final battery = device.battery;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.tText2(0.07)),
        ),
        child: Row(
          children: [
            // Lock icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                DeviceIcons.lockIcon(isLocked),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                        isLocked ? s.lockedStatus : s.unlockedStatus,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (battery != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          battery > 20
                              ? Symbols.battery_full
                              : Symbols.battery_alert,
                          size: 13,
                          color: battery > 20
                              ? context.tText2(0.4)
                              : AppColors.unsecured,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$battery%',
                          style: TextStyle(
                            color: context.tText2(0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Toggle button
            GestureDetector(
              onTap: isOnline ? onToggle : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52, height: 30,
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.secured
                      : context.tText2(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: isLocked
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        DeviceIcons.lockIcon(isLocked),
                        size: 12,
                        color: isLocked
                            ? AppColors.secured
                            : context.tText2(0.5),
                      ),
                    ),
                  ),
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
// Lock detail sheet
// ─────────────────────────────────────────────────────────────
class _LockDetailSheet extends StatelessWidget {
  final Device device;
  final S s;
  final AppState state;

  const _LockDetailSheet({
    required this.device,
    required this.s,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = device.isOn;
    final color = isLocked ? AppColors.secured : AppColors.unsecured;
    final battery = device.battery;
    final entityId = device.attributes['entityId'] as String?;
    final room = device.room.isNotEmpty ? device.room : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.tText2(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(
              DeviceIcons.lockIcon(isLocked),
              color: color, size: 36,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            device.name,
            style: TextStyle(
              color: context.tText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLocked ? s.lockedStatus : s.unlockedStatus,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Info rows
          _InfoRow(
            icon: Symbols.room,
            label: room,
            context: context,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Symbols.wifi,
            label: device.status == DeviceStatus.online
                ? s.activeStatus
                : s.offlineLabel,
            valueColor: device.status == DeviceStatus.online
                ? AppColors.secured
                : AppColors.statusOffline,
            context: context,
          ),
          if (battery != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Symbols.battery_full,
              label: '$battery%',
              valueColor: battery > 20 ? AppColors.secured : AppColors.unsecured,
              context: context,
            ),
          ],
          if (entityId != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Symbols.tag,
              label: entityId,
              context: context,
            ),
          ],
          const SizedBox(height: 24),

          // Big toggle button
          FtButton(
            label:       isLocked
                ? s.unlockAll.replaceAll(' All', '').replaceAll(' הכל', '')
                : s.lockAll.replaceAll(' All', '').replaceAll(' הכל', ''),
            leadingIcon: isLocked ? Symbols.lock_open : Symbols.lock,
            onTap:       () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              state.toggleDevice(device.id);
            },
            color:       isLocked ? AppColors.unsecured : AppColors.secured,
            expand:      true,
            size:        FtButtonSize.lg,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? valueColor;
  final BuildContext context;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.context,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.tText2(0.45)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: valueColor ?? context.tText,
              fontSize: 13,
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
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
                Symbols.lock,
                size: 38,
                color: context.tText2(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.noLocksFound,
              style: TextStyle(
                color: context.tText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.lockHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tText2(0.45),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Confirm sheet
// ─────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.tText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: context.tText2(0.5), fontSize: 14),
          ),
          const SizedBox(height: 24),
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
              const SizedBox(width: 12),
              Expanded(
                child: FtButton(
                  label:  confirmLabel,
                  onTap:  onConfirm,
                  expand: true,
                  color:  color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
