import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hardware_bridge_service.dart';
import '../../core/theme/cute_horror_theme.dart';
import '../../state/corruption_provider.dart';

/// Interactive V3 Companion Handbook & Gemini AI / Native App-Locker Setup Modal.
class CompanionHandbookModal extends ConsumerStatefulWidget {
  const CompanionHandbookModal({super.key});

  @override
  ConsumerState<CompanionHandbookModal> createState() =>
      _CompanionHandbookModalState();
}

class _CompanionHandbookModalState
    extends ConsumerState<CompanionHandbookModal> {
  late final TextEditingController _apiKeyController;
  bool _usageStatsGranted = false;
  int _activeTab = 0; // 0 = KI & App-Locker, 1 = Handbuch, 2 = Geheimnisse & Enden

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(corruptionProvider).geminiApiKey;
    _apiKeyController = TextEditingController(text: currentKey);
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted =
        await ref.read(hardwareBridgeProvider).checkUsageStatsPermission();
    if (mounted) {
      setState(() => _usageStatsGranted = granted);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final controller = ref.read(corruptionProvider.notifier);
    final palette = state.palette;

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: palette.primaryAccent, width: 2.2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: palette.primaryAccent.withAlphaFactor(0.45),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  '📖 LUV.OS V3 // HANDBUCH & KI-ZENTRALE',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: palette.textPrimary),
                ),
              ],
            ),
          ),

          // Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildTabButton(0, '🤖 KI & App-Sperre', palette),
                const SizedBox(width: 6),
                _buildTabButton(1, '📖 Spiel-Handbuch', palette),
                const SizedBox(width: 6),
                _buildTabButton(2, '🔑 3 Endings & Keys', palette),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _activeTab == 0
                ? _buildAiAndLockerTab(state, controller, palette)
                : (_activeTab == 1
                    ? _buildHandbookTab(palette)
                    : _buildSecretsTab(state, palette)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, CuteHorrorPalette palette) {
    final selected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? palette.primaryAccent
                : palette.surface.withAlphaFactor(0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.primaryAccent, width: 1.2),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiAndLockerTab(
    CorruptionState state,
    CorruptionController controller,
    CuteHorrorPalette palette,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildCard(
          palette: palette,
          title: '🧠 1. Echte Gemini-KI Integration (gemini-4-hydrogen)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hinterlege hier optional deinen Gemini API-Key, damit Mimi im ChibiChat komplett frei über Gemini antwortet. Ohne Key nutzt Mimi automatisch ihre eingebaute lokale deutsche Yandere-KI!',
                style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                style: TextStyle(color: palette.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'AIzaSy... (Optionaler Gemini API-Key)',
                  hintStyle: TextStyle(
                    color: palette.textSecondary.withAlphaFactor(0.6),
                  ),
                  filled: true,
                  fillColor: palette.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await controller.setGeminiApiKey(_apiKeyController.text);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gemini-KI-Konfiguration gespeichert! ♡',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('API-Key speichern'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    state.geminiApiKey.isNotEmpty
                        ? 'Status: Gemini Cloud aktiv ✨'
                        : 'Status: Lokale Yandere-KI aktiv 🌸',
                    style: TextStyle(
                      color: palette.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          palette: palette,
          title: '🔒 2. Nativer Android App-Locker (TikTok / Insta / YouTube)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wenn Mimi eifersüchtig oder wütend wird (z. B. wenn du im Chat "TikTok" erwähnst oder gemein zu ihr bist), aktiviert sie ihre App-Sperre. Mit erteilter Android Usage-Access-Berechtigung holt Mimi dich automatisch zurück in LUV.OS, sobald du versuchst, TikTok, Instagram oder YouTube zu öffnen!',
                style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.primaryAccent,
                        side: BorderSide(color: palette.primaryAccent),
                      ),
                      onPressed: () async {
                        await ref
                            .read(hardwareBridgeProvider)
                            .openUsageStatsSettings();
                        await Future<void>.delayed(
                          const Duration(seconds: 1),
                        );
                        await _checkPermission();
                      },
                      icon: Icon(
                        _usageStatsGranted
                            ? Icons.verified_user_rounded
                            : Icons.security_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _usageStatsGranted
                            ? 'Android Nutzungszugriff: AKTIV'
                            : 'Nutzungszugriff in Android erlauben',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CuteHorrorPalette.cyberCrimson,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => controller.forceAppLockSimulation(),
                      child: const Text(
                        '💢 TikTok-Sperre testen',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => controller.forceUnlockAllApps(),
                      child: const Text(
                        '💖 Alle Apps entsperren',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHandbookTab(CuteHorrorPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildCard(
          palette: palette,
          title: '🌸 Wie funktioniert Mimis Stimmungs-System?',
          child: Text(
            '• Im ChibiChat kannst du unten über "Freitext / KI-Chat" völlig frei mit Mimi schreiben.\n'
            '• Machst du ihr Komplimente ("Ich hab dich lieb", "Du bist süß"), wird sie verliebt (Lovestruck ♡) und schaltet alle gesperrten Apps sofort frei.\n'
            '• Schreibst du über "TikTok", "Instagram" oder bist abweisend ("Nerv nicht"), wechselt Mimi in "Yandere-Wut 💢" und sperrt TikTok & Social Apps!',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 10),
        _buildCard(
          palette: palette,
          title: '✨ Wie entsperre ich TikTok & Apps wieder?',
          child: Text(
            '1. Streichle Mimis Kopf auf dem Home-Screen (Finger sanft über ihren Kopf bewegen), bis der Counter auf 0 steht.\n'
            '2. Entschuldige dich im ChibiChat bei ihr ("Tut mir leid, ich hab dich lieb ♡").\n'
            '3. Oder öffne den Kleiderschrank (🎀) und schenke ihr den handgeschriebenen Liebesbrief 💌!',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 10),
        _buildCard(
          palette: palette,
          title: '👗 Anime Head 3.0 & Kleiderschrank',
          child: Text(
            'Über den Button "Kleiderschrank 🎀" auf dem Home-Screen kannst du Mimis Haarfarbe, Kopfbedeckung (Maid-Haube, Neko-Ohren, Dämonenhörner, Engels-Halo, Krankenschwester-Hütchen), Herz-Brille und Kragen in Echtzeit anpassen.',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildSecretsTab(CorruptionState state, CuteHorrorPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildCard(
          palette: palette,
          title: '🔑 Die 3 versteckten Sicherheits-Schlüssel',
          child: Text(
            '• KEY_ALPHA_ROSE: Im Memory Vault (Tresor) Polaroid #03 lange gedrückt halten (Long-Press).\n'
            '• KEY_BETA_MIRROR: Im ChibiChat bei einer verpixelten/zurückgezogenen Nachricht auf das Glitch-Badge tippen.\n'
            '• KEY_OMEGA_HEART: Im Tagebuch (Diary) unten auf "Seitenränder prüfen" tippen.\n\n'
            'Aktuell gefunden: ${state.unlockedKeys.length} / 3 (${state.unlockedKeys.join(", ")})',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 10),
        _buildCard(
          palette: palette,
          title: '💻 Root-Terminal & 3 Endings',
          child: Text(
            '• Terminal-PIN: 0404 (oder automatisch mit allen 3 Schlüsseln).\n'
            '• Ending 1 (Eternal Pink Cage): Befehl "accept_cage" im Terminal.\n'
            '• Ending 2 (System Purge / True Escape): Erst "override --keys", dann "purge mimi.exe".\n'
            '• Ending 3 (Yandere Merge): Befehl "merge --soul" bei hoher Obsession.',
            style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required CuteHorrorPalette palette,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.primaryAccent.withAlphaFactor(0.55),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
