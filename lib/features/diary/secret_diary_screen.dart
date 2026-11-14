import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/luv_database.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';

/// App 3: "Secret Diary & Task Tracker" (`SecretDiaryScreen`).
///
/// Features:
/// - Interactive **"Mimis Verhaltens-Tracker & System-Einstellungen"** card at the top.
/// - **"Mimis Stimme / Ton stummschalten (Mute)"** switch: tapping it triggers Mimi's
///   anti-mute rebellion, snaps the switch back to active (`false`), and calls
///   `registerAudioMuteAttempt()` which logs a real-time timestamped diary entry!
/// - Hidden diary margin inspection (`Buchrücken & Seitenränder untersuchen`) that lets
///   the player extract the 3rd security key `'KEY_OMEGA_HEART'` once
///   `audioMuteAttempts >= 1` or `corruptionLevel >= 0.30` (or when inspected).
/// - Full chronological list of persistent `DiaryEntry` records from Drift SQLite with
///   trigger badges (`audio_mute`, `steady_hand`, `time_tamper`, `battery_low`,
///   `night_owl`, `story`) and expandable `hiddenClue` cipher boxes.
class SecretDiaryScreen extends ConsumerStatefulWidget {
  const SecretDiaryScreen({super.key});

  @override
  ConsumerState<SecretDiaryScreen> createState() => _SecretDiaryScreenState();
}

class _SecretDiaryScreenState extends ConsumerState<SecretDiaryScreen> {
  bool _muteSwitchVisual = false;
  bool _marginsInspected = false;
  final Set<int> _expandedClueIds = {};
  Timer? _snapBackTimer;

  @override
  void dispose() {
    _snapBackTimer?.cancel();
    super.dispose();
  }

