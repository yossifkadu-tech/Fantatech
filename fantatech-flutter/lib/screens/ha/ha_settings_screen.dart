import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ha/ha_provider.dart';
import '../../services/ha/ha_config.dart';

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _card    = Color(0xFF21262D);
const _border  = Color(0xFF30363D);
const _orange  = Color(0xFFFF6B00);
const _green   = Color(0xFF3FB950);
const _red     = Color(0xFFF85149);
const _text1   = Color(0xFFE6EDF3);
const _text2   = Color(0xFF8B949E);

class HaSettingsScreen extends StatefulWidget {
  const HaSettingsScreen({super.key});

  @override
  State<HaSettingsScreen> createState() => _HaSettingsScreenState();
}

class _HaSettingsScreenState extends State<HaSettingsScreen> {
  final _urlCtrl   = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _connecting = false;
  String? _message;
  bool _messageOk = true;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<HaProvider>().config;
    if (cfg != null) {
      _urlCtrl.text   = cfg.baseUrl;
      _tokenCtrl.text = cfg.token;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url   = _urlCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (url.isEmpty || token.isEmpty) {
      setState(() { _message = 'יש למלא כתובת URL וטוקן'; _messageOk = false; });
      return;
    }

    setState(() { _connecting = true; _message = null; });

    final ha  = context.read<HaProvider>();
    final cfg = HaConfig(baseUrl: url, token: token);
    final ok  = await ha.connect(cfg);

    if (!mounted) return;
    setState(() {
      _connecting = false;
      _message    = ok ? 'חיבור הצליח!' : (ha.error ?? 'חיבור נכשל');
      _messageOk  = ok;
    });
  }

  Future<void> _disconnect() async {
    await context.read<HaProvider>().disconnect();
    if (!mounted) return;
    setState(() {
      _message   = 'מנותק מ-Home Assistant';
      _messageOk = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ha        = context.watch<HaProvider>();
    final connected = ha.isConnected;

    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Connection Status Card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: connected
                    ? _green.withValues(alpha: 0.35)
                    : _border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: connected
                        ? _green.withValues(alpha: 0.12)
                        : _surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    connected ? Symbols.wifi : Symbols.wifi_off,
                    color: connected ? _green : _text2, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(connected ? 'מחובר' : 'מנותק',
                          style: TextStyle(
                            color: connected ? _green : _text2,
                            fontWeight: FontWeight.w600, fontSize: 16)),
                      if (ha.config != null)
                        Text(ha.config!.baseUrl,
                            style: const TextStyle(color: _text2, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (connected)
                  GestureDetector(
                    onTap: _disconnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _red.withValues(alpha: 0.3)),
                      ),
                      child: const Text('נתק',
                          style: TextStyle(color: _red,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Connection Form ───────────────────────────────────────
          const Text('הגדרות חיבור',
              style: TextStyle(color: _text1, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          _TextField(
            controller: _urlCtrl,
            label: 'כתובת Home Assistant',
            hint: 'http://192.168.1.82:8123',
            icon: Symbols.link,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: _tokenCtrl,
            label: 'Long-Lived Access Token',
            hint: 'eyJ0eXAiOiJKV1...',
            icon: Symbols.vpn_key,
            obscure: true,
          ),
          const SizedBox(height: 16),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _connecting ? null : _connect,
              child: _connecting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(connected ? 'עדכן חיבור' : 'התחבר',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),

          // Message
          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_messageOk ? _green : _red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_messageOk ? _green : _red).withValues(alpha: 0.3)),
              ),
              child: Text(_message!,
                  style: TextStyle(
                    color: _messageOk ? _green : _red,
                    fontSize: 13)),
            ),
          ],

          const SizedBox(height: 24),

          // ── Info ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('איך להשיג טוקן?',
                    style: TextStyle(color: _text1, fontWeight: FontWeight.w600,
                        fontSize: 13)),
                SizedBox(height: 8),
                _InfoStep('1', 'כנס ל-Home Assistant'),
                _InfoStep('2', 'לחץ על שמך (פינה שמאל תחתון)'),
                _InfoStep('3', 'גלול מטה → Security'),
                _InfoStep('4', 'Long-Lived Access Tokens → Create Token'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscure && !_show,
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: _text1),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: _text2),
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFF484F58)),
        prefixIcon: Icon(widget.icon, color: _text2, size: 18),
        suffixIcon: widget.obscure
            ? GestureDetector(
                onTap: () => setState(() => _show = !_show),
                child: Icon(
                  _show ? Symbols.visibility_off : Symbols.visibility,
                  color: _text2, size: 18))
            : null,
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange)),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String step, text;
  const _InfoStep(this.step, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.15),
            shape: BoxShape.circle),
          child: Center(
            child: Text(step, style: const TextStyle(
                color: _orange, fontSize: 10,
                fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: _text2, fontSize: 12)),
      ],
    ),
  );
}
