// ─────────────────────────────────────────────────────────────────────────────
// GatewayConnectSheet
//
// Bottom sheet that adapts to any gateway type:
//   • Shows all fields defined in GatewayMeta.fields
//   • If requiresButtonPress: shows animated pulsing icon + countdown
//   • Live error display from GatewayManager
//   • On success: shows a green "connected" confirmation + device count
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/gateways/gateway_manager.dart';
import '../../services/gateways/gateway_types.dart';
import '../../theme/app_theme.dart';

class GatewayConnectSheet extends StatefulWidget {
  final GatewayMeta meta;

  /// Pre-fill field values (e.g. IP from a discovery scan), keyed by field key.
  final Map<String, String>? initialFields;

  /// When true, the connect flow starts automatically as soon as the sheet
  /// opens, provided all required fields are already filled.
  final bool autoConnect;

  const GatewayConnectSheet({
    super.key,
    required this.meta,
    this.initialFields,
    this.autoConnect = false,
  });

  @override
  State<GatewayConnectSheet> createState() => _GatewayConnectSheetState();
}

class _GatewayConnectSheetState extends State<GatewayConnectSheet>
    with SingleTickerProviderStateMixin {
  late final Map<String, TextEditingController> _ctrls;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  bool    _connected  = false;
  int?    _countdown;
  String? _error;
  bool    _connecting = false;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in widget.meta.fields)
        f.key: TextEditingController(
            text: widget.initialFields?[f.key] ?? f.defaultValue ?? ''),
    };
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Auto-start the connection (e.g. when launched from a discovery result
    // with the IP already known).
    if (widget.autoConnect && _canConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _connect();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Connect ────────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error      = null;
    });

    final fields = {
      for (final e in _ctrls.entries) e.key: e.value.text.trim(),
    };

    final manager = context.read<GatewayManager>();
    final err     = await manager.connect(widget.meta.type, fields);

    if (!mounted) return;

    setState(() {
      _connecting = false;
      if (err == null) {
        _connected = true;
      } else {
        _error = err;
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GatewayManager>();
    final meta    = widget.meta;
    final color   = meta.color;

    // Sync countdown from manager
    if (manager.isPairing && manager.pairCountdown != _countdown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _countdown = manager.pairCountdown);
      });
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.5,
      maxChildSize:     0.92,
      expand:           false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color:        context.tCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24, right: 24, top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:        context.tText2(0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Gateway brand header
              _GatewayHeader(meta: meta, color: color),
              const SizedBox(height: 20),

              // Success state
              if (_connected) ...[
                _SuccessView(
                  meta:    meta,
                  color:   color,
                  onClose: () => Navigator.pop(context),
                ),
              ]

              // Connecting / pairing state
              else if (_connecting || manager.isPairing) ...[
                _PairingView(
                  meta:      meta,
                  color:     color,
                  pulse:     _pulseAnim,
                  status:    manager.isPairing
                      ? manager.pairStatus
                      : 'מתחבר…',
                  countdown: _countdown,
                ),
              ]

              // Input form
              else ...[
                // Cloud badge
                if (meta.isCloud)
                  _CloudBadge(color: color),

                // Setup steps (e.g. how to obtain cloud credentials)
                if (meta.setupSteps != null && meta.setupSteps!.isNotEmpty)
                  _SetupSteps(steps: meta.setupSteps!, color: color),

                // Button-press instructions
                if (meta.requiresButtonPress && meta.buttonInstruction != null)
                  _ButtonPressHint(
                    instruction: meta.buttonInstruction!,
                    color:       color,
                  ),

                const SizedBox(height: 12),

                // Field inputs
                ...widget.meta.fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GatewayField(
                    field: f,
                    ctrl:  _ctrls[f.key]!,
                  ),
                )),

                if (_error != null) ...[
                  const SizedBox(height: 4),
                  _ErrorBanner(error: _error!),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 8),

                // Connect button
                SizedBox(
                  width:  double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canConnect ? _connect : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: context.tText,
                      disabledBackgroundColor:
                          color.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(meta.requiresButtonPress
                            ? Icons.bluetooth_searching
                            : Icons.link,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                          meta.requiresButtonPress
                              ? 'חבר (לאחר לחיצת כפתור)'
                              : 'חבר',
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Info link / footnote
                if (meta.isCloud)
                  Center(
                    child: Text(
                      'Token נוצר בפורטל ${meta.name}',
                      style: TextStyle(
                        color:    context.tText2(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canConnect {
    if (_connecting) return false;
    // All required fields must be non-empty
    for (final f in widget.meta.fields) {
      if (f.required && _ctrls[f.key]!.text.trim().isEmpty) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────
// Brand header
// ─────────────────────────────────────────────────────────────
class _GatewayHeader extends StatelessWidget {
  final GatewayMeta meta;
  final Color       color;
  const _GatewayHeader({required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(meta.icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.name,
                style: TextStyle(
                  color:      context.tText,
                  fontSize:   18,
                  fontWeight: FontWeight.bold,
                )),
              Text(meta.subtitle,
                style: TextStyle(
                  color:    context.tText2(0.4),
                  fontSize: 12,
                )),
            ],
          ),
        ),
        if (meta.isCloud)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border:       Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_outlined, color: color, size: 12),
              const SizedBox(width: 4),
              Text('ענן',
                style: TextStyle(
                  color:      color,
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                )),
            ]),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pairing view (button-press animation + countdown)
// ─────────────────────────────────────────────────────────────
class _PairingView extends StatelessWidget {
  final GatewayMeta      meta;
  final Color            color;
  final Animation<double> pulse;
  final String           status;
  final int?             countdown;

  const _PairingView({
    required this.meta,
    required this.color,
    required this.pulse,
    required this.status,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            // Pulsing icon
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Transform.scale(
                scale: pulse.value,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color:  color.withValues(alpha: 0.15 * pulse.value),
                    shape:  BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.5 * pulse.value),
                        width: 2),
                  ),
                  child: Icon(meta.icon, color: color, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(status,
              style: TextStyle(
                color:      context.tText,
                fontSize:   15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center),
            if (countdown != null && countdown! > 0) ...[
              const SizedBox(height: 8),
              Text('$countdown שניות נותרו',
                style: TextStyle(
                  color:    context.tText2(0.35),
                  fontSize: 12,
                )),
            ],
            const SizedBox(height: 24),
            if (meta.buttonInstruction != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                      color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.touch_app_outlined, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(meta.buttonInstruction!,
                        style: TextStyle(
                          color:    context.tText2(0.6),
                          fontSize: 12,
                          height:   1.5,
                        )),
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
// Success view
// ─────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final GatewayMeta  meta;
  final Color        color;
  final VoidCallback onClose;
  const _SuccessView({
    required this.meta,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GatewayManager>();
    final conn    = manager.connections.lastWhere(
        (c) => c.type == meta.type, orElse: () => manager.connections.last);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:  AppColors.secured.withValues(alpha: 0.15),
                shape:  BoxShape.circle,
                border: Border.all(
                    color: AppColors.secured.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(Icons.check_rounded,
                  color: AppColors.secured, size: 36),
            ),
            const SizedBox(height: 16),
            Text('מחובר בהצלחה!',
              style: TextStyle(
                color:      context.tText,
                fontSize:   18,
                fontWeight: FontWeight.bold,
              )),
            const SizedBox(height: 6),
            Text(conn.displayName,
              style: TextStyle(
                color:    context.tText2(0.45),
                fontSize: 13,
              )),
            const SizedBox(height: 32),
            SizedBox(
              width:  double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.tText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  elevation: 0,
                ),
                child: Text('סגור',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Cloud badge
// ─────────────────────────────────────────────────────────────
class _CloudBadge extends StatelessWidget {
  final Color color;
  const _CloudBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.cloud_outlined, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('חיבור ענן — הנתונים עוברים דרך שרתי היצרן',
            style: TextStyle(
              color:    context.tText2(0.5),
              fontSize: 11,
            )),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Setup steps (collapsible numbered guide)
// ─────────────────────────────────────────────────────────────
class _SetupSteps extends StatefulWidget {
  final List<String> steps;
  final Color        color;
  const _SetupSteps({required this.steps, required this.color});

  @override
  State<_SetupSteps> createState() => _SetupStepsState();
}

class _SetupStepsState extends State<_SetupSteps> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color:        widget.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: widget.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tap to expand)
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: widget.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('איך משיגים את הפרטים? (${widget.steps.length} צעדים)',
                      style: TextStyle(
                        color:      widget.color,
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                      )),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: widget.color, size: 20),
                ],
              ),
            ),
          ),
          // Steps
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:  widget.color.withValues(alpha: 0.18),
                              shape:  BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                              style: TextStyle(
                                color:      widget.color,
                                fontSize:   11,
                                fontWeight: FontWeight.bold,
                              )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(widget.steps[i],
                              style: TextStyle(
                                color:    context.tText2(0.65),
                                fontSize: 12,
                                height:   1.45,
                              )),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Button-press hint
// ─────────────────────────────────────────────────────────────
class _ButtonPressHint extends StatelessWidget {
  final String instruction;
  final Color  color;
  const _ButtonPressHint({required this.instruction, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.touch_app_outlined, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(instruction,
              style: TextStyle(
                color:    context.tText2(0.6),
                fontSize: 12,
                height:   1.5,
              )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Field input
// ─────────────────────────────────────────────────────────────
class _GatewayField extends StatelessWidget {
  final GatewayFieldDef         field;
  final TextEditingController   ctrl;
  const _GatewayField({required this.field, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   ctrl,
      obscureText:  field.obscure,
      keyboardType: field.keyboardType,
      maxLines:     field.inputType == FieldInputType.token ? 3 : 1,
      style: TextStyle(color: context.tText, fontSize: 13),
      decoration: InputDecoration(
        labelText: field.label,
        labelStyle: TextStyle(
          color:    context.tText2(0.45),
          fontSize: 12,
        ),
        hintText:  field.hint,
        hintStyle: TextStyle(
          color:    context.tText2(0.18),
          fontSize: 12,
        ),
        prefixIcon: Icon(field.icon,
            color: context.tText2(0.35), size: 18),
        filled:        true,
        fillColor:     context.tText2(0.05),
        border:        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        isDense:       true,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 14),
        // "Optional" suffix
        suffixIcon: !field.required
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('אופציונלי',
                  style: TextStyle(
                    color:    context.tText2(0.2),
                    fontSize: 9,
                  )),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.unsecured.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(
            color: AppColors.unsecured.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline,
            color: AppColors.unsecured, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(error,
            style: TextStyle(
              color:    AppColors.unsecured,
              fontSize: 12,
            )),
        ),
      ]),
    );
  }
}
