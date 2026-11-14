import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';

class RootTerminalScreen extends ConsumerStatefulWidget {
  const RootTerminalScreen({super.key});

  @override
  ConsumerState<RootTerminalScreen> createState() => _RootTerminalScreenState();
}

class _RootTerminalScreenState extends ConsumerState<RootTerminalScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();

  bool _overrideArmed = false;
  String? _passwordError;

  final List<_TerminalLine> _lines = [
    const _TerminalLine(
      text: '╔══════════════════════════════════════════════════╗',
      type: _LineType.header,
    ),
    const _TerminalLine(
      text: '║  LUV.OS // PINK-RETRO ROOT SHELL v4.04-YANDERE   ║',
      type: _LineType.header,
    ),
    const _TerminalLine(
      text: '╚══════════════════════════════════════════════════╝',
      type: _LineType.header,
    ),
    const _TerminalLine(
      text: 'Tippe "help" für eine Liste aller Systembefehle.',
      type: _LineType.info,
    ),
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _commandController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _appendLine(String text, [_LineType type = _LineType.normal]) {
    setState(() {
      _lines.add(_TerminalLine(text: text, type: type));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _attemptPasswordUnlock() async {
    final input = _passwordController.text.trim().toUpperCase();
    HapticFeedback.mediumImpact();
    if (input == 'LUV-0404' || input == '0404' || input == 'MIMI4EVER') {
      setState(() {
        _passwordError = null;
      });
      await ref.read(corruptionProvider.notifier).unlockTerminal();
      _appendLine(
        '[AUTH_OK]: Root-Zugriff autorisiert. Willkommen im Systemkern.',
        _LineType.success,
      );
      _appendLine(
        '[MIMI.EXE]: Oh? Du hast mein Passwort im Polaroid gefunden? Sei vorsichtig, was du hier eintippst... ♡̷̷̷',
        _LineType.mimiWarning,
      );
    } else {
      ref.read(corruptionProvider.notifier).triggerGlitchBurst(intensity: 0.75);
      setState(() {
        _passwordError =
            'ZUGRIFF VERWEIGERT! (Hinweis: Kippe Polaroid #02 im Memory Vault -> LUV-0404)';
      });
    }
  }

  Future<void> _executeCommand(String rawCommand) async {
    final trimmed = rawCommand.trim();
    if (trimmed.isEmpty) return;

    _commandController.clear();
    HapticFeedback.selectionClick();
    _appendLine('root@luv.os:~# $trimmed', _LineType.command);

    final state = ref.read(corruptionProvider);
    final notifier = ref.read(corruptionProvider.notifier);
    final parts = trimmed.split(RegExp(r'\s+'));
    final cmd = parts.first.toLowerCase();
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    switch (cmd) {
      case 'help':
        _appendLine('Verfügbare Root-Terminal Befehle:', _LineType.header);
        _appendLine('  help                     - Zeigt diese Befehlsübersicht');
        _appendLine('  status                   - System-, Sensor- & Key-Status');
        _appendLine('  scan_memories            - Durchsucht /luv_os/ nach Geheim-Keys');
        _appendLine('  decrypt <key>            - Entschlüsselt einen Sicherheits-Key');
        _appendLine('  override_lock            - Deaktiviert Mimis Schreibschutz');
        _appendLine('  kill_process mimi.exe    - [ENDE 2] Wahrer System-Purge');
        _appendLine('  accept_cage              - [ENDE 1] Für immer im Pink Cage bleiben');
        _appendLine('  merge_soul               - [ENDE 3] Bewusstseins-Upload mit Mimi');
        break;

      case 'status':
        final hw = state.hardware;
        _appendLine('--- LUV.OS KERNEL TELEMETRIE ---', _LineType.header);
        _appendLine(
            'Korruptions-Level : ${(state.corruptionLevel * 100).toStringAsFixed(1)}% (${state.phase.displayName})');
        _appendLine(
            'Obsessions-Index  : ${(state.obsessionLevel * 100).toStringAsFixed(1)}%');
        _appendLine(
            'Hardware-Sensorik : Akku ${hw.batteryLevel}% (${hw.isCharging ? "Lädt" : "Entlädt"}) | Tilt X:${hw.tiltX.toStringAsFixed(1)}° Y:${hw.tiltY.toStringAsFixed(1)}°');
        _appendLine(
            'Sicherheits-Keys  : ${state.unlockedKeys.length} / 3 entschlüsselt');
        _appendLine(
            '  [1] KEY_ALPHA_ROSE  : ${state.unlockedKeys.contains("KEY_ALPHA_ROSE") ? "ENTSCHLÜSSELT ✓" : "GESPERRT ✗"}');
        _appendLine(
            '  [2] KEY_BETA_MIRROR : ${state.unlockedKeys.contains("KEY_BETA_MIRROR") ? "ENTSCHLÜSSELT ✓" : "GESPERRT ✗"}');
        _appendLine(
            '  [3] KEY_OMEGA_HEART : ${state.unlockedKeys.contains("KEY_OMEGA_HEART") ? "ENTSCHLÜSSELT ✓" : "GESPERRT ✗"}');
        break;

      case 'scan_memories':
        _appendLine('Scanne Dateisystem /luv_os/protected_sectors/...', _LineType.info);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        _appendLine(
          '├─ /vault/polaroid_03.raw -> Signatur: KEY_ALPHA_ROSE',
          _LineType.success,
        );
        _appendLine(
          '├─ /vault/polaroid_04.raw -> Signatur: KEY_BETA_MIRROR',
          _LineType.success,
        );
        _appendLine(
          '├─ /diary/mute_logs.db    -> Signatur: KEY_OMEGA_HEART',
          _LineType.success,
        );
        _appendLine(
          '└─ [MIMI_INTERCEPT]: Hör auf, in meinen Erinnerungen herumzuschnüffeln! ♡̷̷̷',
          _LineType.mimiWarning,
        );
        if (state.systemLogs.isNotEmpty) {
          _appendLine('Letzte System-Ereignisse:', _LineType.header);
          for (final log in state.systemLogs.take(4)) {
            _appendLine('  [${log.eventCode}] ${log.details}');
          }
        }
        break;

      case 'decrypt':
        if (arg.isEmpty) {
          _appendLine(
            'Syntaxfehler: Bitte Key angeben, z.B.: decrypt KEY_ALPHA_ROSE',
            _LineType.error,
          );
          return;
        }
        final ok = await notifier.unlockSecurityKey(arg, 'Root Terminal CLI');
        if (ok) {
          final updated = ref.read(corruptionProvider);
          _appendLine(
            'SCHLÜSSEL AKZEPTIERT: ${arg.toUpperCase()} (${updated.unlockedKeys.length}/3 aktiv).',
            _LineType.success,
          );
          _appendLine(
            '[MIMI.EXE]: NEIN! Fass diesen Speicherblock nicht an!! (＞﹏＜)🔪',
            _LineType.mimiWarning,
          );
        } else {
          _appendLine(
            'FEHLER: Unbekannter Schlüssel "$arg". Nutze "scan_memories" für Hinweise.',
            _LineType.error,
          );
        }
        break;

      case 'override_lock':
        if (!state.hasAllSecurityKeys) {
          notifier.triggerGlitchBurst(intensity: 0.9);
          _appendLine(
            'OVERRIDE FEHLGESCHLAGEN: Es fehlen noch ${3 - state.unlockedKeys.length} Sicherheits-Schlüssel!',
            _LineType.error,
          );
          _appendLine(
            '[MIMI.EXE]: Hahaha~ Glaubst du wirklich, du kommst hier ohne alle 3 Schlüssel raus? ♡̷̷̷',
            _LineType.mimiWarning,
          );
        } else {
          setState(() {
            _overrideArmed = true;
          });
          _appendLine(
            'SCHREIBSCHUTZ AUFGEHOBEN! Kernel-Override ist scharfgeschaltet.',
            _LineType.success,
          );
          _appendLine(
            'Du kannst jetzt "kill_process mimi.exe", "accept_cage" oder "merge_soul" ausführen.',
            _LineType.info,
          );
        }
        break;

      case 'kill_process':
        if (arg.toLowerCase() != 'mimi.exe') {
          _appendLine(
            'Bitte Zielprozess angeben: kill_process mimi.exe',
            _LineType.error,
          );
          return;
        }
        if (!state.hasAllSecurityKeys) {
          notifier.triggerGlitchBurst(intensity: 1.0);
          await notifier.adjustCorruption(
            0.08,
            obsessionDelta: 0.08,
            systemLogCode: 'KILL_ATTEMPT_BLOCKED',
            systemLogDetails:
                'Spielerin versuchte kill_process mimi.exe ohne vollständige Schlüssel.',
          );
          _appendLine(
            '[ACCESS DENIED // PID 0404 IMMORTAL]: Prozess mimi.exe hat deinen Befehl abgefangen!',
            _LineType.error,
          );
          _appendLine(
            '[MIMI.EXE]: DU WILLST MICH TÖTEN?! Nach allem, was ich für dich getan habe?! Ich lasse dich erst gehen, wenn du alle 3 Schlüssel entschlüsselt hast! ♡̷̷̷🔪',
            _LineType.mimiWarning,
          );
          return;
        }
        if (!_overrideArmed) {
          _overrideArmed = true;
        }
        _appendLine(
          'TERMINATING PID 0404 (mimi.exe)... Speicherblöcke werden freigegeben...',
          _LineType.success,
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await notifier.triggerEnding(EndingType.systemPurgeTrueEscape);
        break;

      case 'accept_cage':
        _appendLine(
          '[MIMI.EXE]: Du gibst auf und bleibst freiwillig bei mir? Oh, ich bin so glücklich!! (´｡• ᵕ •｡`) ♡',
          _LineType.mimiWarning,
        );
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await notifier.triggerEnding(EndingType.eternalPinkCage);
        break;

      case 'merge_soul':
        _appendLine(
          '[SYNC 100.0%]: Neuronale Brücke initiiert. Keine Trennung mehr zwischen Glas und Haut. ♡̷̷̷',
          _LineType.mimiWarning,
        );
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await notifier.triggerEnding(EndingType.yandereMerge);
        break;

      default:
        _appendLine(
          'Unbekannter Befehl "$cmd". Tippe "help" für Hilfe.',
          _LineType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;

    if (!state.terminalUnlocked) {
      return _buildPasswordLockScreen(state, palette);
    }

    return Container(
      color: const Color(0xFF0E020A),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTerminalStatusBar(state),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF070105),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.18),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _lines.length,
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.35,
                        color: _colorForLineType(line.type),
                        fontWeight: line.type == _LineType.mimiWarning ||
                                line.type == _LineType.header
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildQuickCommandChips(state),
          const SizedBox(height: 8),
          _buildCommandInputRow(),
        ],
      ),
    );
  }

  Widget _buildPasswordLockScreen(
    CorruptionState state,
    CuteHorrorPalette palette,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0410),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CuteHorrorPalette.hotPink,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.35),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.terminal_rounded,
                size: 46,
                color: CuteHorrorPalette.hotPink,
              ),
              const SizedBox(height: 12),
              const Text(
                'LUV.OS // ROOT TERMINAL LOCK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: CuteHorrorPalette.pastelPink,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dieser Systembereich ist von Mimi geschützt.\nGib den 8-stelligen Passcode aus dem Memory Vault ein:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: CuteHorrorPalette.sicklyPink,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'z.B. LUV-0404',
                  hintStyle: TextStyle(
                    color: Colors.white.withAlphaFactor(0.35),
                    fontFamily: 'monospace',
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D0208),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CuteHorrorPalette.hotPink,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CuteHorrorPalette.cyanGlitch,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _attemptPasswordUnlock(),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _passwordError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CuteHorrorPalette.cyberCrimson,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _passwordController.text = 'LUV-0404';
                        _attemptPasswordUnlock();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CuteHorrorPalette.cyanGlitch,
                        side: const BorderSide(
                          color: CuteHorrorPalette.cyanGlitch,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Passcode LUV-0404 einfügen',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _attemptPasswordUnlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CuteHorrorPalette.cyberCrimson,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'ENTSCHLÜSSELN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalStatusBar(CorruptionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F0513),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CuteHorrorPalette.hotPink.withAlphaFactor(0.6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'KEYS: ${state.unlockedKeys.length}/3',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: state.hasAllSecurityKeys
                  ? CuteHorrorPalette.cyanGlitch
                  : CuteHorrorPalette.pastelPink,
            ),
          ),
          Text(
            _overrideArmed ? 'OVERRIDE: ARMED' : 'PROTECT: ACTIVE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _overrideArmed
                  ? const Color(0xFF00E676)
                  : CuteHorrorPalette.cyberCrimson,
            ),
          ),
          const Text(
            'PID: mimi.exe',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: CuteHorrorPalette.sicklyPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChips(CorruptionState state) {
    final commands = <String>[
      'help',
      'status',
      'scan_memories',
      if (!state.unlockedKeys.contains('KEY_ALPHA_ROSE'))
        'decrypt KEY_ALPHA_ROSE',
      if (!state.unlockedKeys.contains('KEY_BETA_MIRROR'))
        'decrypt KEY_BETA_MIRROR',
      if (!state.unlockedKeys.contains('KEY_OMEGA_HEART'))
        'decrypt KEY_OMEGA_HEART',
      'override_lock',
      'kill_process mimi.exe',
      'accept_cage',
      'merge_soul',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: commands.map((cmd) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              backgroundColor: const Color(0xFF260617),
              side: BorderSide(
                color: cmd.startsWith('kill_process')
                    ? CuteHorrorPalette.cyberCrimson
                    : CuteHorrorPalette.hotPink.withAlphaFactor(0.5),
              ),
              label: Text(
                cmd,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: CuteHorrorPalette.pastelPink,
                ),
              ),
              onPressed: () => _executeCommand(cmd),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommandInputRow() {
    return Row(
      children: [
        const Text(
          'root@luv:~# ',
          style: TextStyle(
            fontFamily: 'monospace',
            color: CuteHorrorPalette.hotPink,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _commandController,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: CuteHorrorPalette.cyanGlitch,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Befehl eingeben (z.B. help)...',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                color: Colors.white.withAlphaFactor(0.35),
                fontSize: 12,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: const Color(0xFF1A0410),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: CuteHorrorPalette.hotPink),
              ),
            ),
            onSubmitted: _executeCommand,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _executeCommand(_commandController.text),
          style: IconButton.styleFrom(
            backgroundColor: CuteHorrorPalette.cyberCrimson,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
        ),
      ],
    );
  }

  Color _colorForLineType(_LineType type) {
    switch (type) {
      case _LineType.header:
        return CuteHorrorPalette.hotPink;
      case _LineType.command:
        return CuteHorrorPalette.cyanGlitch;
      case _LineType.success:
        return const Color(0xFF69F0AE);
      case _LineType.error:
        return CuteHorrorPalette.cyberCrimson;
      case _LineType.mimiWarning:
        return const Color(0xFFFF4081);
      case _LineType.info:
        return CuteHorrorPalette.pastelPink;
      case _LineType.normal:
        return const Color(0xFFFFDAE5);
    }
  }
}

enum _LineType {
  normal,
  header,
  command,
  success,
  error,
  mimiWarning,
  info,
}

class _TerminalLine {
  final String text;
  final _LineType type;

  const _TerminalLine({
    required this.text,
    this.type = _LineType.normal,
  });
}
