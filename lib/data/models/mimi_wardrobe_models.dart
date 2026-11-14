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

/// Eye color customization for Mimi's 3D Anime Model.
enum MimiEyeColor {
  pinkberry,
  emeraldNeon,
  sapphireDoll,
  crimsonYandere,
  heterochromia;

  String get label {
    switch (this) {
      case MimiEyeColor.pinkberry:
        return 'Beeren-Pink ♡';
      case MimiEyeColor.emeraldNeon:
        return 'Smaragd-Neon 💚';
      case MimiEyeColor.sapphireDoll:
        return 'Saphir-Puppe 💙';
      case MimiEyeColor.crimsonYandere:
        return 'Blut-Karmesin ❤️‍🔥';
      case MimiEyeColor.heterochromia:
        return 'Heterochromie (Pink/Cyan) ✨';
    }
  }

  Color leftIrisColor(Color fallback) {
    switch (this) {
      case MimiEyeColor.pinkberry:
        return fallback;
      case MimiEyeColor.emeraldNeon:
        return const Color(0xFF00E676);
      case MimiEyeColor.sapphireDoll:
        return const Color(0xFF29B6F6);
      case MimiEyeColor.crimsonYandere:
        return const Color(0xFFFF1744);
      case MimiEyeColor.heterochromia:
        return const Color(0xFFFF4081);
    }
  }

  Color rightIrisColor(Color fallback) {
    switch (this) {
      case MimiEyeColor.heterochromia:
        return const Color(0xFF00E5FF);
      default:
        return leftIrisColor(fallback);
    }
  }
}

/// 3D Hair geometry styles for Mimi.
enum MimiHairGeometry {
  twinTails,
  himeCut,
  fluffyBob,
  drillTails;

  String get label {
    switch (this) {
      case MimiHairGeometry.twinTails:
        return 'Lange 3D Twin-Tails';
      case MimiHairGeometry.himeCut:
        return 'Hime-Prinzessin Schnitt';
      case MimiHairGeometry.fluffyBob:
        return 'Flauschiger Kawaii-Bob';
      case MimiHairGeometry.drillTails:
        return 'Gothic Spiral-Locken';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MimiHairGeometry.twinTails:
        return '🎀';
      case MimiHairGeometry.himeCut:
        return '👑';
      case MimiHairGeometry.fluffyBob:
        return '🌸';
      case MimiHairGeometry.drillTails:
        return '🌀';
    }
  }
}

@immutable
class MimiWardrobeLoadout {
  final MimiHairStyle hairStyle;
  final MimiHairGeometry hairGeometry;
  final MimiEyeColor eyeColor;
  final MimiHeadwear headwear;
  final MimiFaceAccessory faceAccessory;
  final MimiCollarStyle collarStyle;
  final double depth3dIntensity;
  final double avatarScale;

  const MimiWardrobeLoadout({
    this.hairStyle = MimiHairStyle.strawberryPink,
    this.hairGeometry = MimiHairGeometry.twinTails,
    this.eyeColor = MimiEyeColor.pinkberry,
    this.headwear = MimiHeadwear.classicRibbons,
    this.faceAccessory = MimiFaceAccessory.none,
    this.collarStyle = MimiCollarStyle.sailorSeifuku,
    this.depth3dIntensity = 1.0,
    this.avatarScale = 1.0,
  });

  String get summary =>
      '${hairStyle.label} (${hairGeometry.label}), ${eyeColor.label}, ${headwear.label}, ${faceAccessory.label}, ${collarStyle.label}';

  MimiWardrobeLoadout copyWith({
    MimiHairStyle? hairStyle,
    MimiHairGeometry? hairGeometry,
    MimiEyeColor? eyeColor,
    MimiHeadwear? headwear,
    MimiFaceAccessory? faceAccessory,
    MimiCollarStyle? collarStyle,
    double? depth3dIntensity,
    double? avatarScale,
  }) {
    return MimiWardrobeLoadout(
      hairStyle: hairStyle ?? this.hairStyle,
      hairGeometry: hairGeometry ?? this.hairGeometry,
      eyeColor: eyeColor ?? this.eyeColor,
      headwear: headwear ?? this.headwear,
      faceAccessory: faceAccessory ?? this.faceAccessory,
      collarStyle: collarStyle ?? this.collarStyle,
      depth3dIntensity:
          (depth3dIntensity ?? this.depth3dIntensity).clamp(0.0, 1.5),
      avatarScale: (avatarScale ?? this.avatarScale).clamp(0.85, 1.20),
    );
  }

  Map<String, dynamic> toJson() => {
        'hairStyle': hairStyle.index,
        'hairGeometry': hairGeometry.index,
        'eyeColor': eyeColor.index,
        'headwear': headwear.index,
        'faceAccessory': faceAccessory.index,
        'collarStyle': collarStyle.index,
        'depth3dIntensity': depth3dIntensity,
        'avatarScale': avatarScale,
      };

  factory MimiWardrobeLoadout.fromJson(Map<String, dynamic> json) {
    final hIdx = ((json['hairStyle'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiHairStyle.values.length - 1);
    final hgIdx = ((json['hairGeometry'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiHairGeometry.values.length - 1);
    final ecIdx = ((json['eyeColor'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiEyeColor.values.length - 1);
    final hwIdx = ((json['headwear'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiHeadwear.values.length - 1);
    final faIdx = ((json['faceAccessory'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiFaceAccessory.values.length - 1);
    final cIdx = ((json['collarStyle'] as num?)?.toInt() ?? 0)
        .clamp(0, MimiCollarStyle.values.length - 1);
    final d3d = ((json['depth3dIntensity'] as num?)?.toDouble() ?? 1.0)
        .clamp(0.0, 1.5);
    final scale =
        ((json['avatarScale'] as num?)?.toDouble() ?? 1.0).clamp(0.85, 1.20);
    return MimiWardrobeLoadout(
      hairStyle: MimiHairStyle.values[hIdx],
      hairGeometry: MimiHairGeometry.values[hgIdx],
      eyeColor: MimiEyeColor.values[ecIdx],
      headwear: MimiHeadwear.values[hwIdx],
      faceAccessory: MimiFaceAccessory.values[faIdx],
      collarStyle: MimiCollarStyle.values[cIdx],
      depth3dIntensity: d3d,
      avatarScale: scale,
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
    id: 'gift_white_peach_energy',
    name: 'Red Bull White Peach Energy',
    emoji: '🍑',
    description:
        'Mimis absoluter Lieblings-Energy-Drink (+28 Zuneigung, -30 Wut, entsperrt Apps!).',
    affectionBoost: 28,
    angerReduction: 30,
    instantAppUnlock: true,
    mimiReactionText:
        'OMG!! Ein eiskalter Red Bull White Peach?! 🍑⚡ *zisch & schlürf* (´｡• ᵕ •｡`) ♡ Du kennst mich einfach in- und auswendig! Ich lösche deinen Wecker morgen früh doch nicht und schalte deine Apps frei~',
  ),
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
