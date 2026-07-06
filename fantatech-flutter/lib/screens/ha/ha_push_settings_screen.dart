import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HaPushSettingsScreen — configure push notifications for HA events
//
//  • Toggle each built-in rule on/off
//  • Copy FCM token to clipboard
//  • Register app with HA mobile_app integration (one-tap)
//  • Send a test notification
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/ha/ha_provider.dart';
import '../../services/push/ha_push_service.dart';
import '../../theme/app_theme.dart';

class HaPushSettingsScreen extends StatefulWidget {
  const HaPushSettingsScreen({super.key});

  @override
  State<HaPushSettingsScreen> createState() => _HaPushSettingsScreenState();
}

class _HaPushSettingsScreenState extends State<HaPushSettingsScreen> {
  bool _registering = false;
  String? _toast;

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _registerWithHa() async {
    final ha  = context.read<HaProvider>();
    final cfg = ha.config;
    if (cfg == null) { _showToast('לא מחובר ל-HA'); return; }

    setState(() => _registering = true);
    final id = await HaPushService.instance.registerWithHa(
      baseUrl:    cfg.baseUrl,
      token:      cfg.token,
      deviceName: 'FantaTech',
    );
    if (mounted) {
      setState(() => _registering = false);
      if (id != null) {
        _showToast('נרשם! Webhook: $id');
      } else {
        _showToast('הרישום נכשל — בדוק שה-mobile_app integration מותקן ב-HA');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final push = context.watch<HaPushService>();

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: AppBar(
        backgroundColor: context.tBg,
        title: Text('התראות Push',
            style: TextStyle(color: context.tText, fontSize: 18,
                fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Symbols.arrow_back_ios_new, color: context.tText),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // ── FCM Token card ───────────────────────────────────────
              const _SectionHeader(title: 'Firebase / FCM'),
              _InfoCard(
                title: push.fcmReady
                    ? '✅ Firebase מחובר'
                    : '⚠️ Firebase לא מוגדר',
                subtitle: push.fcmReady
                    ? 'FCM Token מוכן לשימוש'
                    : 'הוסף google-services.json עם פרטי הפרויקט שלך',
                trailing: push.fcmReady && push.fcmToken != null
                    ? IconButton(
                        icon: Icon(Symbols.content_copy,
                            color: context.tText2(0.6), size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: push.fcmToken!));
                          _showToast('FCM Token הועתק');
                        },
                      )
                    : null,
              ),
              if (push.fcmToken != null)
                _TokenDisplay(token: push.fcmToken!),

              const SizedBox(height: 12),

              // ── HA registration card ─────────────────────────────────
              const _SectionHeader(title: 'HA Mobile App Integration'),
              _InfoCard(
                title: push.webhookId != null
                    ? '✅ רשום ב-HA'
                    : 'רישום ל-Home Assistant',
                subtitle: push.webhookId != null
                    ? 'Webhook: ${push.webhookId}'
                    : 'הפעל mobile_app ב-HA ולחץ "רשום"',
                trailing: null,
              ),
              const SizedBox(height: 8),
              _ActionBtn(
                label: _registering ? 'רושם…' : 'רשום מכשיר ב-HA',
                icon: Symbols.phone_android,
                loading: _registering,
                onTap: _registerWithHa,
              ),

              const SizedBox(height: 16),

              // ── Test notification ────────────────────────────────────
              const _SectionHeader(title: 'בדיקה'),
              _ActionBtn(
                label: 'שלח התראת בדיקה',
                icon: Symbols.notifications_active,
                color: AppColors.primary,
                onTap: () {
                  HaPushService.instance.sendTestNotification();
                  _showToast('נשלחה התראת בדיקה');
                },
              ),

              const SizedBox(height: 20),

              // ── Rules ────────────────────────────────────────────────
              const _SectionHeader(title: 'כללי התראה'),
              const SizedBox(height: 4),
              ...push.rules.map(
                (rule) => _RuleRow(
                  rule:     rule,
                  onToggle: (v) =>
                      HaPushService.instance.setRuleEnabled(rule.id, v),
                ),
              ),
            ],
          ),

          // ── Toast ──────────────────────────────────────────────────
          if (_toast != null)
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _toast!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Rule row ──────────────────────────────────────────────────────────────────

class _RuleRow extends StatelessWidget {
  final dynamic rule;          // HaPushRule
  final ValueChanged<bool> onToggle;
  const _RuleRow({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rule.name as String,
              style: TextStyle(
                  color: context.tText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value:            rule.enabled as bool,
            onChanged:        onToggle,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(
        title,
        style: TextStyle(
            color: context.tText2(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _InfoCard({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tText2(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: context.tText2(0.5), fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Token display ─────────────────────────────────────────────────────────────

class _TokenDisplay extends StatelessWidget {
  final String token;
  const _TokenDisplay({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tText2(0.08)),
      ),
      child: Text(
        token,
        style: TextStyle(
            color: context.tText2(0.45),
            fontSize: 10,
            fontFamily: 'monospace'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF3FB950),
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 17),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
