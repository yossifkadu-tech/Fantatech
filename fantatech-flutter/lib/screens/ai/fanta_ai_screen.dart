import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/app_state.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

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
    }
  }

  @override
  void dispose() {
    _orbPulse.dispose();
    _orbGlow.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text, {int sugIndex = -1}) async {
    if (text.trim().isEmpty || _isThinking) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isThinking = true;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    final replyKey = _generateReply(text, sugIndex: sugIndex);
    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add(_ChatMessage(text: '', isUser: false, replyKey: replyKey));
    });

    _scrollToBottom();
    // Re-focus the input so the user can immediately type another message.
    _inputFocus.requestFocus();
  }

  _ReplyKey _generateReply(String input, {int sugIndex = -1}) {
    // suggestion chip tapped — reply by index
    if (sugIndex == 0) return _ReplyKey.reply1;
    if (sugIndex == 1) return _ReplyKey.reply2;
    if (sugIndex == 2) return _ReplyKey.reply3;
    if (sugIndex == 3) return _ReplyKey.reply4;
    // free-text: match keywords across all supported languages
    final lower = input.toLowerCase();
    final isLights = lower.contains('אור') || lower.contains('תאורה') ||
        lower.contains('light') || lower.contains('свет') ||
        lower.contains('ضوء') || lower.contains('luz') || lower.contains('መብራት');
    final isStatus = lower.contains('מצב') || lower.contains('סטטוס') ||
        lower.contains('status') || lower.contains('состояние') ||
        lower.contains('حالة') || lower.contains('estado') || lower.contains('ሁኔታ');
    final isNight = lower.contains('לילה') || lower.contains('שקט') ||
        lower.contains('night') || lower.contains('ночь') ||
        lower.contains('ليل') || lower.contains('noche') || lower.contains('ሌሊት');
    final isAlert = lower.contains('התראה') || lower.contains('אבטחה') ||
        lower.contains('alert') || lower.contains('security') ||
        lower.contains('تنبيه') || lower.contains('alerta') || lower.contains('ማስጠንቀቂያ');
    if (isLights) return _ReplyKey.reply1;
    if (isStatus) return _ReplyKey.reply2;
    if (isNight)  return _ReplyKey.reply3;
    if (isAlert)  return _ReplyKey.reply4;
    return _ReplyKey.replyDefault;
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
            _TopBar(),

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
            style: TextStyle(
              color: context.tText,
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

          const SizedBox(height: 32),

          // Suggestion chips
          ..._getSuggestions(s).asMap().entries.map(
            (entry) => _SuggestionChip(
              text: entry.value,
              onTap: () => _sendMessage(entry.value, sugIndex: entry.key),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Chat view (after first message) ────────────────────────
  Widget _ChatView() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length + (_isThinking ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_isThinking && i == _messages.length) {
          return _ThinkingBubble();
        }
        return _MessageBubble(message: _messages[i]);
      },
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
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_outlined,
                color: _isListening ? context.tText : AppColors.primary,
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
            color: AppColors.primary,
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
                  Icons.send_rounded,
                  color: _isThinking
                      ? context.tText2(0.4)
                      : context.tText,
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
// AI Orb
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
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.18 * glowAnim.value),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Gradient border ring
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.8),
                        const Color(0xFF7B6FCD).withValues(alpha: 0.6),
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Inner dark circle
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D0F1A),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.12 * glowAnim.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),

                // Eyes
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Eye(glowAlpha: glowAnim.value),
                    const SizedBox(width: 22),
                    _Eye(glowAlpha: glowAnim.value),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Eye extends StatelessWidget {
  final double glowAlpha;
  const _Eye({required this.glowAlpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.7 * glowAlpha),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Suggestion chip
// ─────────────────────────────────────────────────────────────
class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: context.tText2(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.tText2(0.10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: context.tText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Icon(
              Icons.chevron_left,
              color: context.tText2(0.3),
              size: 18,
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
/// Identifies which canned bot reply a message holds, so it can be
/// re-rendered in the currently-selected language instead of staying
/// frozen in the language it was first generated in.
enum _ReplyKey { reply1, reply2, reply3, reply4, replyDefault }

class _ChatMessage {
  /// Literal text — used for user-typed messages (kept as the user wrote them).
  final String text;
  final bool isUser;

  /// For bot messages: which canned reply this is. When non-null the bubble
  /// resolves the text live from the current language's strings.
  final _ReplyKey? replyKey;

  _ChatMessage({required this.text, required this.isUser, this.replyKey});

  /// Resolve the text to display in the given language.
  String resolve(S s) {
    switch (replyKey) {
      case _ReplyKey.reply1:       return s.aiReply1;
      case _ReplyKey.reply2:       return s.aiReply2;
      case _ReplyKey.reply3:       return s.aiReply3;
      case _ReplyKey.reply4:       return s.aiReply4;
      case _ReplyKey.replyDefault: return s.aiReplyDefault;
      case null:                   return text; // user message
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Resolve bot replies live so they follow the selected language.
    final state = context.watch<AppState>();
    final s = state.strings;
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : context.tText2(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.resolve(s),
          style: TextStyle(
            color: message.isUser
                ? context.tText
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
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.tText2(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
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
                  color: AppColors.primary.withValues(alpha: 0.4 + val * 0.6),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
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
                Icons.chevron_right,
                color: context.tText,
                size: 22,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Fanta AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}
