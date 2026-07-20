import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/app_state.dart';
import '../../l10n/strings.dart';
import '../../services/ai/ai_agent_service.dart';
import '../../theme/app_theme.dart';

// Dedicated accent for the Fanta AI screen — distinct from the app's orange
// brand color, matching the approved "Design 4" mockup.
const _kAiBlue = Color(0xFF4F7DF3);
const _kAiBlueDark = Color(0xFF3D63D6);

class FantaAIScreen extends StatefulWidget {
  const FantaAIScreen({super.key});

  @override
  State<FantaAIScreen> createState() => _FantaAIScreenState();
}

class _FantaAIScreenState extends State<FantaAIScreen>
    with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _isListening = false;

  // Speech-to-text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  // Real Claude-backed agent + spoken replies
  final AiAgentService _agent = AiAgentService();
  final FlutterTts _tts = FlutterTts();

  late AnimationController _orbPulse;
  late AnimationController _orbGlow;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  List<String> _getSuggestions(S s) => [s.aiSug1, s.aiSug2, s.aiSug3, s.aiSug4];

  @override
  void initState() {
    super.initState();

    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _orbGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _orbPulse, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _orbGlow, curve: Curves.easeInOut),
    );

    _initSpeech();
    _tts.setLanguage(_speechLocaleId(context.read<AppState>().locale));
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          // status: 'listening' | 'notListening' | 'done'
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      // If we got transcribed text, send it as a message.
      final text = _inputCtrl.text.trim();
      if (text.isNotEmpty) {
        _sendMessage(text);
      }
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }
    if (!mounted) return;
    if (!_speechAvailable) {
      final s = context.read<AppState>().strings;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.aiMicUnavailable),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final locale = _speechLocaleId(context.read<AppState>().locale);
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (res) {
        setState(() {
          _inputCtrl.text = res.recognizedWords;
          _inputCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputCtrl.text.length));
        });
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        localeId: locale,
      ),
    );
  }

  String _speechLocaleId(AppLocale loc) {
    switch (loc) {
      case AppLocale.hebrew:  return 'he-IL';
      case AppLocale.english: return 'en-US';
      case AppLocale.arabic:  return 'ar-SA';
      case AppLocale.amharic: return 'am-ET';
      case AppLocale.spanish: return 'es-ES';
      case AppLocale.russian: return 'ru-RU';
      case AppLocale.french:  return 'fr-FR';
    }
  }

  @override
  void dispose() {
    _orbPulse.dispose();
    _orbGlow.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isThinking) return;
    _inputCtrl.clear();
    final state = context.read<AppState>();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isThinking = true;
    });
    _scrollToBottom();

    // Real Claude agent — understands intent, calls real device commands via
    // AppState/DeviceCommander, and only reports success it actually
    // confirmed. See AiAgentService for the tool-use loop.
    final reply = await _agent.send(text, state);
    if (!mounted) return;

    setState(() {
      _isThinking = false;
      _messages.add(_ChatMessage(text: reply.text, isUser: false));
    });
    _scrollToBottom();
    _inputFocus.requestFocus();

    if (reply.text.isNotEmpty) {
      await _tts.setLanguage(_speechLocaleId(state.locale));
      await _tts.speak(reply.text);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsSheet() {
    final s = context.read<AppState>().strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.tText2(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Symbols.delete_sweep, color: AppColors.statusAlarm),
                title: Text(s.aiClearChat,
                    style: TextStyle(color: context.tText, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _messages.clear());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showChat = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: context.tBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(onSettings: _showSettingsSheet),

            // ── Body ─────────────────────────────────────────
            Expanded(
              child: showChat ? _ChatView() : _WelcomeView(),
            ),

            // ── Input bar ────────────────────────────────────
            _InputBar(),
          ],
        ),
      ),
    );
  }

  // ── Welcome view (before first message) ────────────────────
  Widget _WelcomeView() {
    final state = context.watch<AppState>();
    final s = state.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Orb
          _AIOrb(pulseAnim: _pulseAnim, glowAnim: _glowAnim),

          const SizedBox(height: 28),

          // Greeting
          Text(
            '${state.userFirstName}! 👋',
            style: const TextStyle(
              color: _kAiBlue,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.aiSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText2(0.45),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Suggestion cards — 2x2 grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: List.generate(4, (i) {
              const icons = [Symbols.lightbulb, Symbols.shield, Symbols.bedtime, Symbols.notifications];
              const bgColors = [_kAiBlue, AppColors.statusOnline, Color(0xFF9C6FE0), AppColors.statusWarning];
              final descs = [s.aiSugDesc1, s.aiSugDesc2, s.aiSugDesc3, s.aiSugDesc4];
              final titles = _getSuggestions(s);
              return _SuggestionCard(
                icon: icons[i],
                accent: bgColors[i],
                title: titles[i],
                desc: descs[i],
                onTap: () => _sendMessage(titles[i]),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Privacy note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.lock, size: 13, color: context.tText2(0.35)),
              const SizedBox(width: 5),
              Text(
                s.aiPrivacyNote,
                style: TextStyle(color: context.tText2(0.35), fontSize: 11.5),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Chat view (after first message) ────────────────────────
  Widget _ChatView() {
    final s = context.select((AppState st) => st.strings);
    // Show "what next?" chips after the assistant has replied (not while
    // thinking) so it's obvious the conversation stays open for more requests.
    final showFollowUps =
        !_isThinking && _messages.isNotEmpty && !_messages.last.isUser;
    final extra = (_isThinking ? 1 : 0) + (showFollowUps ? 1 : 0);

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + extra,
      itemBuilder: (ctx, i) {
        if (_isThinking && i == _messages.length) {
          return _ThinkingBubble();
        }
        if (showFollowUps && i == _messages.length) {
          return _FollowUpChips(s);
        }
        return _MessageBubble(message: _messages[i]);
      },
    );
  }

  // ── Follow-up suggestion chips (keep the conversation going) ──
  Widget _FollowUpChips(S s) {
    final sugg = _getSuggestions(s);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(sugg.length, (i) {
          return GestureDetector(
            onTap: () => _sendMessage(sugg[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _kAiBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _kAiBlue.withValues(alpha: 0.30)),
              ),
              child: Text(
                sugg[i],
                style: TextStyle(
                  color: _kAiBlue,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────
  Widget _InputBar() {
    final state = context.watch<AppState>();
    final s = state.strings;
    final textDir = state.isRtl ? TextDirection.rtl : TextDirection.ltr;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: context.tCard,
        border: Border(
          top: BorderSide(
            color: context.tText2(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mic button — real speech-to-text
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? _kAiBlue
                    : _kAiBlue.withValues(alpha: 0.15),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: _kAiBlue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Symbols.mic,
                color: _isListening ? Colors.white : _kAiBlue,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Text field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: context.tText2(0.1),
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                textDirection: textDir,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: context.tText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: s.aiInputHint,
                  hintStyle: TextStyle(
                    color: context.tText2(0.3),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (t) => _sendMessage(t),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button — proper 44px tap target
          Material(
            color: _kAiBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isThinking
                  ? null
                  : () => _sendMessage(_inputCtrl.text),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Symbols.send,
                  color: _isThinking
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AI Orb — soundwave avatar (Design 4)
// ─────────────────────────────────────────────────────────────
class _AIOrb extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Animation<double> glowAnim;

  const _AIOrb({required this.pulseAnim, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnim, glowAnim]),
      builder: (ctx, _) {
        return Transform.scale(
          scale: pulseAnim.value,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kAiBlue.withValues(alpha: 0.20 * glowAnim.value),
                        blurRadius: 46,
                        spreadRadius: 16,
                      ),
                    ],
                  ),
                ),

                // Filled circle
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kAiBlue, _kAiBlueDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kAiBlue.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),

                // Soundwave bars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    const heights = [14.0, 26.0, 36.0, 26.0, 14.0];
                    final wave = 0.85 + 0.15 * math.sin((glowAnim.value * math.pi) + i);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: heights[i] * wave,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Suggestion card — 2x2 grid tile with icon, title, description
// ─────────────────────────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.tCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.tText2(0.08)),
          boxShadow: context.isLight ? AppShadows.sm : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: context.tText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                color: context.tText2(0.45),
                fontSize: 10.5,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chat message bubble
// ─────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Align(
      alignment: message.isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? _kAiBlue
              : context.tText2(0.08),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(message.isUser ? 16 : 4),
            bottomEnd: Radius.circular(message.isUser ? 4 : 16),
          ).resolve(Directionality.of(context)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : context.tText2(0.9),
            fontSize: 14,
            height: 1.5,
          ),
          textDirection:
              state.isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Thinking indicator
// ─────────────────────────────────────────────────────────────
class _ThinkingBubble extends StatefulWidget {
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.tText2(0.08),
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomEnd: const Radius.circular(16),
            bottomStart: const Radius.circular(4),
          ).resolve(Directionality.of(context)),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.3;
              final val =
                  math.sin((_ctrl.value * math.pi) - delay).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAiBlue.withValues(alpha: 0.4 + val * 0.6),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;
  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final s = context.select((AppState st) => st.strings);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Symbols.chevron_right,
                color: context.tText,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Fanta AI',
                      style: TextStyle(
                        color: context.tText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 2),
                        child: Icon(Symbols.auto_awesome, color: _kAiBlue, size: 12),
                      ),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  s.aiTopSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.tText2(0.45), fontSize: 11.5),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSettings,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.tText2(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Symbols.settings,
                color: context.tText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
