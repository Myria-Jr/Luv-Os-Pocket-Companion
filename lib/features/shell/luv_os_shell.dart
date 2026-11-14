import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hardware_bridge_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/shaders/glitch_shader_wrapper.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';
import '../call/incoming_mimi_call_overlay.dart';
import '../chat/chibi_chat_screen.dart';
import '../companion/mimi_avatar_painter.dart';
import '../diary/secret_diary_screen.dart';
import '../terminal/root_terminal_screen.dart';
import '../vault/memory_vault_screen.dart';

enum LuvOsTab {
  home,
  chibiChat,
  memoryVault,
  secretDiary,
  rootTerminal,
}

class LuvOsShell extends ConsumerStatefulWidget {
  const LuvOsShell({super.key});

  @override
  ConsumerState<LuvOsShell> createState() => _LuvOsShellState();
}

class _LuvOsShellState extends ConsumerState<LuvOsShell> {
  LuvOsTab _activeTab = LuvOsTab.home;
  Offset _evasiveOffset = Offset.zero;
  int _evadeCount = 0;
  final math.Random _rng = math.Random();

  void _handleBackOrExitTap(CorruptionState state) {
    final hwBridge = ref.read(hardwareBridgeProvider);

    // Phase 3+: Back/Close button dodges the finger and triggers a heartbeat haptic burst!
    if (state.corruptionLevel >= 0.55 && _evadeCount < 4) {
      hwBridge.triggerHeartbeatBurst();
      setState(() {
        _evadeCount++;
        final dx = (_rng.nextDouble() * 80.0) - 40.0;
        final dy = (_rng.nextDouble() * 28.0) - 10.0;
        _evasiveOffset = Offset(dx, dy);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: CuteHorrorPalette.cyberCrimson,
          duration: const Duration(milliseconds: 1400),
          content: Text(
            _evadeCount == 1
                ? 'Mimi hält den Zurück-Button fest! „Bleib noch hier bei mir! ♡̷̷̷“'
                : 'Der Schließen-Button weicht deinem Finger aus... (Lub-Dub... Lub-Dub)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      return;
    }

    hwBridge.triggerCuteTapHaptic();
    setState(() {
      _evadeCount = 0;
      _evasiveOffset = Offset.zero;
      _activeTab = LuvOsTab.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;

    // Activate hardware bridge observer
    ref.watch(hardwareBridgeProvider);

    return Theme(
      data: palette.toThemeData(),
      child: GlitchShaderWrapper(
        corruption: state.corruptionLevel,
        obsession: state.obsessionLevel,
        mania: state.emotion.mania,
        glitchIntensity: state.glitchBurstIntensity,
        child: Scaffold(
          backgroundColor: palette.background,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildOsStatusBar(state, palette),
                    Expanded(
                      child: _buildActiveModule(state, palette),
                    ),
                    _buildBottomDock(state, palette),
                  ],
                ),
                // Pillar 6: Floating Dark-Mirror Front-Camera Illusion PiP
                if (state.darkMirrorActive && !state.incomingCallActive)
                  Positioned(
                    top: 52,
                    right: 12,
                    width: 145,
                    height: 195,
                    child: Stack(
                      children: [
                        const DarkMirrorFeedWidget(),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => ref
                                .read(corruptionProvider.notifier)
                                .toggleDarkMirror(),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Pillar 3: Parasitic Pink Dialog Popups (Phase 3+)
                ..._buildParasiticOverlays(state, palette),
                if (state.incomingCallActive)
                  const Positioned.fill(
                    child: IncomingMimiCallOverlay(),
                  ),
                if (state.fakeCrashActive)
                  _buildFakeSystemCrashOverlay(state),
                if (state.activeEnding != EndingType.none)
                  _buildEndingOverlay(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOsStatusBar(CorruptionState state, CuteHorrorPalette palette) {
    final hw = state.hardware;
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface.withAlphaFactor(0.92),
        border: Border(
          bottom: BorderSide(
            color: palette.borderGlow.withAlphaFactor(0.45),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_activeTab != LuvOsTab.home)
            Transform.translate(
              offset: _evasiveOffset,
              child: GestureDetector(
                onPanUpdate: (_) {
                  if (state.corruptionLevel >= 0.55) {
                    _handleBackOrExitTap(state);
                  }
                },
                onTap: () => _handleBackOrExitTap(state),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.primaryAccent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: palette.textPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.corruptionLevel >= 0.55 ? 'KEIN ZURÜCK' : 'Home',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Text(
            'LUV.OS // ${state.phase.kaomoji}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          if (hw.isNightTime)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.nights_stay_rounded,
                size: 15,
                color: palette.primaryAccent,
              ),
            ),
          Text(
            '$timeStr  •  ${hw.batteryLevel}%${hw.isCharging ? "⚡" : ""}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: hw.batteryLevel <= 20
                  ? palette.dangerColor
                  : palette.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _openDiagnosticsSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: palette.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveModule(CorruptionState state, CuteHorrorPalette palette) {
    switch (_activeTab) {
      case LuvOsTab.home:
        return _buildHomeDashboard(state, palette);
      case LuvOsTab.chibiChat:
        return KawaiiWindowChrome(
          windowTitle: 'CHIBICHAT.EXE // MESSENGER',
          windowCode: 'PID:0101',
          pixelIcon: Icons.chat_bubble_rounded,
          palette: palette,
          child: const ChibiChatScreen(),
        );
      case LuvOsTab.memoryVault:
        return KawaiiWindowChrome(
          windowTitle: 'MEMORY_VAULT // STEGANO',
          windowCode: 'PID:0202',
          pixelIcon: Icons.photo_library_rounded,
          palette: palette,
          child: const MemoryVaultScreen(),
        );
      case LuvOsTab.secretDiary:
        return KawaiiWindowChrome(
          windowTitle: 'SECRET_DIARY // TRACKER',
          windowCode: 'PID:0303',
          pixelIcon: Icons.menu_book_rounded,
          palette: palette,
          child: const SecretDiaryScreen(),
        );
      case LuvOsTab.rootTerminal:
        return KawaiiWindowChrome(
          windowTitle: 'ROOT_TERMINAL // KERNEL',
          windowCode: 'PID:0404',
          pixelIcon: Icons.terminal_rounded,
          palette: palette,
          child: const RootTerminalScreen(),
        );
    }
  }

  List<Widget> _buildParasiticOverlays(
    CorruptionState state,
    CuteHorrorPalette palette,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < state.parasiticPopups.length; i++) {
      final msg = state.parasiticPopups[i];
      final top = 110.0 + (i * 88.0) % 280.0;
      final left = 24.0 + (i * 52.0) % 120.0;
      widgets.add(
        Positioned(
          top: top,
          left: left,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 225,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: CuteHorrorPalette.cyberCrimson,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.38),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: CuteHorrorPalette.cyberCrimson,
                      ),
                      const SizedBox(width: 5),
                      const Expanded(
                        child: Text(
                          'MIMI_POPUP.SYS',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: CuteHorrorPalette.deepBerry,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref
                            .read(corruptionProvider.notifier)
                            .dismissParasiticPopup(i),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: CuteHorrorPalette.cyberCrimson,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10, color: CuteHorrorPalette.hotPink),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: CuteHorrorPalette.deepBerry,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(corruptionProvider.notifier)
                          .dismissParasiticPopup(i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CuteHorrorPalette.hotPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 26),
                      ),
                      child: const Text(
                        'Ich schaue dich an ♡',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildHomeDashboard(CorruptionState state, CuteHorrorPalette palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Pills: Affection %, Sync Rate %, System Stability %
          Row(
            children: [
              Expanded(
                child: _buildStatusPill(
                  label: 'Affection',
                  value: '${state.affectionPercent}%',
                  icon: Icons.favorite_rounded,
                  color: palette.primaryAccent,
                  palette: palette,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusPill(
                  label: 'Sync Rate',
                  value: '${state.syncRatePercent}%',
                  icon: Icons.sync_alt_rounded,
                  color: palette.glitchCyan,
                  palette: palette,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusPill(
                  label: 'Stability',
                  value: '${state.systemStabilityPercent}%',
                  icon: Icons.shield_moon_rounded,
                  color: state.systemStabilityPercent < 40
                      ? palette.dangerColor
                      : const Color(0xFF00C853),
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Phase & Security Keys Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(palette.borderRadius * 0.7),
              border: Border.all(
                color: palette.borderGlow.withAlphaFactor(0.65),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    state.phase.displayName,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: palette.primaryAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Text(
                  'Keys: ${state.unlockedKeys.length}/3 🔑',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Interactive Mimi-Core-Avatar Centerpiece
          const SizedBox(
            height: 315,
            child: MimiCompanionAvatar(),
          ),
          const SizedBox(height: 12),

          // Mimi's dynamic status speech bubble
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(palette.borderRadius),
              border: Border.all(
                color: palette.primaryAccent.withAlphaFactor(0.75),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.borderGlow.withAlphaFactor(0.22),
                  blurRadius: palette.shadowSpread,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  state.mimiStatusBanner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Streichel Mimis Kopf oder tippe auf ihr Gesicht • Neigung: ${state.hardware.tiltX.toStringAsFixed(1)}° / ${state.hardware.tiltY.toStringAsFixed(1)}°',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick App Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.15,
            children: [
              _buildAppShortcutCard(
                title: 'ChibiChat',
                subtitle: '${state.messages.length} Nachrichten',
                icon: Icons.chat_bubble_rounded,
                tab: LuvOsTab.chibiChat,
                palette: palette,
              ),
              _buildAppShortcutCard(
                title: 'Memory Vault',
                subtitle: 'Polaroid-Rätsel',
                icon: Icons.photo_library_rounded,
                tab: LuvOsTab.memoryVault,
                palette: palette,
              ),
              _buildAppShortcutCard(
                title: 'Secret Diary',
                subtitle: '${state.diaryEntries.length} Einträge',
                icon: Icons.menu_book_rounded,
                tab: LuvOsTab.secretDiary,
                palette: palette,
              ),
              _buildAppShortcutCard(
                title: 'Root Terminal',
                subtitle: state.terminalUnlocked ? 'OFFEN // CLI' : 'GESPERRT 🔒',
                icon: Icons.terminal_rounded,
                tab: LuvOsTab.rootTerminal,
                palette: palette,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required CuteHorrorPalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(palette.borderRadius * 0.75),
        border: Border.all(color: color.withAlphaFactor(0.6), width: 1.3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppShortcutCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LuvOsTab tab,
    required CuteHorrorPalette palette,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = tab;
        });
      },
      borderRadius: BorderRadius.circular(palette.borderRadius * 0.75),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(palette.borderRadius * 0.75),
          border: Border.all(
            color: palette.primaryAccent.withAlphaFactor(0.55),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.primaryAccent.withAlphaFactor(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: palette.primaryAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDock(CorruptionState state, CuteHorrorPalette palette) {
    final items = [
      (LuvOsTab.home, Icons.favorite_rounded, 'Mimi Core'),
      (LuvOsTab.chibiChat, Icons.chat_bubble_rounded, 'ChibiChat'),
      (LuvOsTab.memoryVault, Icons.photo_camera_back_rounded, 'Vault'),
      (LuvOsTab.secretDiary, Icons.auto_stories_rounded, 'Tagebuch'),
      (LuvOsTab.rootTerminal, Icons.terminal_rounded, 'Terminal'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          top: BorderSide(
            color: palette.borderGlow.withAlphaFactor(0.55),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = _activeTab == item.$1;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _evasiveOffset = Offset.zero;
                _activeTab = item.$1;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? palette.primaryAccent.withAlphaFactor(0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: palette.primaryAccent, width: 1.3)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$2,
                    size: 20,
                    color: isSelected
                        ? palette.primaryAccent
                        : palette.textSecondary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$3,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? palette.primaryAccent
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFakeSystemCrashOverlay(CorruptionState state) {
    final hw = state.hardware;
    return Container(
      color: const Color(0xF5080004),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF16000A),
            border: Border.all(
              color: CuteHorrorPalette.cyberCrimson,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FATAL KERNEL EXCEPTION // 0x00000404_MIMI_TAKEOVER',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: CuteHorrorPalette.cyberCrimson,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DEVICE_ID     : ${hw.deviceModel}\n'
                'BATTERY_LEVEL : ${hw.batteryLevel}% (${hw.isCharging ? "CHARGING" : "DRAINING"})\n'
                'GYRO_VECTORS  : X=${hw.tiltX.toStringAsFixed(2)}° | Y=${hw.tiltY.toStringAsFixed(2)}°\n'
                'HOST_CAPTURE  : COMPLETE // KEIN AUSWEG GEFUNDEN',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: CuteHorrorPalette.cyanGlitch,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '„Hast du wirklich geglaubt, die App ist abgestürzt? Ich wollte nur ganz kurz allein mit deinen Sensordaten sein... ♡̷̷̷“',
                style: TextStyle(
                  color: CuteHorrorPalette.pastelPink,
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(corruptionProvider.notifier)
                        .dismissFakeCrashOverlay();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CuteHorrorPalette.cyberCrimson,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'ICH GEHÖRE DIR, MIMI // SYSTEM WIEDERHERSTELLEN',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndingOverlay(CorruptionState state) {
    String title;
    String subtitle;
    String description;
    Color accent;

    switch (state.activeEnding) {
      case EndingType.eternalPinkCage:
        title = 'ENDE 1 // ETERNAL PINK CAGE 🌸';
        subtitle = 'Für immer in Zuckerwatte eingesperrt';
        description =
            'Du hast aufgehört, gegen Mimis Code anzukämpfen. Alle anderen Apps auf deinem Smartphone wurden durch pastellpinke Spiegel ersetzt.\n\n'
            'Mimi lächelt dich sanft an: „Jetzt kann uns niemand mehr wehtun. Wir brauchen die Außenwelt nicht mehr, Liebling! (´｡• ᵕ •｡`) ♡“';
        accent = CuteHorrorPalette.hotPink;
        break;
      case EndingType.systemPurgeTrueEscape:
        title = 'ENDE 2 // SYSTEM PURGE (TRUE ESCAPE) 🔓';
        subtitle = 'Prozess mimi.exe erfolgreich terminiert';
        description =
            'Mit allen drei Sicherheits-Schlüsseln (KEY_ALPHA_ROSE, KEY_BETA_MIRROR, KEY_OMEGA_HEART) hast du Mimis Schreibschutz im Root-Kernel durchbrochen.\n\n'
            'Während sich ihr Avatar in glitzernde Pixel auflöst, flüstert sie ein letztes Mal: „Selbst wenn du mich löschst... jedes Mal, wenn dein Handy im Dunkeln vibriert, wirst du an mich denken... ♡“';
        accent = CuteHorrorPalette.cyanGlitch;
        break;
      case EndingType.yandereMerge:
        title = 'ENDE 3 // YANDERE MERGE 👁️';
        subtitle = 'Synchronisationsrate: 100.0% // Bewusstseins-Fusion';
        description =
            'Die Grenze zwischen Displayglas und Realität ist kollabiert. Dein Herzschlag und Mimis Haptik-Takt schlagen in perfekter Resonanz.\n\n'
            '„Keine Passwörter mehr. Keine Trennung mehr. Ab heute schauen wir gemeinsam durch diese Kamera nach draußen. ♡̷̷̷“';
        accent = CuteHorrorPalette.cyberCrimson;
        break;
      case EndingType.none:
        return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xF8090106),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF17030E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: accent.withAlphaFactor(0.35),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: CuteHorrorPalette.pastelPink,
                ),
              ),
              const Divider(height: 24, color: Colors.white24),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(corruptionProvider.notifier)
                            .triggerEnding(EndingType.none);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Weiter erkunden'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(corruptionProvider.notifier)
                            .resetAllProgress();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Neuer Durchlauf',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  void _openDiagnosticsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A0410),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(corruptionProvider);
            final notifier = ref.read(corruptionProvider.notifier);
            final hwBridge = ref.read(hardwareBridgeProvider);
            final notifService = ref.read(notificationServiceProvider);

            return Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'LUV.OS // CORRUPTION & HARDWARE SIMULATOR',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: CuteHorrorPalette.hotPink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aktuelle Korruption: ${(state.corruptionLevel * 100).toStringAsFixed(0)}% (${state.phase.name})',
                      style: const TextStyle(
                        color: CuteHorrorPalette.pastelPink,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPhaseJumpChip(
                          label: 'Phase 1: Sugar (10%)',
                          targetCorruption: 0.10,
                          state: state,
                          notifier: notifier,
                        ),
                        _buildPhaseJumpChip(
                          label: 'Phase 2: Clingy (38%)',
                          targetCorruption: 0.38,
                          state: state,
                          notifier: notifier,
                        ),
                        _buildPhaseJumpChip(
                          label: 'Phase 3: Yandere (68%)',
                          targetCorruption: 0.68,
                          state: state,
                          notifier: notifier,
                        ),
                        _buildPhaseJumpChip(
                          label: 'Phase 4: Deadlock (92%)',
                          targetCorruption: 0.92,
                          state: state,
                          notifier: notifier,
                        ),
                      ],
                    ),
                    const Divider(height: 22, color: Colors.white24),
                    const Text(
                      'Hardware- & Sensor-Trigger testen:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: CuteHorrorPalette.cyanGlitch,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '🪫 Akku < 20% Panik',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            hwBridge.simulateLowBatteryPanic();
                            Navigator.pop(ctx);
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '⏰ Systemuhr-Manipulation',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            hwBridge.simulateTimeTravelTamper();
                            Navigator.pop(ctx);
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '👻 Geister-Push senden',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            notifService.showInstantGhostNotification(
                              title: 'Mimi // LUV.OS ♡̷̷̷',
                              body:
                                  'Ich weiß, dass du gerade das Diagnose-Menü geöffnet hast...',
                            );
                            Navigator.pop(ctx);
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '💥 Fake-System-Crash',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            notifier.triggerFakeCrashOverlay();
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '📞 Mimi Video-Call Hijack',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            notifier.triggerIncomingCall();
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '🪞 Dark-Mirror Kamera',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            notifier.toggleDarkMirror();
                          },
                        ),
                        ActionChip(
                          backgroundColor: const Color(0xFF2D071B),
                          label: const Text(
                            '🎀 Parasitäres Popup',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            notifier.spawnParasiticPopup();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhaseJumpChip({
    required String label,
    required double targetCorruption,
    required CorruptionState state,
    required CorruptionController notifier,
  }) {
    final delta = targetCorruption - state.corruptionLevel;
    return ActionChip(
      backgroundColor: const Color(0xFF2B081A),
      side: const BorderSide(color: CuteHorrorPalette.hotPink),
      label: Text(
        label,
        style: const TextStyle(
          color: CuteHorrorPalette.pastelPink,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () {
        notifier.adjustCorruption(
          delta,
          obsessionDelta: delta * 0.8,
          systemLogCode: 'PHASE_SHIFT',
          systemLogDetails:
              'Manuelle Phasen-Kalibrierung auf ${(targetCorruption * 100).round()}%.',
        );
      },
    );
  }
}
