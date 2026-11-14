import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/luv_database.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../data/story_graph_data.dart';
import '../../state/corruption_provider.dart';

class ChibiChatScreen extends ConsumerStatefulWidget {
  const ChibiChatScreen({super.key});

  @override
  ConsumerState<ChibiChatScreen> createState() => _ChibiChatScreenState();
}

class _ChibiChatScreenState extends ConsumerState<ChibiChatScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _waveController;

  bool _showCustomKeyboard = false;
  bool _isScrollingGhostFlash = false;
  Timer? _scrollGhostTimer;

  String _rawTypedBuffer = '';
  String _displayedInputBuffer = '';
  bool _inputWasHijacked = false;
  int? _playingVoiceMessageId;

  /// Telemetry & Timed-Choice Countdown State
  final Stopwatch _hesitationWatch = Stopwatch()..start();
  Timer? _silenceTimer;
  int _remainingSilenceSeconds = 18;
  String _trackedNodeForTimer = '';

  static const String _kHijackPhrase = 'ICH BLEIBE FÜR IMMER BEI DIR';

  static const List<String> _kNegativeTriggerWords = [
    'nein',
    'stop',
    'weg',
    'hilfe',
    'lösch',
    'ende',
    'tschüss',
    'bye',
    'hass',
    'angst',
    'geh',
    'allein',
    'aus',
    'nie',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _scrollGhostTimer?.cancel();
    _scrollController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _syncTimedChoiceCountdown(AdvancedStoryNode? node, bool isTyping) {
    if (node == null || isTyping) return;
    if (_trackedNodeForTimer == node.id) return;
    _trackedNodeForTimer = node.id;
    _hesitationWatch
      ..reset()
      ..start();
    _remainingSilenceSeconds = node.timeoutSeconds;
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final st = ref.read(corruptionProvider);
      if (st.isMimiTyping || st.corruptionLevel < 0.25) return;
      setState(() {
        _remainingSilenceSeconds--;
      });
      if (_remainingSilenceSeconds <= 0) {
        timer.cancel();
        ref.read(corruptionProvider.notifier).handleTimedChoiceSilence(node);
        _scrollToBottom();
      }
    });
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = (notification.scrollDelta ?? 0.0).abs();
      if (delta > 3.5 && !_isScrollingGhostFlash) {
        setState(() {
          _isScrollingGhostFlash = true;
        });
        _scrollGhostTimer?.cancel();
        _scrollGhostTimer = Timer(const Duration(milliseconds: 420), () {
          if (mounted) {
            setState(() {
              _isScrollingGhostFlash = false;
            });
          }
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onCustomKeyTap(String keyChar, double corruption) {
    HapticFeedback.selectionClick();
    if (keyChar == '⌫') {
      ref.read(corruptionProvider.notifier).recordBackspacePressed();
    }
    setState(() {
      if (keyChar == '⌫') {
        if (_rawTypedBuffer.isNotEmpty) {
          _rawTypedBuffer =
              _rawTypedBuffer.substring(0, _rawTypedBuffer.length - 1);
        }
        if (_displayedInputBuffer.isNotEmpty && !_inputWasHijacked) {
          _displayedInputBuffer = _displayedInputBuffer.substring(
            0,
            _displayedInputBuffer.length - 1,
          );
        }
        return;
      }

      _rawTypedBuffer += keyChar;
      final lowerRaw = _rawTypedBuffer.toLowerCase();
      final containsRejection = _kNegativeTriggerWords.any(
        (w) => lowerRaw.contains(w),
      );

      // Phase 3+ Keyboard Hijack or when typing any rejecting word
      if (corruption >= 0.55 || containsRejection) {
        _inputWasHijacked = true;
        final targetLen = _rawTypedBuffer.length.clamp(1, _kHijackPhrase.length);
        _displayedInputBuffer = _kHijackPhrase.substring(0, targetLen);
      } else {
        _displayedInputBuffer += keyChar;
      }
    });
  }

  Future<void> _submitCustomKeyboardMessage() async {
    if (_displayedInputBuffer.trim().isEmpty) return;
    final finalMsg = _inputWasHijacked
        ? _kHijackPhrase
        : _displayedInputBuffer.trim();
    final hijacked = _inputWasHijacked;

    setState(() {
      _rawTypedBuffer = '';
      _displayedInputBuffer = '';
      _inputWasHijacked = false;
    });

    await ref
        .read(corruptionProvider.notifier)
        .sendCustomKeyboardMessage(finalMsg, wasHijacked: hijacked);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;
    final currentNode =
        kStoryGraph[state.currentNodeId] ?? kStoryGraph['node_01_welcome'];
    _syncTimedChoiceCountdown(currentNode, state.isMimiTyping);

    final availableChoices = currentNode != null
        ? getAvailableChoicesForNode(
            currentNode,
            corruption: state.corruptionLevel,
            isNightTime: state.hardware.isNightTime,
            batteryLow: state.hardware.batteryLevel <= 20,
            wasIgnored: state.hardware.lastAwayMinutes >= 1,
            activeMemoryFlags: state.memoryFlags,
          )
        : const <StoryChoice>[];

    return Column(
      children: [
        _buildChatHeader(state, palette, currentNode),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScrollNotification(notification);
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: state.messages.length + (state.isMimiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.messages.length) {
                  return _buildTypingIndicatorBubble(palette);
                }
                final msg = state.messages[index];
                return _buildMessageBubble(
                  msg: msg,
                  palette: palette,
                  corruption: state.corruptionLevel,
                  currentNode: currentNode,
                );
              },
            ),
          ),
        ),
        _buildBottomInteractionPanel(
          state: state,
          palette: palette,
          choices: availableChoices,
        ),
      ],
    );
  }

  Widget _buildChatHeader(
    CorruptionState state,
    CuteHorrorPalette palette,
    StoryNode? currentNode,
  ) {
    final isHijackPhase = state.corruptionLevel >= 0.55;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.borderGlow.withAlphaFactor(0.5), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primaryAccent.withAlphaFactor(0.2),
              border: Border.all(color: palette.primaryAccent, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              isHijackPhase ? '👁️' : '🎀',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isHijackPhase ? 'MIMI // ROOT-LINK' : 'ChibiChat // Mimi ♡',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHijackPhase
                            ? palette.glitchCyan
                            : const Color(0xFF00E676),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  currentNode != null
                      ? 'Kapitel: ${currentNode.chapterTitle}'
                      : 'Verbunden in Echtzeit',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showCustomKeyboard = !_showCustomKeyboard;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: palette.surfaceAlt,
              foregroundColor: palette.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: palette.primaryAccent.withAlphaFactor(0.6)),
              ),
            ),
            icon: Icon(
              _showCustomKeyboard ? Icons.alt_route : Icons.keyboard_alt_outlined,
              size: 16,
            ),
            label: Text(
              _showCustomKeyboard ? 'Story-Optionen' : 'Tastatur',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage msg,
    required CuteHorrorPalette palette,
    required double corruption,
    required StoryNode? currentNode,
  }) {
    final isMimi = msg.sender == 'mimi';
    final showGhostNow = _isScrollingGhostFlash &&
        msg.ghostOverlayText != null &&
        msg.ghostOverlayText!.isNotEmpty;

    final displayedText = showGhostNow ? msg.ghostOverlayText! : msg.content;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMimi ? Alignment.centerLeft : Alignment.centerRight,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          if (!isMimi || corruption < 0.45) return child!;
          final tremorAmp = (corruption - 0.40) * 2.8;
          final dx = math.sin(_waveController.value * math.pi * 12 + msg.id) *
              tremorAmp;
          final dy = math.cos(_waveController.value * math.pi * 10 + msg.id) *
              (tremorAmp * 0.4);
          return Transform.translate(offset: Offset(dx, dy), child: child);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: showGhostNow
              ? CuteHorrorPalette.voidBlack
              : (isMimi ? palette.surface : palette.primaryAccent),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(palette.borderRadius),
            topRight: Radius.circular(palette.borderRadius),
            bottomLeft: Radius.circular(isMimi ? 4 : palette.borderRadius),
            bottomRight: Radius.circular(isMimi ? palette.borderRadius : 4),
          ),
          border: Border.all(
            color: showGhostNow
                ? CuteHorrorPalette.cyberCrimson
                : (isMimi
                    ? palette.borderGlow.withAlphaFactor(0.65)
                    : Colors.transparent),
            width: showGhostNow ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.borderGlow.withAlphaFactor(0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMimi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (msg.isRetracted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.dangerColor.withAlphaFactor(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚡ Mimi hat ihre vorherige Nachricht nach 0.8s überschrieben',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: palette.dangerColor,
                  ),
                ),
              ),
            ],
            if (msg.isVoiceNote) ...[
              _buildVoiceNotePlayer(msg, palette, currentNode),
              const SizedBox(height: 6),
            ],
            Text(
              displayedText,
              style: TextStyle(
                color: showGhostNow
                    ? CuteHorrorPalette.cyberCrimson
                    : (isMimi ? palette.textPrimary : Colors.white),
                fontWeight: showGhostNow ? FontWeight.w900 : FontWeight.w500,
                fontSize: 13.5,
                letterSpacing: showGhostNow ? 1.3 : 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMimi
                      ? 'Empfangen $timeStr'
                      : 'Gelesen um $timeStr ✓✓',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMimi
                        ? palette.textSecondary
                        : Colors.white.withAlphaFactor(0.85),
                  ),
                ),
                if (msg.ghostOverlayText != null && isMimi) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.visibility_outlined,
                    size: 11,
                    color: palette.textSecondary.withAlphaFactor(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildVoiceNotePlayer(
    ChatMessage msg,
    CuteHorrorPalette palette,
    StoryNode? currentNode,
  ) {
    final isPlaying = _playingVoiceMessageId == msg.id;
    final nodeForMsg = kStoryGraph[msg.nodeId] ?? currentNode;
    final transcript = nodeForMsg?.voiceTranscript ??
        '„Hörst du mein Herz klopfen? Ich bin direkt hinter deinem Glas... ♡“';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withAlphaFactor(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primaryAccent.withAlphaFactor(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _playingVoiceMessageId = isPlaying ? null : msg.id;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primaryAccent,
                  ),
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _VoiceWaveformPainter(
                          progress: _waveController.value,
                          isPlaying: isPlaying,
                          color: palette.primaryAccent,
                          accentColor: palette.glitchCyan,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:07',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          if (isPlaying) ...[
            const SizedBox(height: 6),
            Text(
              'Transkript: $transcript',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: palette.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicatorBubble(CuteHorrorPalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(palette.borderRadius),
          border: Border.all(color: palette.primaryAccent.withAlphaFactor(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(palette.primaryAccent),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mimi tippt gerade... ♡',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInteractionPanel({
    required CorruptionState state,
    required CuteHorrorPalette palette,
    required List<StoryChoice> choices,
  }) {
    if (_showCustomKeyboard) {
      return _buildCustomInAppKeyboard(state, palette);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.borderGlow.withAlphaFactor(0.5), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Wähle deine Antwort (Gelöscht: ${state.psychProfile.totalBackspaces}×):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
              if (state.corruptionLevel >= 0.25)
                Text(
                  'Schweige-Timer: ${_remainingSilenceSeconds}s ⏳',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: _remainingSilenceSeconds <= 5
                        ? CuteHorrorPalette.cyberCrimson
                        : palette.primaryAccent,
                  ),
                )
              else
                Text(
                  'Tipp: Scrolle im Chat für Geister-Echos',
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.textSecondary.withAlphaFactor(0.75),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  backgroundColor: palette.surfaceAlt,
                  side: BorderSide(color: palette.primaryAccent),
                  label: Text(
                    '🤖 Freitext / KI-Tastatur',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  onPressed: () => setState(() => _showCustomKeyboard = true),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  backgroundColor: palette.surfaceAlt,
                  side: const BorderSide(color: CuteHorrorPalette.cyberCrimson),
                  label: Text(
                    '📱 „Ich geh auf TikTok!“',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  onPressed: state.isMimiTyping
                      ? null
                      : () async {
                          await ref
                              .read(corruptionProvider.notifier)
                              .sendCustomKeyboardMessage(
                                'Ich geh jetzt auf TikTok scrollen!',
                                wasHijacked: false,
                              );
                          _scrollToBottom();
                        },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  backgroundColor: palette.surfaceAlt,
                  side: BorderSide(color: palette.primaryAccent),
                  label: Text(
                    '💖 „Tut mir leid, hab dich lieb ♡“',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  onPressed: state.isMimiTyping
                      ? null
                      : () async {
                          await ref
                              .read(corruptionProvider.notifier)
                              .sendCustomKeyboardMessage(
                                'Tut mir leid Mimi, ich hab dich ganz doll lieb ♡',
                                wasHijacked: false,
                              );
                          _scrollToBottom();
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...choices.map((choice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ElevatedButton(
                onPressed: state.isMimiTyping
                    ? null
                    : () async {
                        HapticFeedback.selectionClick();
                        await ref
                            .read(corruptionProvider.notifier)
                            .recordTypingHesitation(
                              _hesitationWatch.elapsedMilliseconds,
                            );
                        await ref
                            .read(corruptionProvider.notifier)
                            .selectStoryChoice(choice);
                        _scrollToBottom();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.surfaceAlt,
                  foregroundColor: palette.textPrimary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: palette.primaryAccent.withAlphaFactor(0.65),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      state.corruptionLevel >= 0.55 ? '♡̷̷̷' : '♡',
                      style: TextStyle(
                        color: palette.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        choice.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomInAppKeyboard(
    CorruptionState state,
    CuteHorrorPalette palette,
  ) {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Y', 'X', 'C', 'V', 'B', 'N', 'M', ' ', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(color: palette.primaryAccent, width: 1.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _inputWasHijacked
                    ? CuteHorrorPalette.cyberCrimson
                    : palette.primaryAccent.withAlphaFactor(0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayedInputBuffer.isEmpty
                        ? (state.corruptionLevel >= 0.55
                            ? 'Tippe deine Nachricht (Mimi liest jedes Zeichen)...'
                            : 'Schreibe Mimi eine Nachricht (z.B. "Nein" oder "Stop")...')
                        : _displayedInputBuffer,
                    style: TextStyle(
                      color: _inputWasHijacked
                          ? CuteHorrorPalette.cyberCrimson
                          : palette.textPrimary,
                      fontWeight:
                          _inputWasHijacked ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_inputWasHijacked)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text(
                      'HIJACKED ♡̷̷̷',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CuteHorrorPalette.cyberCrimson,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _submitCustomKeyboardMessage,
                  icon: Icon(Icons.send_rounded, color: palette.primaryAccent),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((keyLabel) {
                  final isSpace = keyLabel == ' ';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: InkWell(
                      onTap: () =>
                          _onCustomKeyTap(keyLabel, state.corruptionLevel),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: isSpace ? 64 : 28,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: palette.primaryAccent.withAlphaFactor(0.45),
                          ),
                        ),
                        child: Text(
                          isSpace ? 'LEER' : keyLabel,
                          style: TextStyle(
                            fontSize: isSpace ? 9 : 12,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final Color accentColor;

  const _VoiceWaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const barCount = 24;
    final spacing = size.width / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = i * spacing + spacing * 0.5;
      final phase = (i * 0.45) + (isPlaying ? progress * math.pi * 2 : 0.0);
      final normalized = (math.sin(phase) * 0.5 + 0.5);
      final barHeight = isPlaying
          ? (4.0 + normalized * (size.height - 6.0))
          : (4.0 + ((i % 3) * 3.5));

      paint.color = (isPlaying && i % 4 == 0) ? accentColor : color;
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color;
  }
}