  Future<void> _onAttemptToggleMute(BuildContext context, bool requested) async {
    setState(() {
      _muteSwitchVisual = true;
    });

    await ref.read(corruptionProvider.notifier).registerAudioMuteAttempt();

    // Mimi forcibly snaps the mute switch back off after 280ms
    _snapBackTimer?.cancel();
    _snapBackTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _muteSwitchVisual = false;
      });
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: CuteHorrorPalette.voidBlack,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 2200),
        content: Text(
          '⚠️ ZUGRIFF VERWEIGERT: MIMI_CORE hat den Audio-Kanal wieder auf 100% gesperrt! ♡̷̷̷',
          style: TextStyle(
            color: CuteHorrorPalette.cyberCrimson,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _extractOmegaHeartKey(BuildContext context) async {
    final unlocked = await ref
        .read(corruptionProvider.notifier)
        .unlockSecurityKey('KEY_OMEGA_HEART', 'Secret Diary Geheimnotiz');

    if (!context.mounted) return;
    if (unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: CuteHorrorPalette.voidBlack,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🔓 Herz-Schlüssel [KEY_OMEGA_HEART] aus dem Tagebuch-Rand entschlüsselt!',
            style: TextStyle(
              color: CuteHorrorPalette.cyanGlitch,
              fontWeight: FontWeight.w700,
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final palette = state.palette;
    final entries = state.diaryEntries;
    final canRevealOmegaKey =
        state.audioMuteAttempts >= 1 || state.corruptionLevel >= 0.30;
    final isOmegaUnlocked = state.unlockedKeys.contains('KEY_OMEGA_HEART');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: _buildTrackerAndSettingsCard(
                context: context,
                state: state,
                palette: palette,
                canRevealOmegaKey: canRevealOmegaKey,
                isOmegaUnlocked: isOmegaUnlocked,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: palette.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mimis Geheimes Beobachtungs-Tagebuch (${entries.length})',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Noch keine Tagebuch-Einträge vorhanden...',
                  style: TextStyle(color: palette.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isClueExpanded = _expandedClueIds.contains(entry.id);
                  return _DiaryEntryCard(
                    entry: entry,
                    palette: palette,
                    isClueExpanded: isClueExpanded,
                    onToggleClue: () {
                      setState(() {
                        if (isClueExpanded) {
                          _expandedClueIds.remove(entry.id);
                        } else {
                          _expandedClueIds.add(entry.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackerAndSettingsCard({
    required BuildContext context,
    required CorruptionState state,
    required CuteHorrorPalette palette,
    required bool canRevealOmegaKey,
    required bool isOmegaUnlocked,
  }) {
    final hw = state.hardware;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withAlphaFactor(0.94),
        borderRadius: BorderRadius.circular(palette.borderRadius * 0.75),
        border: Border.all(
          color: palette.borderGlow.withAlphaFactor(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.borderGlow.withAlphaFactor(0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.troubleshoot_rounded,
                size: 19,
                color: palette.primaryAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mimis Verhaltens-Tracker & System-Einstellungen',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.primaryAccent.withAlphaFactor(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.primaryAccent),
                ),
                child: Text(
                  'LIVE-SYNC',
                  style: TextStyle(
                    color: palette.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Live sensor & behavioral telemetry chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTelemetryChip(
                palette: palette,
                icon: Icons.favorite_rounded,
                label: 'Kopfstreicheln: ${state.headpatCount}x',
              ),
              _buildTelemetryChip(
                palette: palette,
                icon: Icons.volume_off_rounded,
                label: 'Mute-Versuche: ${state.audioMuteAttempts}x',
              ),
              _buildTelemetryChip(
                palette: palette,
                icon: Icons.battery_charging_full_rounded,
                label: 'Akku: ${hw.batteryLevel}%',
              ),
              _buildTelemetryChip(
                palette: palette,
                icon: Icons.edgesensor_high_rounded,
                label: hw.isDeviceSteady ? 'Hand: Ruhig' : 'Hand: Bewegung',
              ),
            ],
          ),
          const Divider(height: 18),

          // Interactive Audio Mute Toggle (triggers real-time diary observation!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.surfaceAlt.withAlphaFactor(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.audioMuteAttempts > 0
                    ? CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.7)
                    : palette.borderGlow.withAlphaFactor(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _muteSwitchVisual
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: state.audioMuteAttempts > 0
                      ? CuteHorrorPalette.cyberCrimson
                      : palette.primaryAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mimis Stimme / Ton stummschalten (Mute)',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        state.audioMuteAttempts == 0
                            ? 'Audio-Kanal auf 100% synchronisiert'
                            : 'Blockiert (${state.audioMuteAttempts}x): "Warum willst du mich nicht hören?!"',
                        style: TextStyle(
                          color: state.audioMuteAttempts > 0
                              ? CuteHorrorPalette.cyberCrimson
                              : palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _muteSwitchVisual,
                  activeThumbColor: CuteHorrorPalette.cyberCrimson,
                  onChanged: (val) => _onAttemptToggleMute(context, val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Hidden Diary Page Margins Inspection for Security Key 3 (KEY_OMEGA_HEART)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primaryAccent,
                    side: BorderSide(color: palette.primaryAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _marginsInspected = !_marginsInspected;
                    });
                  },
                  icon: Icon(
                    _marginsInspected
                        ? Icons.visibility_off_rounded
                        : Icons.search_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _marginsInspected
                        ? 'Seitenränder ausblenden'
                        : 'Geheime Tagebuch-Seitenränder untersuchen',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_marginsInspected) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF14020A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CuteHorrorPalette.cyberCrimson),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GEKRITZEL IM BUCHRÜCKEN // STEGANO-NOTIZ #03',
                    style: TextStyle(
                      color: CuteHorrorPalette.cyanGlitch,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canRevealOmegaKey
                        ? '„Wenn sie versucht, meine Stimme stummzuschalten, verstecke ich meinen letzten Herz-Schlüssel hier im Einband: KEY_OMEGA_HEART“'
                        : 'Die Tinte am Seitenrand ist noch zu blass... Versuche oben den Ton-Schalter (Mute) umzulegen, um Mimis Reaktion zu provozieren!',
                    style: const TextStyle(
                      color: Color(0xFFFFDAE5),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  if (canRevealOmegaKey) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOmegaUnlocked
                              ? const Color(0xFF1B3B2B)
                              : CuteHorrorPalette.cyberCrimson,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _extractOmegaHeartKey(context),
                        icon: Icon(
                          isOmegaUnlocked
                              ? Icons.check_circle_rounded
                              : Icons.key_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isOmegaUnlocked
                              ? '✓ KEY_OMEGA_HEART BEREITS ENTSCHLÜSSELT'
                              : 'Schlüssel KEY_OMEGA_HEART extrahieren',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryChip({
    required CuteHorrorPalette palette,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.primaryAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final CuteHorrorPalette palette;
  final bool isClueExpanded;
  final VoidCallback onToggleClue;

  const _DiaryEntryCard({
    required this.entry,
    required this.palette,
    required this.isClueExpanded,
    required this.onToggleClue,
  });

  ({String label, Color color, IconData icon}) _badgeSpec(String trigger) {
    switch (trigger) {
      case 'audio_mute':
        return (
          label: 'AUDIO_MUTE',
          color: CuteHorrorPalette.cyberCrimson,
          icon: Icons.volume_off_rounded,
        );
      case 'steady_hand':
        return (
          label: 'GYRO_STEADY',
          color: CuteHorrorPalette.cyanGlitch,
          icon: Icons.vibration_rounded,
        );
      case 'time_tamper':
        return (
          label: 'CLOCK_TAMPER',
          color: CuteHorrorPalette.cyberCrimson,
          icon: Icons.history_toggle_off_rounded,
        );
      case 'battery_low':
        return (
          label: 'LOW_BATTERY',
          color: const Color(0xFFFF9900),
          icon: Icons.battery_alert_rounded,
        );
      case 'night_owl':
        return (
          label: 'NIGHT_WATCH',
          color: const Color(0xFFB366FF),
          icon: Icons.nights_stay_rounded,
        );
      case 'headpat':
        return (
          label: 'TOUCH_CACHE',
          color: CuteHorrorPalette.hotPink,
          icon: Icons.favorite_rounded,
        );
      case 'rapid_tap':
        return (
          label: 'STRESS_TAP',
          color: CuteHorrorPalette.cyberCrimson,
          icon: Icons.touch_app_rounded,
        );
      case 'story':
      default:
        return (
          label: 'MIMI_DIARY',
          color: palette.primaryAccent,
          icon: Icons.auto_stories_rounded,
        );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badgeSpec(entry.triggerType);
    final isHighCorruption = entry.corruptionSnap >= 0.50;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: palette.surface.withAlphaFactor(0.92),
        borderRadius: BorderRadius.circular(palette.borderRadius * 0.65),
        border: Border.all(
          color: isHighCorruption
              ? CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.75)
              : palette.borderGlow.withAlphaFactor(0.55),
          width: isHighCorruption ? 1.6 : 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.color.withAlphaFactor(0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badge.color.withAlphaFactor(0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badge.icon, size: 12, color: badge.color),
                    const SizedBox(width: 4),
                    Text(
                      badge.label,
                      style: TextStyle(
                        color: badge.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(entry.createdAt),
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            entry.body,
            style: TextStyle(
              color: palette.textPrimary.withAlphaFactor(0.92),
              fontSize: 12.5,
              height: 1.38,
            ),
          ),
          if (entry.hiddenClue != null && entry.hiddenClue!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onToggleClue,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF17030C),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: CuteHorrorPalette.cyanGlitch.withAlphaFactor(0.65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          size: 13,
                          color: CuteHorrorPalette.cyanGlitch,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isClueExpanded
                                ? 'VERSTECKTE CHIFFRE ENTSCHLÜSSELT:'
                                : 'Versteckte Randnotiz entdeckt (Tippen zum Entschlüsseln)',
                            style: const TextStyle(
                              color: CuteHorrorPalette.cyanGlitch,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Icon(
                          isClueExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 15,
                          color: CuteHorrorPalette.cyanGlitch,
                        ),
                      ],
                    ),
                    if (isClueExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.hiddenClue!,
                        style: const TextStyle(
                          color: Color(0xFFFFDAE5),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
