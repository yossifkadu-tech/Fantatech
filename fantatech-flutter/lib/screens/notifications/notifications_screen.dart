import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/device.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/device_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  // 0=all, 1=alerts, 2=cameras, 3=automations
  int _filterIndex = 0;

  // ── Convert AppNotification → local UI model ──────────────────
  static IconData _iconForType(DeviceType type) => DeviceIcons.icon(type);

  static Color _colorForType(DeviceType type) => DeviceIcons.color(type);

  static String _relativeTime(DateTime dt, S s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return s.timeNow;
    if (diff.inMinutes < 60) {
      return s.timeMinAgo.replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff.inHours < 24) {
      return s.timeHrAgo.replaceAll('{n}', '${diff.inHours}');
    }
    return s.timeDayAgo.replaceAll('{n}', '${diff.inDays}');
  }

  _Notification _toUiNotif(AppNotification n, S s) => _Notification(
    id: n.id,
    title: s.deviceConnectedFmt.replaceAll('{name}', n.title),
    time: _relativeTime(n.timestamp, s),
    icon: _iconForType(n.deviceType),
    iconColor: _colorForType(n.deviceType),
    type: _NotifType.alert,
    isRead: n.isRead,
  );

  List<_Notification> _buildList(List<AppNotification> source, S s) =>
      source.map((n) => _toUiNotif(n, s)).toList();

  List<_Notification> _filtered(List<_Notification> all) {
    switch (_filterIndex) {
      case 1:
        return all.where((n) => n.type == _NotifType.alert).toList();
      case 2:
        return all.where((n) => n.type == _NotifType.camera).toList();
      case 3:
        return all.where((n) => n.type == _NotifType.automation).toList();
      default:
        return all;
    }
  }

  void _markAllRead() =>
      context.read<AppState>().markAllNotificationsRead();

  void _markRead(String id) =>
      context.read<AppState>().markNotificationRead(id);

  void _dismiss(String id) =>
      context.read<AppState>().dismissNotification(id);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final allNotifications = _buildList(state.notifications, s);
    final filtered = _filtered(allNotifications);
    final unreadCount = allNotifications.where((n) => !n.isRead).length;
    final filters = [s.allNotif, s.alertsNotif, s.camerasNotif, s.automationsTitle];

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: s.notificationsTitle,
              unreadCount: unreadCount,
              onMenuTap: () => _showFilterMenu(context, s),
            ),

            const SizedBox(height: 4),

            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final selected = _filterIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : context.tText2(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : context.tText2(0.1),
                        ),
                      ),
                      child: Text(
                        filters[i],
                        style: TextStyle(
                          color: selected
                              ? context.tText
                              : context.tText2(0.55),
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final n = filtered[i];
                        return _SwipeableNotifCard(
                          notification: n,
                          onRead: () => _markRead(n.id),
                          onDismiss: () => _dismiss(n.id),
                        );
                      },
                    ),
            ),

            if (unreadCount > 0)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _markAllRead,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.tText,
                      side: BorderSide(
                          color: context.tText2(0.18)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      s.markAllRead,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, S s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.settingsTitle,
              style: TextStyle(
                color: context.tText2(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _MenuOption(
              icon: Symbols.done_all,
              label: s.markAllRead,
              onTap: () {
                Navigator.pop(context);
                _markAllRead();
              },
            ),
            const SizedBox(height: 10),
            _MenuOption(
              icon: Symbols.delete,
              label: s.delete,
              color: AppColors.unsecured,
              onTap: () {
                Navigator.pop(context);
                context.read<AppState>().clearNotifications();
              },
            ),
            const SizedBox(height: 8),
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
  final int unreadCount;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.title,
    required this.unreadCount,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.tText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.unsecured,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: context.tText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                  Symbols.more_vert, color: context.tText, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Swipeable notification card
// ─────────────────────────────────────────────────────────────
class _SwipeableNotifCard extends StatelessWidget {
  final _Notification notification;
  final VoidCallback onRead;
  final VoidCallback onDismiss;

  const _SwipeableNotifCard({
    required this.notification,
    required this.onRead,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 20),
        decoration: BoxDecoration(
          color: AppColors.unsecured.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Symbols.delete,
            color: AppColors.unsecured, size: 22),
      ),
      child: GestureDetector(
        onTap: onRead,
        child: _NotifCard(notification: notification),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification card
// ─────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final _Notification notification;
  const _NotifCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.isRead
            ? context.tCard
            : context.tCard.withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n.isRead
              ? context.tText2(0.07)
              : n.iconColor.withValues(alpha: 0.25),
          width: n.isRead ? 1 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(n.icon, color: n.iconColor, size: 22),
              ),
              if (!n.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.tCard, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: TextStyle(
                    color: n.isRead
                        ? context.tText2(0.7)
                        : context.tText,
                    fontSize: 14,
                    fontWeight: n.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n.time,
                  style: TextStyle(
                    color: context.tText2(0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          if (n.hasThumbnail)
            _NotifThumbnail(seed: n.thumbnailSeed)
          else if (n.badge != null)
            _BadgeWidget(badge: n.badge!),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Thumbnail (simulated camera snapshot)
// ─────────────────────────────────────────────────────────────
class _NotifThumbnail extends StatelessWidget {
  final int seed;
  const _NotifThumbnail({required this.seed});

  @override
  Widget build(BuildContext context) {
    final colors = seed == 1
        ? [const Color(0xFF0D1F0D), const Color(0xFF1A3020)]
        : [const Color(0xFF0D0F1A), const Color(0xFF1A1D30)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 58,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (seed == 1) ...[
              Positioned(
                bottom: 0,
                left: 5,
                child: Container(
                  width: 8,
                  height: 20,
                  color: const Color(0xFF060C08),
                ),
              ),
              Positioned(
                top: 3,
                right: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 22,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.tText2(0.1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],

            Icon(
              Symbols.videocam,
              color: context.tText2(0.25),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Badge widget (text or icon)
// ─────────────────────────────────────────────────────────────
class _BadgeWidget extends StatelessWidget {
  final _BadgeData badge;
  const _BadgeWidget({required this.badge});

  @override
  Widget build(BuildContext context) {
    if (badge.text != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: badge.color.withValues(alpha: 0.25)),
        ),
        child: Text(
          badge.text!,
          style: TextStyle(
            color: badge.color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(badge.icon!, color: badge.color, size: 19),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.notifications_none,
            color: context.tText2(0.2),
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            s.noNotifications,
            style: TextStyle(
              color: context.tText2(0.35),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom menu option
// ─────────────────────────────────────────────────────────────
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────
enum _NotifType { alert, camera, automation }

class _Notification {
  final String id;
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final _NotifType type;
  bool isRead;
  final bool hasThumbnail = false;
  final int thumbnailSeed = 0;
  final _BadgeData? badge = null;

  _Notification({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.type,
    required this.isRead,
  });
}

class _BadgeData {
  final String? text = null;
  final IconData? icon = null;
  final Color color;

  const _BadgeData({required this.color});
}
