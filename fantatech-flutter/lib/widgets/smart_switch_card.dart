import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// כרטיס "מפסק חכם" עגול עם אנימציית מעבר חלקה בין מצב דלוק (ON) לכבוי (OFF).
///
/// הכפתור מחושב כאחוז מהרוחב הזמין (LayoutBuilder), כך שהוא נשמר באותן
/// פרופורציות גם בטלפון צר וגם במסך רחב/טאבלט, עם גבולות מינימום/מקסימום
/// כדי שלא ייצא קטן מדי או גדול מדי בקצוות.
///
/// [isOn] and [onConnected] are the live, externally-owned state (from
/// AppState) — the widget keeps its own [_isOn] only so the toggle
/// animation has something to animate optimistically on tap, and
/// resyncs to [isOn] whenever it changes from outside (a schedule, an
/// automation, another screen), not just on first build.
class SmartSwitchCard extends StatefulWidget {
  final String deviceName;
  final String roomName;
  final bool isOn;
  final bool isConnected;
  final ValueChanged<bool>? onChanged;
  final IconData icon;
  // False when the card is embedded in a screen that already shows its own
  // name/room/icon header (e.g. the devices list detail sheet) — avoids
  // showing the same name and a second small icon twice.
  final bool showHeader;

  const SmartSwitchCard({
    super.key,
    required this.deviceName,
    required this.roomName,
    required this.isOn,
    this.isConnected = true,
    this.onChanged,
    this.icon = Icons.power_settings_new_rounded,
    this.showHeader = true,
  });

  @override
  State<SmartSwitchCard> createState() => _SmartSwitchCardState();
}

class _SmartSwitchCardState extends State<SmartSwitchCard> {
  late bool _isOn;

  // פלטת הצבעים של Fantatech: כתום = פעולה/פעיל, אפור-נייבי = כבוי/ניטרלי.
  static const _orangeGradientOn = [
    Color(0xFFFFB37A),
    Color(0xFFFF8A3D),
    Color(0xFFF4661A),
  ];
  static const _grayGradientOff = [
    Color(0xFFE7E4DF),
    Color(0xFFC9C4BC),
    Color(0xFFA9A29A),
  ];

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn;
  }

  @override
  void didUpdateWidget(SmartSwitchCard old) {
    super.didUpdateWidget(old);
    // Real state changed from outside (schedule/automation/another
    // screen) — resync instead of only ever reading isOn once.
    if (widget.isOn != old.isOn) _isOn = widget.isOn;
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _isOn = !_isOn);
    widget.onChanged?.call(_isOn);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // גודל הכפתור: 18% מרוחב הכרטיס — עכשיו שהכותרת קומפקטית וחד-שורתית,
        // המקום שהתפנה הולך לכפתור עצמו כדי שיהיה בולט.
        final buttonSize = (availableWidth * 0.18).clamp(60.0, 78.0);
        final glowSize = buttonSize * 1.3;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isOn
                  ? const [Color(0xFFFFF7F0), Color(0xFFFBEFE4)]
                  : const [Color(0xFFF5F4F2), Color(0xFFECEAE6)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showHeader) ...[
                _Header(
                  deviceName: widget.deviceName,
                  roomName: widget.roomName,
                  icon: widget.icon,
                  isOn: _isOn,
                  isConnected: widget.isConnected,
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: glowSize,
                height: glowSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _isOn ? 1 : 0,
                      duration: const Duration(milliseconds: 350),
                      child: Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x8CFF8A3D), Color(0x00FF8A3D)],
                            stops: [0.0, 0.7],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: _isOn ? 0.55 : 0.4),
                            width: 3,
                          ),
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.4),
                            colors: _isOn ? _orangeGradientOn : _grayGradientOff,
                            stops: const [0.0, 0.55, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isOn
                                  ? const Color(0x66F4661A)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: _isOn ? 30 : 16,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.power_settings_new_rounded,
                              size: buttonSize * 0.24,
                              color: _isOn ? Colors.white : const Color(0xFF78716A),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isOn ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontSize: buttonSize * 0.16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: _isOn ? Colors.white : const Color(0xFF78716A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isOn ? const Color(0xFFF4661A) : const Color(0xFFA9A29A),
                ),
                // Generic per-device text instead of hardcoded "lighting" —
                // this card represents any switch/plug, not only lights.
                child: Text(
                    '${widget.deviceName} ${_isOn ? "פעיל" : "כבוי"}'),
              ),
              const SizedBox(height: 2),
              Text(
                _isOn ? 'הקש כדי לכבות' : 'הקש כדי להדליק',
                style: const TextStyle(fontSize: 9, color: Color(0xFF7A6F63)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String deviceName;
  final String roomName;
  final IconData icon;
  final bool isOn;
  final bool isConnected;

  const _Header({
    required this.deviceName,
    required this.roomName,
    required this.icon,
    required this.isOn,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Name + room on one line (was two stacked lines) — frees up
        // vertical space for the button below.
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: deviceName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2A)),
                ),
                if (roomName.isNotEmpty)
                  TextSpan(
                    text: '  ·  $roomName',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7A6F63)),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isConnected ? 'מחובר' : 'לא מחובר',
                style: const TextStyle(fontSize: 9, color: Color(0xFF7A6F63))),
            const SizedBox(width: 4),
            if (isConnected) const _ConnectedDot(),
            const SizedBox(width: 4),
            Icon(
              isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 13,
              color: const Color(0xFF7A6F63),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectedDot extends StatelessWidget {
  const _ConnectedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: Color(0xFF3FB56B), shape: BoxShape.circle),
    );
  }
}
