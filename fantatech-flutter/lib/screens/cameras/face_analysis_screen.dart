import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// FaceAnalysisScreen — history of all face detection results
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_state.dart';
import '../../models/face_analysis.dart';
import '../../theme/app_theme.dart';

class FaceAnalysisScreen extends StatelessWidget {
  const FaceAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final s       = state.strings;
    final history = state.faceAnalysisHistory;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: context.tText2(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.chevron_right,
                          color: context.tText, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.faceAnalysisTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(s.faceAnalysisSubtitle,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (history.isNotEmpty)
                    GestureDetector(
                      onTap: () => _confirmClear(context, state),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.statusAlarm.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.statusAlarm.withValues(alpha: 0.3)),
                        ),
                        child: Text(s.clear,
                            style: const TextStyle(
                                color: AppColors.statusAlarm, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Stats row ────────────────────────────────────────
            if (history.isNotEmpty) _StatsRow(history: history),

            const SizedBox(height: 8),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: history.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) =>
                          _ResultCard(result: history[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    final s = context.read<AppState>().strings;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.tCard,
        title: Text(s.clearHistory,
            style: TextStyle(color: context.tText)),
        content: Text(s.clearHistoryConfirm,
            style: TextStyle(color: context.tText2(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel,
                style: TextStyle(color: context.tText2(0.54))),
          ),
          TextButton(
            onPressed: () {
              state.clearFaceAnalysisHistory();
              Navigator.pop(context);
            },
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.statusAlarm)),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<FaceAnalysisResult> history;
  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final str        = context.select((AppState st) => st.strings);
    final totalFaces = history.fold(0, (s, r) => s + r.faceCount);
    final cameras    = history.map((r) => r.cameraId).toSet().length;
    final alerts     = history
        .where((r) => r.alertLevel == FaceAlertLevel.high)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatChip(label: str.statScans, value: '${history.length}',
              color: AppColors.primary),
          const SizedBox(width: 8),
          _StatChip(label: str.statFacesDetected, value: '$totalFaces',
              color: const Color(0xFF00C896)),
          const SizedBox(width: 8),
          _StatChip(label: str.camerasTitle, value: '$cameras',
              color: const Color(0xFF9C7AFF)),
          if (alerts > 0) ...[
            const SizedBox(width: 8),
            _StatChip(label: str.statAlerts, value: '$alerts',
                color: AppColors.statusAlarm),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label, required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final FaceAnalysisResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final s     = context.select((AppState st) => st.strings);
    final level = result.alertLevel;
    final time  = result.timestamp;
    final timeStr =
        '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}  '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: level.color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                // Thumbnail or icon
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: level.color.withValues(alpha: 0.3)),
                  ),
                  child: result.thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(result.thumbnail!,
                              fit: BoxFit.cover))
                      : Icon(Symbols.face,
                          color: level.color, size: 26),
                ),
                const SizedBox(width: 12),

                // Camera + summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.cameraName,
                          style: TextStyle(
                              color: context.tText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Symbols.access_time,
                            color: context.tText2(0.38), size: 11),
                        const SizedBox(width: 4),
                        Text(timeStr,
                            style: TextStyle(
                                color: context.tText2(0.38), fontSize: 11)),
                      ]),
                    ],
                  ),
                ),

                // Alert level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: level.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: level.color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('${result.faceCount}',
                          style: TextStyle(
                              color: level.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text(s.faces,
                          style: TextStyle(
                              color: level.color.withValues(alpha: 0.7),
                              fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Face details ─────────────────────────────────────
          if (result.faces.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.tText2(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: result.faces.asMap().entries.map((e) {
                  final idx  = e.key;
                  final face = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${idx + 1}',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FaceTag(
                          icon: Symbols.directions,
                          label: face.gazeDirection,
                        ),
                        const SizedBox(width: 6),
                        if (face.isSmiling)
                          _FaceTag(
                            icon: Symbols.sentiment_very_satisfied,
                            label: s.smiling,
                            color: const Color(0xFFFFD600),
                          ),
                        if (!face.eyesOpen)
                          _FaceTag(
                            icon: Symbols.remove_red_eye,
                            label: s.eyesClosed,
                            color: Colors.orange,
                          ),
                        const Spacer(),
                        Text(
                          '${face.boundingBox.width.toInt()}×${face.boundingBox.height.toInt()}px',
                          style: TextStyle(
                              color: context.tText2(0.24), fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Icon(Symbols.search_off,
                    color: context.tText2(0.24), size: 14),
                const SizedBox(width: 6),
                Text(s.noFacesInFrame,
                    style:
                        TextStyle(color: context.tText2(0.24), fontSize: 12)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _FaceTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FaceTag({
    required this.icon,
    required this.label,
    this.color = Colors.white54,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(color: color, fontSize: 11)),
    ]);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Symbols.face,
                color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 16),
          Text(s.noAnalysesYet,
              style: TextStyle(
                  color: context.tText2(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            s.faceAnalysisHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tText2(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
