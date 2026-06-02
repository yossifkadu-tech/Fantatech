// ─────────────────────────────────────────────────────────────────────────────
// GatewayHubScreen — main gateway management page.
//
// Layout:
//   ┌────────────────────────────────────────────────────┐
//   │  ← header + subtitle                               │
//   ├────────────────────────────────────────────────────┤
//   │  Connected gateways (horizontal cards, if any)     │
//   ├────────────────────────────────────────────────────┤
//   │  "Add a gateway" grid — all supported types        │
//   └────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_model.dart';
import '../../services/gateways/gateway_types.dart';
import '../../theme/app_theme.dart';
import 'gateway_connect_sheet.dart';

class GatewayHubScreen extends StatelessWidget {
  const GatewayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GatewayManager>();
    final state   = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white54, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('גשרים ומרכזי בקרה',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   20,
                              fontWeight: FontWeight.bold,
                            )),
                          Text('חבר רכזות Zigbee, Z-Wave, WiFi וענן',
                            style: TextStyle(
                              color:    Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Connected gateways ─────────────────────────────────────────
            if (manager.connections.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text('מחובר',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:         const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:       manager.connections.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) => _ConnectedCard(
                      conn:     manager.connections[i],
                      onImport: () => _importDevices(ctx, manager, state,
                                         manager.connections[i]),
                      onRemove: () => _confirmDisconnect(ctx, manager,
                                         manager.connections[i]),
                    ),
                  ),
                ),
              ),
            ],

            // ── Section header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(children: [
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  const Text('הוסף גשר',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
                  const Spacer(),
                  Text('${GatewayRegistry.all.length} סוגים',
                    style: TextStyle(
                      color:    Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    )),
                ]),
              ),
            ),

            // ── Gateway type grid ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing:  10,
                  childAspectRatio: 1.35,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final meta = GatewayRegistry.all[i];
                    return _GatewayTypeCard(
                      meta:    meta,
                      already: manager.connections
                          .any((c) => c.type == meta.type),
                      onTap: () => _openConnectSheet(ctx, meta),
                    );
                  },
                  childCount: GatewayRegistry.all.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _openConnectSheet(BuildContext context, GatewayMeta meta) {
    showModalBottomSheet(
      context:          context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GatewayConnectSheet(meta: meta),
    );
  }

  Future<void> _importDevices(
    BuildContext context,
    GatewayManager manager,
    AppState state,
    GatewayConnection conn,
  ) async {
    final devices = await manager.importDevices(conn.id);
    if (!context.mounted) return;

    int added = 0;
    for (final d in devices) {
      if (!state.devices.any((e) => e.id == d.id)) {
        state.addDevice(d);
        added++;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added > 0
          ? 'נוספו $added מכשירים מ-${conn.displayName}'
          : 'כל המכשירים כבר קיימים'),
      backgroundColor: added > 0 ? AppColors.secured : Colors.white24,
      duration: const Duration(seconds: 3),
    ));
  }

  void _confirmDisconnect(
      BuildContext context, GatewayManager manager, GatewayConnection conn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('נתק "${conn.displayName}"?',
            style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('המכשירים שיובאו יישארו, אך לא ניתן יהיה לייבא עוד.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('ביטול',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  manager.disconnect(conn.id);
                },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color:        AppColors.unsecured.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(
                        color: AppColors.unsecured.withValues(alpha: 0.35))),
                  child: Center(child: Text('נתק',
                    style: const TextStyle(
                      color:      AppColors.unsecured,
                      fontSize:   14,
                      fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Connected gateway card (horizontal scroll)
// ─────────────────────────────────────────────────────────────
class _ConnectedCard extends StatelessWidget {
  final GatewayConnection conn;
  final VoidCallback onImport;
  final VoidCallback onRemove;

  const _ConnectedCard({
    required this.conn,
    required this.onImport,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final meta  = GatewayRegistry.forType(conn.type);
    final color = meta.color;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
          color: conn.isConnected
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(meta.icon, color: color, size: 16),
            ),
            const Spacer(),
            // Status dot
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: conn.isConnected ? AppColors.secured : Colors.white24,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close,
                  color: Colors.white.withValues(alpha: 0.25), size: 14),
            ),
          ]),
          const SizedBox(height: 8),
          Text(conn.displayName,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
            maxLines:  1,
            overflow:  TextOverflow.ellipsis),
          Text('${conn.deviceCount} מכשירים',
            style: TextStyle(
              color:    Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            )),
          const Spacer(),
          GestureDetector(
            onTap: onImport,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(
                    color: color.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text('ייבא מכשירים',
                  style: TextStyle(
                    color:      color,
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                  )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gateway type card (grid)
// ─────────────────────────────────────────────────────────────
class _GatewayTypeCard extends StatelessWidget {
  final GatewayMeta meta;
  final bool        already;
  final VoidCallback onTap;

  const _GatewayTypeCard({
    required this.meta,
    required this.already,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = meta.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(
            color: already
                ? AppColors.secured.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon, color: color, size: 18),
              ),
              const Spacer(),
              if (already)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:        AppColors.secured.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('מחובר',
                    style: TextStyle(
                      color:    AppColors.secured,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    )),
                )
              else if (meta.isCloud)
                Icon(Icons.cloud_outlined,
                    color: Colors.white.withValues(alpha: 0.2), size: 14)
              else
                Icon(Icons.wifi_outlined,
                    color: Colors.white.withValues(alpha: 0.2), size: 14),
            ]),
            const SizedBox(height: 8),
            Text(meta.name,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(meta.subtitle,
              style: TextStyle(
                color:    Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
