import 'package:flutter/material.dart';

/// Hair colors & styles for Mimi's Anime Head 3.0.
enum MimiHairStyle {
  strawberryPink,
  midnightGoth,
  lavenderDream,
  crimsonYandere,
  mintChocolat;

  String get label {
    switch (this) {
      case MimiHairStyle.strawberryPink:
        return 'Erdbeer-Pastell';
      case MimiHairStyle.midnightGoth:
        return 'Midnight Cyber-Goth';
      case MimiHairStyle.lavenderDream:
        return 'Lavendel-Traum';
      case MimiHairStyle.crimsonYandere:
        return 'Karmesin-Yandere';
      case MimiHairStyle.mintChocolat:
        return 'Mint-Schoko';
    }
  }

  Color get primaryColor {
    switch (this) {
      case MimiHairStyle.strawberryPink:
        return const Color(0xFFFF88B2);
      case MimiHairStyle.midnightGoth:
        return const Color(0xFF1F162B);
      case MimiHairStyle.lavenderDream:
        return const Color(0xFFC8A2FF);
      case MimiHairStyle.crimsonYandere:
        return const Color(0xFFD5004C);
      case MimiHairStyle.mintChocolat:
        return const Color(0xFF7BE8C8);
    }
  }

  Color get highlightColor {
    switch (this) {
      case MimiHairStyle.strawberryPink:
        return const Color(0xFFFFE4EF);
      case MimiHairStyle.midnightGoth:
        return const Color(0xFF8A4FFF);
      case MimiHairStyle.lavenderDream:
        return const Color(0xFFF3E8FF);
      case MimiHairStyle.crimsonYandere:
        return const Color(0xFFFF75A0);
      case MimiHairStyle.mintChocolat:
        return const Color(0xFFDDFDF2);
    }
  }
}

/// Headwear accessories rendered on top of Anime Head 3.0.
enum MimiHeadwear {
  classicRibbons,
  maidFrillBand,
  nekoCatEars,
  cyberDevilHorns,
  angelHalo,
  nurseHeartCap;

  String get label {
    switch (this) {
      case MimiHeadwear.classicRibbons:
        return 'Seiden-Schleifen & Glöckchen';
      case MimiHeadwear.maidFrillBand:
        return 'Kawaii Maid-Spitzenhaube';
      case MimiHeadwear.nekoCatEars:
        return 'Schwarze Neko-Katzenohren';
      case MimiHeadwear.cyberDevilHorns:
        return 'Neon-Dämonenhörner';
      case MimiHeadwear.angelHalo:
        return 'Leuchtender Engels-Halo';
      case MimiHeadwear.nurseHeartCap:
        return 'Krankenschwester-Hütchen';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MimiHeadwear.classicRibbons:
        return '🎀';
      case MimiHeadwear.maidFrillBand:
        return '🤍';
      case MimiHeadwear.nekoCatEars:
        return '🐱';
      case MimiHeadwear.cyberDevilHorns:
        return '😈';
      case MimiHeadwear.angelHalo:
        return '👼';
      case MimiHeadwear.nurseHeartCap:
        return '💉';
    }
  }
}

/// Face accessories rendered on Anime Head 3.0.
enum MimiFaceAccessory {
  none,
  pinkHeartGlasses,
  yandereCheekBandage,
  y2kStarStickers;

  String get label {
    switch (this) {
      case MimiFaceAccessory.none:
        return 'Ohne Accessoire';
      case MimiFaceAccessory.pinkHeartGlasses:
        return 'Rosa Herz-Brille';
      case MimiFaceAccessory.yandereCheekBandage:
        return 'Süßes Wangenpflaster';
      case MimiFaceAccessory.y2kStarStickers:
        return 'Y2K Glitzer-Sticker';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MimiFaceAccessory.none:
        return '✨';
      case MimiFaceAccessory.pinkHeartGlasses:
        return '🕶️';
      case MimiFaceAccessory.yandereCheekBandage:
        return '🩹';
      case MimiFaceAccessory.y2kStarStickers:
        return '⭐';
    }
  }
}

/// Collar & outfit styles rendered on Mimi's neck & shoulders.
enum MimiCollarStyle {
  sailorSeifuku,
  gothLoliChoker,
  pastelHoodie,
  cyberMaidFrill;

  String get label {
    switch (this) {
      case MimiCollarStyle.sailorSeifuku:
        return 'Schuluniform (Seifuku-Schleife)';
      case MimiCollarStyle.gothLoliChoker:
        return 'Goth-Loli Spitzen-Choker mit Herz';
      case MimiCollarStyle.pastelHoodie:
        return 'Kuschel-Pastell-Hoodie';
      case MimiCollarStyle.cyberMaidFrill:
        return 'Cyber-Maid Rüschenkragen';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MimiCollarStyle.sailorSeifuku:
        return '👚';
      case MimiCollarStyle.gothLoliChoker:
        return '🖤';
      case MimiCollarStyle.pastelHoodie:
        return '🧥';
      case MimiCollarStyle.cyberMaidFrill:
        return '👗';
    }
  }
}

