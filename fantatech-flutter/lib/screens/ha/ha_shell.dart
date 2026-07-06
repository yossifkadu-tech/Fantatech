import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaShell — מעטפת ניווט ראשית לממשק Home Assistant
// 6 לשוניות: Dashboard | Rooms | Security | Cameras | Automations | Settings
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ha/ha_provider.dart';
import '../../services/ha/ha_config.dart';
import 'ha_dashboard_screen.dart';
import 'ha_rooms_screen.dart';
import 'ha_security_screen.dart';
import 'ha_cameras_screen.dart';
import 'ha_automations_screen.dart';
import 'ha_settings_screen.dart';

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF30363D);
const _orange  = Color(0xFFFF6B00);
const _text2   = Color(0xFF8B949E);

class HaShell extends StatefulWidget {
  /// אם מועבר config, מתחבר אוטומטית בהפעלה
  final HaConfig? initialConfig;

  const HaShell({super.key, this.initialConfig});

  @override
  State<HaShell> createState() => _HaShellState();
}

class _HaShellState extends State<HaShell> {
  int _index = 0;

  static const _screens = [
    HaDashboardScreen(),
    HaRoomsScreen(),
    HaSecurityScreen(),
    HaCamerasScreen(),
    HaAutomationsScreen(),
    HaSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HaProvider>().connect(widget.initialConfig!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ha = context.watch<HaProvider>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_ios, size: 18, color: Color(0xFFE6EDF3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Symbols.home, color: _orange, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('FantaTech HA',
              style: TextStyle(color: Color(0xFFE6EDF3), fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ]),
        actions: [
          // Status dot
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ha.isConnected
                    ? const Color(0xFF3FB950).withValues(alpha: 0.15)
                    : const Color(0xFFF85149).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ha.isConnected
                      ? const Color(0xFF3FB950).withValues(alpha: 0.4)
                      : const Color(0xFFF85149).withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ha.isConnected
                        ? const Color(0xFF3FB950)
                        : const Color(0xFFF85149)),
                ),
                const SizedBox(width: 5),
                Text(ha.isConnected ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: ha.isConnected
                          ? const Color(0xFF3FB950)
                          : const Color(0xFFF85149),
                      fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _HaBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _HaBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _HaBottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Symbols.dashboard, Symbols.dashboard, 'דשבורד'),
      _NavItem(Symbols.meeting_room, Symbols.meeting_room, 'חדרים'),
      _NavItem(Symbols.shield, Symbols.shield, 'אבטחה'),
      _NavItem(Symbols.videocam, Symbols.videocam, 'מצלמות'),
      _NavItem(Symbols.auto_awesome, Symbols.auto_awesome, 'אוטומציות'),
      _NavItem(Symbols.settings, Symbols.settings, 'הגדרות'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final selected = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected ? _orange : _text2,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: TextStyle(
                            color: selected ? _orange : _text2,
                            fontSize: 9,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
