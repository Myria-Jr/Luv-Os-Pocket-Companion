import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cute_horror_theme.dart';
import '../../data/models/mimi_wardrobe_models.dart';
import '../../state/corruption_provider.dart';
import '../companion/mimi_avatar_painter.dart';

/// Interactive Wardrobe (Ankleide-System) & Gift Boutique for Mimi's Anime Head 3.0.
class MimiWardrobeSheet extends ConsumerStatefulWidget {
  const MimiWardrobeSheet({super.key});

  @override
  ConsumerState<MimiWardrobeSheet> createState() => _MimiWardrobeSheetState();
}

class _MimiWardrobeSheetState extends ConsumerState<MimiWardrobeSheet> {
  int _selectedTabIndex = 0; // 0 = Styling & Outfits, 1 = Geschenke & Besänftigung

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(corruptionProvider);
    final controller = ref.read(corruptionProvider.notifier);
    final palette = state.palette;
    final loadout = state.wardrobe;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: palette.primaryAccent, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: palette.borderGlow.withAlphaFactor(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  '🎀 MIMIS KLEIDERSCHRANK & GESCHENKE',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
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

          // Live Preview of Mimi's Anime Head 3.0 with current outfit & mood
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface.withAlphaFactor(0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.primaryAccent.withAlphaFactor(0.55),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                const MimiCompanionAvatar(
                  size: 108,
                  showSpeechBubble: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.primaryAccent.withAlphaFactor(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Laune: ${state.moodState.germanLabel}',
                          style: TextStyle(
                            color: palette.primaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.mimiStatusBanner,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Sub-tabs: Styling vs. Gifts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: '👗 Anime-Styling (4 Slots)',
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: '🎁 Geschenke & Besänftigen',
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _selectedTabIndex == 0
                ? _buildStylingTab(loadout, controller, palette)
                : _buildGiftsTab(state, controller, palette),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required CuteHorrorPalette palette,
  }) {
    final selected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? palette.primaryAccent
              : palette.surface.withAlphaFactor(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.primaryAccent, width: 1.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : palette.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStylingTab(
    MimiWardrobeLoadout loadout,
    CorruptionController controller,
    CuteHorrorPalette palette,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildSectionTitle('✨ 3D-Perspektive & Kamera-Zoom', palette),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: palette.primaryAccent.withAlphaFactor(0.45),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.view_in_ar_rounded,
                      size: 16, color: palette.primaryAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3D-Tiefen-Parallax: ${(loadout.depth3dIntensity * 100).round()}%',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: Slider(
                      value: loadout.depth3dIntensity,
                      min: 0.0,
                      max: 1.5,
                      activeColor: palette.primaryAccent,
                      onChanged: (v) {
                        controller.updateWardrobe(
                          loadout.copyWith(depth3dIntensity: v),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.zoom_in_rounded,
                      size: 16, color: palette.primaryAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modell-Größe: ${(loadout.avatarScale * 100).round()}%',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 145,
                    child: Slider(
                      value: loadout.avatarScale,
                      min: 0.85,
                      max: 1.20,
                      activeColor: palette.primaryAccent,
                      onChanged: (v) {
                        controller.updateWardrobe(
                          loadout.copyWith(avatarScale: v),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('1. 3D-Frisur-Form (Hair Geometry)', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiHairGeometry.values.map((geom) {
            final selected = loadout.hairGeometry == geom;
            return ChoiceChip(
              label: Text('${geom.iconEmoji} ${geom.label}'),
              selected: selected,
              selectedColor: palette.primaryAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(hairGeometry: geom));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('2. Haarfarbe & Anime-Shading', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiHairStyle.values.map((style) {
            final selected = loadout.hairStyle == style;
            return ChoiceChip(
              label: Text(style.label),
              selected: selected,
              selectedColor: style.primaryColor,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(hairStyle: style));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('3. Augenfarbe & Iris-Leuchten', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiEyeColor.values.map((eye) {
            final selected = loadout.eyeColor == eye;
            return ChoiceChip(
              label: Text(eye.label),
              selected: selected,
              selectedColor: palette.primaryAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(eyeColor: eye));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('4. Kopfbedeckung (Headwear)', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiHeadwear.values.map((hw) {
            final selected = loadout.headwear == hw;
            return ChoiceChip(
              label: Text('${hw.iconEmoji} ${hw.label}'),
              selected: selected,
              selectedColor: palette.primaryAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(headwear: hw));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('5. Gesichts-Accessoire', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiFaceAccessory.values.map((acc) {
            final selected = loadout.faceAccessory == acc;
            return ChoiceChip(
              label: Text('${acc.iconEmoji} ${acc.label}'),
              selected: selected,
              selectedColor: palette.primaryAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(faceAccessory: acc));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildSectionTitle('6. Kragen & Outfit-Stil', palette),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MimiCollarStyle.values.map((collar) {
            final selected = loadout.collarStyle == collar;
            return ChoiceChip(
              label: Text('${collar.iconEmoji} ${collar.label}'),
              selected: selected,
              selectedColor: palette.primaryAccent,
              labelStyle: TextStyle(
                color: selected ? Colors.white : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              onSelected: (_) {
                controller.updateWardrobe(loadout.copyWith(collarStyle: collar));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGiftsTab(
    CorruptionState state,
    CorruptionController controller,
    CuteHorrorPalette palette,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        if (state.appLockActive)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CuteHorrorPalette.cyberCrimson.withAlphaFactor(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CuteHorrorPalette.cyberCrimson, width: 1.5),
            ),
            child: Text(
              '💢 APP-SPERRE AKTIV (${state.blockedAppCategories.join(", ")}): '
              'Schenke Mimi eine Aufmerksamkeit oder streichle sie noch ${state.remainingHeadpatsToUnlock}×, um sie wieder glücklich zu machen!',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ...kMimiGiftCatalog.map((gift) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.primaryAccent.withAlphaFactor(0.55),
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Text(gift.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gift.name,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        gift.description,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => controller.giveGiftToMimi(gift),
                  child: const Text(
                    'Schenken ♡',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title, CuteHorrorPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
