import 'package:material_symbols_icons/symbols.dart';
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
import '../../services/gateways/clients/dirigera_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ft_button.dart';
import 'gateway_connect_sheet.dart';
import '../settings/ha_integration_screen.dart';

class GatewayHubScreen extends StatelessWidget {
  const GatewayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GatewayManager>();
    final state   = context.watch<AppState>();
    final s       = state.strings;

    return Scaffold(
      backgroundColor: context.tBg,
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
                          color: context.tText2(0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Symbols.arrow_back_ios_new,
                            color: context.tText2(0.54), size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.gatewayHubTitle,
                            style: TextStyle(
                              color:      context.tText,
                              fontSize:   20,
                              fontWeight: FontWeight.bold,
                            )),
                          Text(s.gatewayHubSubtitle,
                            style: TextStyle(
                              color:    context.tText2(0.4),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(s.connected,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final conn in manager.connections) ...[
                        _ConnectedCard(
                          conn:     conn,
                          onImport: () => _importDevices(context, manager, state, conn),
                          onRemove: () => _confirmDisconnect(context, manager, conn),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // ── Section header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(children: [
                  Icon(Symbols.add_circle,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(s.addGateway,
                    style: TextStyle(
                      color:      context.tText,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
                  const Spacer(),
                  Text(s.gatewayTypesFmt.replaceAll('{n}', '${GatewayRegistry.all.length}'),
                    style: TextStyle(
                      color:    context.tText2(0.3),
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
    // HA gets its own dedicated screen instead of the generic sheet
    if (meta.type == GatewayType.homeAssistant) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HaIntegrationScreen()));
      return;
    }
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

    final s = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added > 0
          ? s.devicesImportedFmt.replaceAll('{n}', '$added').replaceAll('{name}', conn.displayName)
          : s.allDevicesExist),
      backgroundColor: added > 0 ? AppColors.secured : context.tText2(0.24),
      duration: const Duration(seconds: 3),
    ));

    // Diagnostic: show exactly what the DIRIGERA reported (helps identify
    // sensors that aren't mapped / aren't paired to the hub).
    if (conn.type == GatewayType.dirigera &&
        DIRIGERAGatewayClient.lastRawSummary.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.tCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.diagnosisTitle,
              style: TextStyle(color: context.tText, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(DIRIGERAGatewayClient.lastRawSummary,
                style: TextStyle(color: context.tText2(0.8), fontSize: 13, height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.close),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDisconnect(
      BuildContext context, GatewayManager manager, GatewayConnection conn) {
    final s = context.read<AppState>().strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: context.tText2(0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.disconnectConfirmFmt.replaceAll('{name}', conn.displayName),
            style: TextStyle(
              color: context.tText, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.importedDevicesNote,
            style: TextStyle(color: context.tText2(0.4),
                fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: FtButton(
                label:   s.cancel,
                variant: FtButtonVariant.secondary,
                onTap:   () => Navigator.pop(ctx),
                expand:  true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FtButton(
                label:   s.disconnect,
                variant: FtButtonVariant.danger,
                onTap:   () {
                  Navigator.pop(ctx);
                  manager.disconnect(conn.id);
                },
                expand:  true,
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
    final s     = context.select((AppState st) => st.strings);
    final meta  = GatewayRegistry.forType(conn.type);
    final color = meta.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        context.tCard,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
          color: conn.isConnected
              ? color.withValues(alpha: 0.3)
              : context.tText2(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conn.displayName,
                    style: TextStyle(
                      color:      context.tText,
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conn.isConnected
                            ? AppColors.secured
                            : context.tText2(0.24),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(s.deviceCountFmt.replaceAll('{n}', '${conn.deviceCount}'),
                      style: TextStyle(
                        color: context.tText2(0.5), fontSize: 11)),
                  ]),
                ],
              ),
            ),
            // Remove — proper 40px tap target
            IconButton(
              onPressed: onRemove,
              icon: Icon(Symbols.close, color: context.tText2(0.4), size: 20),
              tooltip: s.disconnect,
            ),
          ]),
          const SizedBox(height: 12),
          // Prominent, full-width import button (44px tap target)
          FtButton(
            label:       s.importDevices,
            leadingIcon: Symbols.download,
            onTap:       onImport,
            expand:      true,
            color:       color,
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
    final s     = context.select((AppState st) => st.strings);
    final color = meta.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        context.tCard,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(
            color: already
                ? AppColors.secured.withValues(alpha: 0.3)
                : context.tText2(0.07),
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
                  child: Text(s.connected,
                    style: const TextStyle(
                      color:    AppColors.secured,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    )),
                )
              else if (meta.isCloud)
                Icon(Symbols.cloud,
                    color: context.tText2(0.2), size: 14)
              else
                Icon(Symbols.wifi,
                    color: context.tText2(0.2), size: 14),
            ]),
            const SizedBox(height: 8),
            Text(meta.name,
              style: TextStyle(
                color:      context.tText,
                fontSize:   13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(meta.subtitle,
              style: TextStyle(
                color:    context.tText2(0.35),
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