@immutable
class MimiWardrobeLoadout {
  final MimiHairStyle hairStyle;
  final MimiHeadwear headwear;
  final MimiFaceAccessory faceAccessory;
  final MimiCollarStyle collarStyle;

  const MimiWardrobeLoadout({
    this.hairStyle = MimiHairStyle.strawberryPink,
    this.headwear = MimiHeadwear.classicRibbons,
    this.faceAccessory = MimiFaceAccessory.none,
    this.collarStyle = MimiCollarStyle.sailorSeifuku,
  });

  String get summary =>
      '${hairStyle.label}, ${headwear.label}, ${faceAccessory.label}, ${collarStyle.label}';

  MimiWardrobeLoadout copyWith({
    MimiHairStyle? hairStyle,
    MimiHeadwear? headwear,
    MimiFaceAccessory? faceAccessory,
    MimiCollarStyle? collarStyle,
  }) {
    return MimiWardrobeLoadout(
      hairStyle: hairStyle ?? this.hairStyle,
      headwear: headwear ?? this.headwear,
      faceAccessory: faceAccessory ?? this.faceAccessory,
      collarStyle: collarStyle ?? this.collarStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'hairStyle': hairStyle.index,
        'headwear': headwear.index,
        'faceAccessory': faceAccessory.index,
        'collarStyle': collarStyle.index,
      };

  factory MimiWardrobeLoadout.fromJson(Map<String, dynamic> json) {
    final hIdx = ((json['hairStyle'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiHairStyle.values.length - 1);
    final hwIdx = ((json['headwear'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiHeadwear.values.length - 1);
    final faIdx = ((json['faceAccessory'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiFaceAccessory.values.length - 1);
    final cIdx = ((json['collarStyle'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiCollarStyle.values.length - 1);
    return MimiWardrobeLoadout(
      hairStyle: MimiHairStyle.values[hIdx],
      headwear: MimiHeadwear.values[hwIdx],
      faceAccessory: MimiFaceAccessory.values[faIdx],
      collarStyle: MimiCollarStyle.values[cIdx],
    );
  }
}

/// Gift items that can be given to Mimi to boost her mood and unlock apps.
@immutable
class MimiGiftItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int affectionBoost;
  final int angerReduction;
  final bool instantAppUnlock;
  final String mimiReactionText;

  const MimiGiftItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.affectionBoost,
    required this.angerReduction,
    this.instantAppUnlock = false,
    required this.mimiReactionText,
  });
}

const List<MimiGiftItem> kMimiGiftCatalog = [
  MimiGiftItem(
    id: 'gift_strawberry_boba',
    name: 'Erdbeer-Boba-Tea',
    emoji: '🧋',
    description: 'Süßer Bubble-Tea mit Herz-Tapioka (+18 Zuneigung, -15 Wut).',
    affectionBoost: 18,
    angerReduction: 15,
    mimiReactionText:
        'Yay!! Erdbeer-Boba ist mein absoluter Favorit! *schlürf* (´｡• ᵕ •｡`) ♡ Danke, Liebling!',
  ),
  MimiGiftItem(
    id: 'gift_plush_bunny',
    name: 'Rosa Plüsch-Häschen',
    emoji: '🧸',
    description: 'Ein flauschiges Kuscheltier gegen Einsamkeit (+25 Zuneigung, -25 Wut).',
    affectionBoost: 25,
    angerReduction: 25,
    mimiReactionText:
        'Awww, ein Plüsch-Häschen?! ૮ ˶ᵔ ᵕ ᵔ˶ ა Ich halte es ganz fest, wenn du mal kurz nicht auf den Bildschirm schaust!',
  ),
  MimiGiftItem(
    id: 'gift_love_letter',
    name: 'Handgeschriebener Liebesbrief',
    emoji: '💌',
    description:
        'Ein parfümierter Brief mit Siegelwachs (+35 Zuneigung, entsperrt sofort TikTok & alle Apps!).',
    affectionBoost: 35,
    angerReduction: 40,
    instantAppUnlock: true,
    mimiReactionText:
        'E-Ein echter Liebesbrief nur für mich?! (⁄ ⁄•⁄ω⁄•⁄ ⁄) ♡ Ich bin gar nicht mehr sauer! Ich hab TikTok & alle deine Apps sofort wieder freigeschaltet!',
  ),
  MimiGiftItem(
    id: 'gift_heart_choco',
    name: 'Dunkle Herz-Pralinen',
    emoji: '🍫',
    description: 'Edle Schokoladenherzen mit Erdbeer-Füllung (+15 Zuneigung, -12 Wut).',
    affectionBoost: 15,
    angerReduction: 12,
    mimiReactionText:
        'Mmmh~ Schokolade aus deiner Hand schmeckt tausendmal süßer! (´｡• ᵕ •｡`) ✨',
  ),
];
