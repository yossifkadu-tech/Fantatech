import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';

class ActivityLogSection extends StatelessWidget {
  /// Maximum number of events to show in the collapsed view.
  final int maxItems;

  const ActivityLogSection({super.key, this.maxItems = 5});

  @override
  Widget build(BuildContext context) {
    final allEvents = context.watch<AppState>().events;

    // Most-recent first, capped at maxItems
    final events = ([...allEvents]
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)))
        .take(maxItems)
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Symbols.history,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEAEDF2)),

          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            // ── Timeline rows ─────────────────────────────────
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (_, i) => _EventRow(
                event: events[i],
                isLast: i == events.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Single event row ─────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  final SecurityEvent event;
  final bool isLast;

  const _EventRow({required this.event, required this.isLast});

  static IconData _iconFor(String description) {
    final d = description.toLowerCase();
    if (d.contains('door'))       return Symbols.door_front;
    if (d.contains('motion'))     return Symbols.directions_run;
    if (d.contains('window'))     return Symbols.window;
    if (d.contains('arm'))        return Symbols.shield;
    if (d.contains('disarm'))     return Symbols.lock_open;
    if (d.contains('smoke'))      return Symbols.smoke_free;
    if (d.contains('water'))      return Symbols.water_drop;
    if (d.contains('glass'))      return Symbols.crisis_alert;
    if (d.contains('lock'))       return Symbols.lock;
    if (d.contains('camera'))     return Symbols.videocam;
    if (d.contains('panic'))      return Symbols.warning;
    return Symbols.circle_notifications;
  }

  static String _timeLabel(DateTime dt) {
    final h   = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  static String _relativeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = event.isAlert ? AppColors.alert : AppColors.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time column ──────────────────────────────────────
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 18),
              child: Text(
                _timeLabel(event.timestamp),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          // ── Timeline line + dot ──────────────────────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: event.isAlert
                        ? [
                            BoxShadow(
                              color: AppColors.alert.withValues(alpha: 0.40),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFEAEDF2),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 11, bottom: isLast ? 16 : 12, right: 18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _iconFor(event.description),
                      color: dotColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _relativeLabel(event.timestamp),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.isAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.alert.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Alert',
                        style: TextStyle(
                          color: AppColors.alert,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
