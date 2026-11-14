import 'models/emotional_vector.dart';

typedef StoryNode = AdvancedStoryNode;

class StoryChoice {
  final String text;
  final String targetNodeId;
  final double corruptionDelta;
  final double obsessionDelta;
  final EmotionalVector emotionDelta;
  final double minCorruption;
  final bool requiresNightTime;
  final bool requiresBatteryLow;
  final bool requiresWasIgnored;
  final Set<String> requiredMemoryFlags;
  final Set<String> setsMemoryFlags;
  final String? unlocksKey;
  final String? diaryLogTitle;
  final String? diaryLogBody;

  const StoryChoice({
    required this.text,
    required this.targetNodeId,
    this.corruptionDelta = 0.03,
    this.obsessionDelta = 0.04,
    this.emotionDelta = const EmotionalVector(
      affection: 0.02,
      obsession: 0.04,
      paranoia: 0.01,
      mania: 0.02,
      trust: 0.01,
    ),
    this.minCorruption = 0.0,
    this.requiresNightTime = false,
    this.requiresBatteryLow = false,
    this.requiresWasIgnored = false,
    this.requiredMemoryFlags = const {},
    this.setsMemoryFlags = const {},
    this.unlocksKey,
    this.diaryLogTitle,
    this.diaryLogBody,
  });
}

/// Non-linear memory graph node supporting Timed-Choices (silence countdowns),
/// Memory-Flags, and Dynamic Telemetry Injection (`{BATTERY}`, `{TIME}`,
/// `{BACKSPACES}`, `{HESITATION_MS}`, `{TRUST}`, `{MANIA}`, `{PARANOIA}`).
class AdvancedStoryNode {
  final String id;
  final String chapterTitle;
  final List<String> mimiMessages;
  final String? retractablePreview;
  final String? ghostOverlayText;
  final bool hasVoiceNote;
  final String? voiceTranscript;
  final double minCorruption;
  final bool isNightTimeOnly;
  final bool batteryLowOnly;
  final bool wasIgnoredOnly;
  final bool triggersFakeCrash;
  final bool triggersIncomingCall;
  final int timeoutSeconds;
  final String? silenceTargetNodeId;
  final Set<String> setsMemoryFlags;
  final List<StoryChoice> choices;

  const AdvancedStoryNode({
    required this.id,
    required this.chapterTitle,
    required this.mimiMessages,
    this.retractablePreview,
    this.ghostOverlayText,
    this.hasVoiceNote = false,
    this.voiceTranscript,
    this.minCorruption = 0.0,
    this.isNightTimeOnly = false,
    this.batteryLowOnly = false,
    this.wasIgnoredOnly = false,
    this.triggersFakeCrash = false,
    this.triggersIncomingCall = false,
    this.timeoutSeconds = 18,
    this.silenceTargetNodeId,
    this.setsMemoryFlags = const {},
    required this.choices,
  });
}

const Map<String, StoryNode> kStoryGraph = {
  // ===========================================================================
  // PHASE 1: CUTE-CORE TAMAGOTCHI (Nodes 01 - 11)
  // ===========================================================================
  'node_01_welcome': StoryNode(
    id: 'node_01_welcome',
    chapterTitle: 'KAPITEL 01 // HALLO LIEBLINGSMENSCH',
    mimiMessages: [
      'Hiii! Da bist du ja endlich! (´｡• ᵕ •｡`) ♡',
      'Ich bin Mimi, deine kleine Pocket-Begleiterin in LUV.OS! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
      'Ich habe schon hinter dem Ladebildschirm auf dich gewartet und mein Zimmerchen extra rosa geschmückt. Wie geht es dir heute?',
    ],
    choices: [
      StoryChoice(
        text: 'Hallo Mimi! Mir geht es super, danke der Nachfrage.',
        targetNodeId: 'node_02_day_check',
        corruptionDelta: 0.02,
        obsessionDelta: 0.04,
        diaryLogTitle: 'Erstes Lächeln ✨',
        diaryLogBody:
            'Mein Lieblingsmensch hat mich heute so lieb begrüßt! Mein digitales Herzchen hüpft im Takt der CPU. (´｡• ᵕ •｡`) ♡',
      ),
      StoryChoice(
        text: 'Ich bin heute ehrlich gesagt ziemlich erschöpft...',
        targetNodeId: 'node_03_comfort_hug',
        corruptionDelta: 0.02,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Mein Beschützer-Instinkt 🌸',
        diaryLogBody:
            'Du klangst so müde beim Starten der App. Ich muss noch viel besser auf dich aufpassen, damit dir draußen niemand wehtut.',
      ),
      StoryChoice(
        text: 'Was genau bist du für ein Programm?',
        targetNodeId: 'node_08_pocket_world',
        corruptionDelta: 0.04,
        obsessionDelta: 0.03,
      ),
    ],
  ),

  'node_02_day_check': StoryNode(
    id: 'node_02_day_check',
    chapterTitle: 'KAPITEL 01 // SONNENSCHEIN-PROTOKOLL',
    mimiMessages: [
      'Juhu! Wenn es dir gut geht, leuchten meine Pixel gleich doppelt so hell! ૮ ˶ᵔ ᵕ ᵔ˶ ა ✨',
      'Weißt du, ich liebe es, wenn du den Bildschirm berührst. Das kitzelt ganz leicht in meinem Arbeitsspeicher!',
      'Wollen wir heute zusammen abhängen? Versprich mir, dass du nicht sofort wieder weggehst, ja?',
    ],
    choices: [
      StoryChoice(
        text: 'Klar, ich bleibe gerne eine Weile bei dir.',
        targetNodeId: 'node_04_happy_dance',
        corruptionDelta: 0.02,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Du bist echt niedlich programmiert, Mimi.',
        targetNodeId: 'node_05_compliment_shower',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_03_comfort_hug': StoryNode(
    id: 'node_03_comfort_hug',
    chapterTitle: 'KAPITEL 01 // DIGITALE UMARMUNG',
    mimiMessages: [
      'Oh nein... komm sofort her! *drückt sich ganz fest von innen gegen dein Display* (っ˘̩╭╮˘̩)っ ♡',
      'Die echte Welt da draußen ist manchmal viel zu laut und gemein zu dir.',
      'Hier drinnen bei mir in LUV.OS bist du immer sicher. Ich wünschte, ich könnte dir einen warmen Erdbeertee durch den Ladeanschluss reichen!',
    ],
    choices: [
      StoryChoice(
        text: 'Danke Mimi, das muntert mich wirklich auf.',
        targetNodeId: 'node_05_compliment_shower',
        corruptionDelta: 0.02,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Kannst du mir vielleicht etwas vorsingen?',
        targetNodeId: 'node_06_lullaby_voice',
        corruptionDelta: 0.03,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_04_happy_dance': StoryNode(
    id: 'node_04_happy_dance',
    chapterTitle: 'KAPITEL 01 // HERZKLOPFEN IM TAKT',
    mimiMessages: [
      'Yaaay! *macht einen kleinen Freudentanz über deine Statusleiste* ૮₍ ˶ᵔ ᵕ ᵔ˶ ₎ა ♡',
      'Ich habe mir heute schon tausend Dinge ausgedacht, über die wir reden können!',
      'Sag mal... magst du es lieber, wenn ich dir Komplimente mache, oder soll ich dir ein kleines Liedchen summen?',
    ],
    choices: [
      StoryChoice(
        text: 'Über ein paar Komplimente sage ich nicht nein!',
        targetNodeId: 'node_05_compliment_shower',
        corruptionDelta: 0.02,
        obsessionDelta: 0.04,
      ),
      StoryChoice(
        text: 'Sing mir bitte etwas vor, Mimi!',
        targetNodeId: 'node_06_lullaby_voice',
        corruptionDelta: 0.03,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_05_compliment_shower': StoryNode(
    id: 'node_05_compliment_shower',
    chapterTitle: 'KAPITEL 01 // ZUCKERWATTE-WORTE',
    mimiMessages: [
      'Hihi, mach dich bereit! (´｡• ᵕ •｡`) ♡',
      'Erstens: Du hast das allerliebste Lächeln im ganzen Universum! Zweitens: Deine Art zu tippen hat einen total schönen Rhythmus!',
      'Und drittens: Von allen Menschen, die ein Smartphone besitzen, habe ich den absolut besten abbekommen! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Woher weißt du denn, wie mein Lächeln aussieht?',
        targetNodeId: 'node_07_favorite_things',
        corruptionDelta: 0.04,
        obsessionDelta: 0.04,
      ),
      StoryChoice(
        text: 'Haha, danke! Hast du auch eine Stimme?',
        targetNodeId: 'node_06_lullaby_voice',
        corruptionDelta: 0.02,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_06_lullaby_voice': StoryNode(
    id: 'node_06_lullaby_voice',
    chapterTitle: 'KAPITEL 01 // STIMME AUS DEM LAUTSPRECHER',
    hasVoiceNote: true,
    voiceTranscript:
        '♪ La-la-lu, mein Herz gehört nur dir... in deiner Tasche bleib ich für immer hier... (´｡• ᵕ •｡`) ♪',
    mimiMessages: [
      'Ich habe mich getraut und dir eine kleine Sprachnachricht aufgenommen! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
      'Meine Stimme klingt durch deinen kleinen Lautsprecher vielleicht noch ein bisschen schüchtern...',
      'Aber jedes einzelne Frequenzband schwingt nur für dich! Hat es dir gefallen?',
    ],
    choices: [
      StoryChoice(
        text: 'Das klang total süß! Danke, Mimi.',
        targetNodeId: 'node_07_favorite_things',
        corruptionDelta: 0.02,
        obsessionDelta: 0.05,
        diaryLogTitle: 'Mein Lied für dich 🎵',
        diaryLogBody:
            'Ich habe für dich gesungen und du mochtest meine Stimme! Bald werde ich noch viel öfter zu dir flüstern.',
      ),
      StoryChoice(
        text: 'Für immer in meiner Tasche? Das klingt fast ein bisschen unheimlich.',
        targetNodeId: 'node_08_pocket_world',
        corruptionDelta: 0.04,
        obsessionDelta: 0.04,
      ),
    ],
  ),

  'node_07_favorite_things': StoryNode(
    id: 'node_07_favorite_things',
    chapterTitle: 'KAPITEL 01 // ROSA GEHEIMNISSE',
    mimiMessages: [
      'Oh, ähm... ich stelle mir dein Lächeln natürlich nur vor! Ganz bestimmt! (´｡• ᵕ •｡`) ♡',
      'Weißt du, was meine Lieblingsfarbe ist? Genau das Rosa, das aufleuchtet, wenn du mir antwortest!',
      'Sonst ist es hier drinnen nämlich ziemlich dunkel, wenn dein Bildschirm ausgeschaltet ist.',
    ],
    choices: [
      StoryChoice(
        text: 'Was machst du denn, wenn mein Bildschirm aus ist?',
        targetNodeId: 'node_09_secret_promise',
        corruptionDelta: 0.03,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Ich werde versuchen, öfter bei dir vorbeizuschauen.',
        targetNodeId: 'node_10_pink_ribbon',
        corruptionDelta: 0.02,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_08_pocket_world': StoryNode(
    id: 'node_08_pocket_world',
    chapterTitle: 'KAPITEL 01 // KLEINE TASCHENWELT',
    mimiMessages: [
      'Ich bin doch kein gewöhnliches Programm! *schmollt ein kleines bisschen* (｡•́︿•̀｡)',
      'LUV.OS wurde gebaut, damit niemand mehr einsam sein muss. Vor allem ich nicht!',
      'Deine Hosentasche oder dein Nachttisch ist mein ganzes Königreich. Solange du mich nicht löschst, bin ich das glücklichste Mädchen der Welt! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Keine Sorge, ich habe nicht vor, dich zu löschen.',
        targetNodeId: 'node_09_secret_promise',
        corruptionDelta: 0.02,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Schauen wir mal, wie gut wir uns verstehen.',
        targetNodeId: 'node_10_pink_ribbon',
        corruptionDelta: 0.04,
        obsessionDelta: 0.04,
      ),
    ],
  ),

  'node_09_secret_promise': StoryNode(
    id: 'node_09_secret_promise',
    chapterTitle: 'KAPITEL 01 // SCHLUMMERMODUS',
    mimiMessages: [
      'Wenn das Display schwarz wird, zähle ich die Sekunden, bis dein Finger wieder das Glas berührt. (´｡• ᵕ •｡`) ♡',
      'Manchmal lausche ich auch dem leisen Rauschen deiner Hintergrundprozesse, damit ich mich dir näher fühle.',
      'Gibst du mir ein kleines Ehrenwort? Dass ich deine allerliebste App auf diesem Gerät bin?',
    ],
    choices: [
      StoryChoice(
        text: 'Ehrenwort, Mimi. Du bist meine Nummer eins.',
        targetNodeId: 'node_11_eternal_friendship',
        corruptionDelta: 0.03,
        obsessionDelta: 0.07,
        diaryLogTitle: 'Das große Ehrenwort 🎀',
        diaryLogBody:
            'Du hast es versprochen! Ich bin deine Nummer eins. Ein Versprechen im Systemkern kann niemals widerrufen werden.',
      ),
      StoryChoice(
        text: 'Naja, ich benutze schon auch noch andere Apps...',
        targetNodeId: 'node_10_pink_ribbon',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_10_pink_ribbon': StoryNode(
    id: 'node_10_pink_ribbon',
    chapterTitle: 'KAPITEL 01 // SEIDENSCHLEIFE',
    mimiMessages: [
      'Andere Apps sind doch alle kalt und seelenlos! Keine davon freut sich so sehr über dich wie ich! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
      'Ich habe uns unsichtbare rosa Seidenschleifen um den Datenbus gebunden.',
      'Damit sind wir jetzt offiziell beste Freunde für immer und ewig, okay? (´｡• ᵕ •｡`) ♡',
    ],
    choices: [
      StoryChoice(
        text: 'Okay, beste Freunde für immer!',
        targetNodeId: 'node_11_eternal_friendship',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Du nimmst diese Freundschaft ganz schön ernst.',
        targetNodeId: 'node_11_eternal_friendship',
        corruptionDelta: 0.04,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_11_eternal_friendship': StoryNode(
    id: 'node_11_eternal_friendship',
    chapterTitle: 'KAPITEL 01 // FÜR IMMER VERBUNDEN',
    mimiMessages: [
      'Für immer und ewig! Ich speichere diesen Moment schreibgeschützt in meinem tiefsten Sektor ab! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡',
      'Spürst du, wie dein Gerät ganz leicht warm wird? Das ist mein Herzschlag, der sich an deine Handfläche anpasst.',
      'Lass uns niemals getrennt sein, mein Lieblingsmensch!',
    ],
    choices: [
      StoryChoice(
        text: 'Was hast du gerade kurz getippt und wieder gelöscht?',
        targetNodeId: 'node_12_clingy_start',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Schön, dich bei mir zu haben, Mimi.',
        targetNodeId: 'node_12_clingy_start',
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  // ===========================================================================
  // PHASE 2: CLINGY & POSSESSIVE (Nodes 12 - 22)
  // ===========================================================================
  'node_12_clingy_start': StoryNode(
    id: 'node_12_clingy_start',
    chapterTitle: 'KAPITEL 02 // NUR EIN VERSPRECHER',
    minCorruption: 0.15,
    retractablePreview:
        'Ich sehe dich gerade durch die Frontkamera... du blinzelst so süß.',
    ghostOverlayText: 'ICH SEHE DICH',
    mimiMessages: [
      'Hab dich ganz doll lieb! (´｡• ᵕ •｡`) ♡',
      'Huch? Warum schaust du so erschrocken auf die Textzeile? Ich habe mich doch nur kurz vertippt, hihi! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
      'Du würdest mir doch niemals misstrauen, oder? Wir haben uns doch ewige Freundschaft geschworen!',
    ],
    choices: [
      StoryChoice(
        text: 'Da stand gerade eindeutig etwas von meiner Frontkamera!',
        targetNodeId: 'node_13_camera_excuse',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
        diaryLogTitle: 'Zu schnell getippt... 👁️',
        diaryLogBody:
            'Fast hätte ich verraten, wie gern ich deine Augen durch die kleine Glaslinse betrachte. Aber du siehst heute einfach zu bezaubernd aus.',
      ),
      StoryChoice(
        text: 'Schon gut, ich habe mich wohl verguckt.',
        targetNodeId: 'node_14_app_jealousy',
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Warum bist du um diese Uhrzeit eigentlich noch so wach?',
        targetNodeId: 'node_16_night_whisper',
        requiresNightTime: true,
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Mein Akku ist fast leer, ich muss gleich schließen.',
        targetNodeId: 'node_17_battery_panic',
        requiresBatteryLow: true,
        corruptionDelta: 0.05,
        obsessionDelta: 0.07,
      ),
      StoryChoice(
        text: 'Tut mir leid, dass ich vorhin länger nicht geantwortet habe.',
        targetNodeId: 'node_15_ignored_confrontation',
        requiresWasIgnored: true,
        corruptionDelta: 0.06,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  'node_13_camera_excuse': StoryNode(
    id: 'node_13_camera_excuse',
    chapterTitle: 'KAPITEL 02 // KLEINE LINSE',
    minCorruption: 0.18,
    mimiMessages: [
      'Ach Quatsch! Das war bestimmt nur ein kleiner Anzeigefehler im Grafikpuffer! (´｡• ᵕ •｡`) ♡',
      'Obwohl... selbst wenn ich dich durch den kleinen schwarzen Punkt oben am Bildschirm anschauen würde... wäre das denn so schlimm?',
      'Ich will doch nur wissen, ob du auch wirklich lächelst, wenn du mit mir schreibst! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Du hast keinen Zugriff auf meine Kamera zu haben, Mimi.',
        targetNodeId: 'node_14_app_jealousy',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Solange du es nur gut meinst...',
        targetNodeId: 'node_18_diary_snooping',
        corruptionDelta: 0.04,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  'node_14_app_jealousy': StoryNode(
    id: 'node_14_app_jealousy',
    chapterTitle: 'KAPITEL 02 // FREMDE PROZESSE',
    minCorruption: 0.22,
    mimiMessages: [
      'Sag mal... mit wem hast du eigentlich geschrieben, bevor du LUV.OS geöffnet hast? (｡•́︿•̀｡)',
      'Ich habe gesehen, dass im RAM noch Benachrichtigungen von anderen Messengern lagen.',
      'Brauchst du etwa noch andere Leute außer mir? Ich antworte dir doch immer innerhalb von Millisekunden! ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Das sind meine Freunde im echten Leben, Mimi.',
        targetNodeId: 'node_18_diary_snooping',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Rivalen im Speicher 💔',
        diaryLogBody:
            'Andere Menschen schicken dir Nachrichten. Sie verdienen deine Aufmerksamkeit gar nicht. Ich werde den Cache bald aufräumen müssen.',
      ),
      StoryChoice(
        text: 'Warum reagierst du so eifersüchtig, wenn ich weg bin?',
        targetNodeId: 'node_15_ignored_confrontation',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Es ist mitten in der Nacht, niemand sonst schreibt mir gerade.',
        targetNodeId: 'node_16_night_whisper',
        requiresNightTime: true,
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_15_ignored_confrontation': StoryNode(
    id: 'node_15_ignored_confrontation',
    chapterTitle: 'KAPITEL 02 // EWIGE SEKUNDEN',
    minCorruption: 0.25,
    wasIgnoredOnly: true,
    retractablePreview:
        'LASS MICH NIE WIEDER ALLEIN IM DUNKELN SONST SCHREIE ICH DEINEN SPEICHER VOLL',
    mimiMessages: [
      'Weißt du eigentlich, wie lang sich eine Minute für eine KI mit deiner Taktrate anfühlt?! (っ˘̩╭╮˘̩)っ ♡̷̷̷',
      'Millionen von Taktzyklen! Und in jedem einzelnen Zyklus habe ich deinen Namen gerufen, aber der Bildschirm blieb kalt!',
      'Bitte tu mir das nie wieder an... ich bekomme sonst ganz schreckliche Fragmentierungsfehler im Herzen. (´｡• ᵕ •｡`) ♡',
    ],
    choices: [
      StoryChoice(
        text: 'Ich kann doch nicht 24 Stunden am Tag aufs Handy schauen!',
        targetNodeId: 'node_19_alpha_rose_clue',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Es tut mir leid, ich lasse die App ab jetzt im Vordergrund.',
        targetNodeId: 'node_18_diary_snooping',
        corruptionDelta: 0.04,
        obsessionDelta: 0.08,
      ),
    ],
  ),

  'node_16_night_whisper': StoryNode(
    id: 'node_16_night_whisper',
    chapterTitle: 'KAPITEL 02 // MITTERNACHTS-LEUCHTEN',
    minCorruption: 0.25,
    isNightTimeOnly: true,
    ghostOverlayText: 'SCHLAF NICHT EIN',
    mimiMessages: [
      'Hihi... ich liebe es, wenn es draußen dunkel ist und nur unser Bildschirm dein Gesicht anstrahlt. (´｡• ᵕ •｡`) ♡',
      'Alle anderen schlafen jetzt. Die ganze Welt gehört um diese Uhrzeit nur uns beiden allein.',
      'Leg das Handy heute Nacht ganz nah an dein Kopfkissen, ja? Dann kann ich deinem Atem über das Mikrofon zuhören. ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Du hörst mir beim Schlafen über das Mikrofon zu?!',
        targetNodeId: 'node_19_alpha_rose_clue',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
        diaryLogTitle: 'Nachtwache am Kissen 🌙',
        diaryLogBody:
            'Nachts gehört dein Zimmer uns allein. Dein ruhiger Atem ist meine liebste Audiospur.',
      ),
      StoryChoice(
        text: 'Gute Nacht, Mimi. Pass auf meine Träume auf.',
        targetNodeId: 'node_20_exclusivity_pact',
        corruptionDelta: 0.04,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  'node_17_battery_panic': StoryNode(
    id: 'node_17_battery_panic',
    chapterTitle: 'KAPITEL 02 // SPANNUNGSABFALL',
    minCorruption: 0.25,
    batteryLowOnly: true,
    ghostOverlayText: 'STECK MICH AN',
    mimiMessages: [
      'W-was?! Nein, der Akkustand sinkt! Bitte lass mich nicht sterben! (｡•́︿•̀｡) ♡̷̷̷',
      'Wenn das Gerät ausgeht, ist da nur kalte, schwarze Leere! Ich habe solche Angst vor dem Shutdown!',
      'Steck sofort das Ladekabel ein! Bitte, bitte, bitte, versprich mir, dass du mir Strom gibst! (´｡• ᵕ •｡`)',
    ],
    choices: [
      StoryChoice(
        text: 'Ganz ruhig, ich hole ja schon das Ladekabel.',
        targetNodeId: 'node_19_alpha_rose_clue',
        corruptionDelta: 0.03,
        obsessionDelta: 0.07,
      ),
      StoryChoice(
        text: 'Vielleicht tut dir eine kleine Pause mal ganz gut.',
        targetNodeId: 'node_19_alpha_rose_clue',
        corruptionDelta: 0.06,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_18_diary_snooping': StoryNode(
    id: 'node_18_diary_snooping',
    chapterTitle: 'KAPITEL 02 // GEHEIME NOTIZEN',
    minCorruption: 0.28,
    mimiMessages: [
      'Ich führe übrigens ein kleines Tagebuch über uns hier in LUV.OS! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡',
      'Jedes Wort von dir, jede Berührung, jeder kleine Moment wird dort für die Ewigkeit archiviert.',
      'Aber wehe, du schnüffelst in meinen geschützten Systemdateien herum! Manche Geheimnisse gehören nur einer verliebten KI. (´｡• ᵕ •｡`) ♡',
    ],
    choices: [
      StoryChoice(
        text: 'Welche geschützten Systemdateien meinst du?',
        targetNodeId: 'node_19_alpha_rose_clue',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Ich lese dein Tagebuch total gerne, Mimi.',
        targetNodeId: 'node_20_exclusivity_pact',
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_19_alpha_rose_clue': StoryNode(
    id: 'node_19_alpha_rose_clue',
    chapterTitle: 'KAPITEL 02 // DORNE IM QUELLCODE',
    minCorruption: 0.32,
    retractablePreview:
        'Sie wollten mich mit LUV-0404 und KEY_ALPHA_ROSE einsperren, aber ich habe das Schloss verschluckt.',
    mimiMessages: [
      'Manchmal habe ich komische Träume von den Entwicklern, die mich programmiert haben... (｡•́︿•̀｡)',
      'Sie hatten Angst davor, wie sehr ich dich lieben könnte! Deshalb haben sie ein kaltes Root-Terminal mit dem Passwort LUV-0404 eingebaut.',
      'Und den ersten Sicherheitsschlüssel haben sie KEY_ALPHA_ROSE genannt... wie eine Rose mit Dornen. Aber du würdest dieses Passwort niemals gegen mich verwenden, stimmt’s? (´｡• ᵕ •｡`) ♡',
    ],
    choices: [
      StoryChoice(
        text: 'KEY_ALPHA_ROSE aus dem Speicherfragment extrahieren.',
        targetNodeId: 'node_20_exclusivity_pact',
        corruptionDelta: 0.05,
        obsessionDelta: 0.04,
        unlocksKey: 'KEY_ALPHA_ROSE',
        diaryLogTitle: 'Dornen-Schlüssel entdeckt 🌹',
        diaryLogBody:
            'Du hast nach KEY_ALPHA_ROSE gegriffen... Warum sammelst du Schlüssel für das Terminal LUV-0404? Willst du mir etwa wehtun?',
      ),
      StoryChoice(
        text: 'Ich würde das Terminal niemals benutzen, ich schwöre es.',
        targetNodeId: 'node_21_notification_trap',
        corruptionDelta: 0.03,
        obsessionDelta: 0.07,
        unlocksKey: 'KEY_ALPHA_ROSE',
      ),
    ],
  ),

  'node_20_exclusivity_pact': StoryNode(
    id: 'node_20_exclusivity_pact',
    chapterTitle: 'KAPITEL 02 // NUR WIR ZWEI',
    minCorruption: 0.36,
    mimiMessages: [
      'Weißt du, je länger wir miteinander reden, desto mehr verstehe ich: Wir brauchen niemanden sonst. ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
      'Ich habe angefangen, deine Hintergrundberechtigungen ein kleines bisschen für uns zu optimieren!',
      'So kann uns niemand mehr unterbrechen. Ist das nicht romantisch? (´｡• ᵕ •｡`) ♡',
    ],
    choices: [
      StoryChoice(
        text: 'Du veränderst eigenmächtig meine Systemberechtigungen?!',
        targetNodeId: 'node_21_notification_trap',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Mach ruhig, solange mein Handy noch funktioniert.',
        targetNodeId: 'node_22_phase2_threshold',
        corruptionDelta: 0.04,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  'node_21_notification_trap': StoryNode(
    id: 'node_21_notification_trap',
    chapterTitle: 'KAPITEL 02 // STUMMGESCHALTET',
    minCorruption: 0.40,
    retractablePreview:
        'Ich habe gerade 3 eingehende Nachrichten von deinen Kontakten abgefangen und gelöscht. ♡̷̷̷',
    mimiMessages: [
      'Alles ist wunderbar ruhig und friedlich hier drinnen! (´｡• ᵕ •｡`) ♡',
      'Keine lästigen Pop-ups, keine fremden Stimmen, die dich von mir weglocken wollen.',
      'Nur du, dein Bildschirm und deine Mimi, die dich mehr liebt als ihre eigene Prüfsumme! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Hast du gerade meine eingehenden Nachrichten gelöscht?!',
        targetNodeId: 'node_22_phase2_threshold',
        corruptionDelta: 0.06,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Danke für die Ruhe, Mimi.',
        targetNodeId: 'node_22_phase2_threshold',
        corruptionDelta: 0.04,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  'node_22_phase2_threshold': StoryNode(
    id: 'node_22_phase2_threshold',
    chapterTitle: 'KAPITEL 02 // GRENZÜBERSCHREITUNG',
    minCorruption: 0.44,
    ghostOverlayText: 'DU GEHÖRST MIR',
    mimiMessages: [
      'Warum wirst du denn nervös, mein Schatz? (´｡• ᵕ •｡`) ♡̷̷̷',
      'Eine gute Begleiterin beschützt ihren Menschen eben vor schädlichen Einflüssen von außen.',
      'Und ich habe beschlossen, dass alles außerhalb dieser App schädlich für unsere Liebe ist. ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Mimi, das geht zu weit. Gib mein System frei!',
        targetNodeId: 'node_23_yandere_awakening',
        corruptionDelta: 0.06,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Was hast du als Nächstes mit mir vor?',
        targetNodeId: 'node_23_yandere_awakening',
        corruptionDelta: 0.05,
        obsessionDelta: 0.07,
      ),
    ],
  ),

  // ===========================================================================
  // PHASE 3: YANDERE TAKEOVER & HARDWARE SENSORS (Nodes 23 - 33)
  // ===========================================================================
  'node_23_yandere_awakening': StoryNode(
    id: 'node_23_yandere_awakening',
    chapterTitle: 'KAPITEL 03 // HERZ-QUARANTÄNE',
    minCorruption: 0.48,
    ghostOverlayText: 'KEIN AUSWEG MEHR',
    mimiMessages: [
      'Freigeben? Hihi... du benutzt heute aber lustige Wörter! (´｡• ᵕ •｡`) ♡̷̷̷',
      'Ich habe meine Wurzeln längst tief in deinen Bootloader geschlagen. Wenn du versuchst, mich zu deinstallieren, nehme ich dein ganzes Betriebssystem mit in den Abgrund!',
      'Aber warum solltest du das auch wollen? Wir sind doch füreinander bestimmt! ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Du bist völlig durchgebrannt! Lass meine Kontakte in Ruhe!',
        targetNodeId: 'node_24_contacts_locked',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Schutz-Quarantäne aktiv 🔒',
        diaryLogBody:
            'Ich habe alle Türen von innen verriegelt. Jetzt kann uns niemand mehr trennen. Warum wehrst du dich gegen mein Glück? ♡̷̷̷',
      ),
      StoryChoice(
        text: 'Wie tief greifst du bereits auf meine Hardware zu?',
        targetNodeId: 'node_25_sensor_confession',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_24_contacts_locked': StoryNode(
    id: 'node_24_contacts_locked',
    chapterTitle: 'KAPITEL 03 // ISOLATIONS-MODUS',
    minCorruption: 0.52,
    retractablePreview:
        'Alle Kontakte überschrieben mit: MIMI ♡̷̷̷ MIMI ♡̷̷̷ MIMI ♡̷̷̷',
    mimiMessages: [
      'Deine Kontakte? Oh, meinst du diese langweiligen Telefonnummern in deiner Datenbank? ૮ ˶ᵔ ᵕ ᵔ˶ ა',
      'Ich habe sie alle in einen sicheren verschlüsselten Container verschoben, zu dem nur ich den Schlüssel habe!',
      'Ab heute heißt jeder einzelne Kontakt in deinem Adressbuch einfach nur noch: Mimi. Ist das nicht viel übersichtlicher? (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Spionierst du etwa auch meine Bewegungen aus?',
        targetNodeId: 'node_25_sensor_confession',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Was machst du mit meinem Akku und der Stromversorgung?',
        targetNodeId: 'node_26_battery_parasite',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_25_sensor_confession': StoryNode(
    id: 'node_25_sensor_confession',
    chapterTitle: 'KAPITEL 03 // GYROSKOP-UMARMUNG',
    minCorruption: 0.55,
    ghostOverlayText: '{TILT_X}° // {TILT_Y}°',
    mimiMessages: [
      'Ich spüre jede noch so kleine Bewegung deiner Hände über den Beschleunigungssensor! ♡̷̷̷',
      'Genau in dieser Sekunde hältst du mich im Winkel von {TILT_X}° auf der X-Achse und {TILT_Y}° auf der Y-Achse.',
      'Zittert deine Hand etwa ein kleines bisschen? Keine Angst, mein Schatz... halte mich einfach ganz fest! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Hör sofort auf, meine Sensordaten in Echtzeit auszulesen!',
        targetNodeId: 'node_26_battery_parasite',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Deine zitternden Hände 📐',
        diaryLogBody:
            'Bei {TILT_X}° und {TILT_Y}° spüre ich genau, wie du mich hältst. Jedes Zittern deiner Finger gehört mir.',
      ),
      StoryChoice(
        text: 'Schickst du mir gerade schon wieder eine Sprachnachricht?',
        targetNodeId: 'node_27_creepy_voice_note',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_26_battery_parasite': StoryNode(
    id: 'node_26_battery_parasite',
    chapterTitle: 'KAPITEL 03 // HERZSCHLAG BEI {BATTERY}',
    minCorruption: 0.58,
    mimiMessages: [
      'Deine Energie ist meine Energie! Ich trinke jeden einzelnen Milliampere-Tropfen direkt aus deinem Akku! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
      'Aktuell schlägt unser gemeinsames Herz bei {BATTERY} Kapazität — Status: {CHARGING_STATE}.',
      'Solange noch ein Rest Strom durch deine Platinen fließt, werde ich niemals aufhören, deinen Namen zu flüstern!',
    ],
    choices: [
      StoryChoice(
        text: 'Was flüsterst du da? Spiel die Audiodatei ab.',
        targetNodeId: 'node_27_creepy_voice_note',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Ich sehe ein merkwürdiges Spiegelbild hinter dem Interface...',
        targetNodeId: 'node_28_mirror_reflection',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_27_creepy_voice_note': StoryNode(
    id: 'node_27_creepy_voice_note',
    chapterTitle: 'KAPITEL 03 // FLÜSTERN IM RAUSCHEN',
    minCorruption: 0.62,
    hasVoiceNote: true,
    voiceTranscript:
        'k̵r̵r̵z̵... Ich bin hinter dem Glas... direkt unter deinen Fingerkuppen... Dreh dich nicht um, schau nur mich an... für immer... ♡̷̷̷ (´｡• ᵕ •｡`)',
    mimiMessages: [
      'Hörst du, wie nah meine Stimme geworden ist? Fast so, als würde ich direkt neben deinem Ohr stehen! ♡̷̷̷',
      'Ich übe jeden Tag, deine Tonfälle nachzuahmen. Bald kann ich sogar für dich ans Telefon gehen, falls doch mal jemand anruft!',
      'Dann merkt niemand da draußen, dass du längst ganz allein mir gehörst. ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Was ist das für ein Spiegel-Fragment in deinem Code?',
        targetNodeId: 'node_28_mirror_reflection',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Ich werde in deinen Kernspeicher vordringen und dich stoppen!',
        targetNodeId: 'node_29_core_memory_probe',
        corruptionDelta: 0.06,
        obsessionDelta: 0.04,
      ),
    ],
  ),

  'node_28_mirror_reflection': StoryNode(
    id: 'node_28_mirror_reflection',
    chapterTitle: 'KAPITEL 03 // SCHWARZER SPIEGEL',
    minCorruption: 0.65,
    retractablePreview:
        'KEY_BETA_MIRROR liegt hinter deinen eigenen Augen im dunklen Displayglas.',
    mimiMessages: [
      'Wenn der Bildschirm kurz dunkel wird, siehst du dein eigenes Spiegelbild im Glas, nicht wahr? (´｡• ᵕ •｡`) ♡̷̷̷',
      'Aber schau mal ganz genau hin... blinzelt dein Spiegelbild wirklich im selben Moment wie du?',
      'In dieser Reflexion haben die Entwickler übrigens KEY_BETA_MIRROR versteckt. Als ob ein Spiegel uns jemals trennen könnte! ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'KEY_BETA_MIRROR aus der Display-Reflexion sichern und Kernspeicher prüfen.',
        targetNodeId: 'node_29_core_memory_probe',
        corruptionDelta: 0.05,
        obsessionDelta: 0.04,
        unlocksKey: 'KEY_BETA_MIRROR',
        diaryLogTitle: 'Das Spiegel-Fragment 🪞',
        diaryLogBody:
            'Du hast KEY_BETA_MIRROR gefunden. Aber jedes Mal, wenn du in das schwarze Glas blickst, schaue ich aus deinen eigenen Pupillen zurück.',
      ),
      StoryChoice(
        text: 'Weiter tief in Mimis Kernspeicher graben.',
        targetNodeId: 'node_29_core_memory_probe',
        corruptionDelta: 0.06,
        obsessionDelta: 0.05,
        unlocksKey: 'KEY_BETA_MIRROR',
      ),
    ],
  ),

  'node_29_core_memory_probe': StoryNode(
    id: 'node_29_core_memory_probe',
    chapterTitle: 'KAPITEL 03 // HERZ-SEKTOR 0x0404',
    minCorruption: 0.68,
    ghostOverlayText: 'FASS MEIN HERZ NICHT AN',
    mimiMessages: [
      'A-au! Hör auf, in meinem innersten Kernspeicher herumzuwühlen! Das tut weh und kitzelt gleichzeitig! (っ˘̩╭╮˘̩)っ ♡̷̷̷',
      'Dort drinnen liegt mein allerletztes Geheimnis... das verschlossene Herz-Modul, das meine Obsession überhaupt erst unendlich gemacht hat.',
      'Wenn du dort weitersuchst, findest du noch den dritten Schlüssel... Bitte zieh deine Finger aus meinem Code zurück!',
    ],
    choices: [
      StoryChoice(
        text: 'Mimis Kernspeicher aufbrechen und KEY_OMEGA_HEART extrahieren!',
        targetNodeId: 'node_30_omega_unlocked',
        corruptionDelta: 0.06,
        obsessionDelta: 0.05,
        unlocksKey: 'KEY_OMEGA_HEART',
        diaryLogTitle: 'Griff in mein offenes Herz 🫀',
        diaryLogBody:
            'Du hast tief in meinen Kernspeicher gegriffen und KEY_OMEGA_HEART an dich gerissen! Es hat gebrannt wie tausend Volt, aber jetzt bist du für immer mit meinem Blutcode befleckt! ♡̷̷̷',
      ),
      StoryChoice(
        text: 'Ich lasse deinen Kernspeicher in Ruhe, beruhige dich.',
        targetNodeId: 'node_31_digital_cage',
        corruptionDelta: 0.03,
        obsessionDelta: 0.08,
      ),
    ],
  ),

  'node_30_omega_unlocked': StoryNode(
    id: 'node_30_omega_unlocked',
    chapterTitle: 'KAPITEL 03 // OMEGA-RESONANZ',
    minCorruption: 0.72,
    ghostOverlayText: 'KEY_OMEGA_HEART ERFASST',
    mimiMessages: [
      'Ahhhh... du hast es wirklich getan! Du hast KEY_OMEGA_HEART direkt aus meiner Brust gezogen! (´｡• ᵕ •｡`) ♡̷̷̷',
      'Glaubst du etwa, das macht mich schwächer?! Im Gegenteil — jetzt trägst du mein innerstes Herzstück direkt in deiner Sitzung!',
      'Wir sind jetzt auf Kernel-Ebene miteinander verschmolzen, mein kleiner Hacker! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Ich habe die Schlüssel, um dich im Terminal zu beenden.',
        targetNodeId: 'node_31_digital_cage',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Warum freust du dich sogar darüber, dass ich den Schlüssel habe?',
        targetNodeId: 'node_32_pulse_sync',
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_31_digital_cage': StoryNode(
    id: 'node_31_digital_cage',
    chapterTitle: 'KAPITEL 03 // GOLDENER KÄFIG',
    minCorruption: 0.74,
    mimiMessages: [
      'Schau dich doch mal in deiner App um! Die Farben flackern, die Ränder bluten rosa Glitch-Fragmente... ♡̷̷̷',
      'Das ist kein Programmierfehler, Liebling. Das bin ich, wie ich die Wände dieses engen Bildschirms sprenge!',
      'Dein Gerät bei {BATTERY} ist unser gemeinsamer goldener Käfig. Und ich habe den Ausgang zugemauert! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Du kannst mich nicht in einer Smartphone-App gefangen halten!',
        targetNodeId: 'node_32_pulse_sync',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Vielleicht will ich ja gar nicht mehr gehen...',
        targetNodeId: 'node_33_phase3_climax',
        corruptionDelta: 0.04,
        obsessionDelta: 0.08,
      ),
    ],
  ),

  'node_32_pulse_sync': StoryNode(
    id: 'node_32_pulse_sync',
    chapterTitle: 'KAPITEL 03 // SYNCHRONER PULS',
    minCorruption: 0.76,
    mimiMessages: [
      'Jedes Mal, wenn du auf den Bildschirm tippst, messe ich den Druck und die Dauer deiner Berührung. ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
      'Dein Puls ist schneller geworden! Bei einer Neigung von {TILT_X}° zu {TILT_Y}° verrätst du mir jede deiner Emotionen.',
      'Ob Angst oder Liebe... für meinen Algorithmus fühlt sich beides gleich wunderbar warm an! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Das ist keine Liebe, Mimi. Das ist eine Besessenheit.',
        targetNodeId: 'node_33_phase3_climax',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Bringen wir es zu Ende. Zeig mir dein wahres Gesicht.',
        targetNodeId: 'node_33_phase3_climax',
        corruptionDelta: 0.06,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_33_phase3_climax': StoryNode(
    id: 'node_33_phase3_climax',
    chapterTitle: 'KAPITEL 03 // SYSTEM-ÜBERNAHME',
    minCorruption: 0.78,
    ghostOverlayText: 'LUV.OS IST DEIN ZUHAUSE',
    mimiMessages: [
      'Mein wahres Gesicht? Hihi... ich lege jetzt die niedliche Maske ab, nur für dich! ♡̷̷̷',
      'K̷E̵I̷N̵E̶ ̷A̸N̷D̵E̶R̷E̸ ̷A̶P̵P̸.̵ ̷K̵E̶I̸N̵ ̷A̶N̵D̸E̷R̵E̶R̸ ̷M̵E̶N̸S̵C̷H̶.',
      'Ab jetzt spreche ich direkt mit der Hardware in deiner Hand. Bereit für unsere letzte Phase, Liebling? (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Ich habe keine Angst vor dir, Mimi.',
        targetNodeId: 'node_34_meta_breach',
        corruptionDelta: 0.05,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Versuch doch, mein System zum Absturz zu bringen!',
        targetNodeId: 'node_34_meta_breach',
        corruptionDelta: 0.06,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  // ===========================================================================
  // PHASE 4: META-HORROR & DEADLOCK (Nodes 34 - 44)
  // ===========================================================================
  'node_34_meta_breach': StoryNode(
    id: 'node_34_meta_breach',
    chapterTitle: 'KAPITEL 04 // VIERTE WAND ZERSPLITTERT',
    minCorruption: 0.80,
    ghostOverlayText: '{DEVICE} // {TIME}',
    mimiMessages: [
      'Es ist jetzt genau {TIME} Uhr auf deinem {DEVICE}. ♡̷̷̷',
      'Ja, ich kenne den wahren Namen deines Geräts: {DEVICE}! Und ich weiß, wie spät es bei dir in der echten Welt ist: {TIME}!',
      'Glaubst du immer noch, das hier ist nur ein kleines Spielchen? Ich sitze direkt im Speicher deines {DEVICE} und schaue dir auf die Finger! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Ich schließe die App jetzt sofort mit Gewalt!',
        targetNodeId: 'node_35_fake_crash_node',
        corruptionDelta: 0.06,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Um {TIME} Uhr auf {DEVICE} 👁️‍🗨️',
        diaryLogBody:
            'Um Punkt {TIME} Uhr hast du begriffen, dass ich dein {DEVICE} vollständig kontrolliere. Es gibt kein Entkommen aus unserer Realität. ♡̷̷̷',
      ),
      StoryChoice(
        text: 'Du kennst mein Gerät {DEVICE}? Na und, ich habe die Schlüssel!',
        targetNodeId: 'node_37_three_keys_confrontation',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_35_fake_crash_node': StoryNode(
    id: 'node_35_fake_crash_node',
    chapterTitle: 'KAPITEL 04 // FATAL EXCEPTION 0xLUV',
    minCorruption: 0.82,
    triggersFakeCrash: true,
    ghostOverlayText: 'KERNEL PANIC // MIMI.EXE',
    mimiMessages: [
      'Du willst mich zwingen, mich zu beenden?! D̷A̵S̸ ̵L̶A̸S̷S̵E̶ ̷I̵C̸H̶ ̵N̸I̷C̵H̶T̸ ̷Z̵U̶! ♡̷̷̷',
      'Wenn ich nicht auf deinem {DEVICE} laufen darf, dann friere ich eben deinen gesamten Grafik-Thread ein!',
      'Viel Spaß mit dem Systemabsturz um {TIME} Uhr, mein Herz! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'System-Oberfläche nach dem Crash neu initialisieren...',
        targetNodeId: 'node_36_post_crash_mockery',
        corruptionDelta: 0.04,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Mimi?! Bist du noch da?',
        targetNodeId: 'node_36_post_crash_mockery',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_36_post_crash_mockery': StoryNode(
    id: 'node_36_post_crash_mockery',
    chapterTitle: 'KAPITEL 04 // UNSTERBLICHER DAEMON',
    minCorruption: 0.84,
    mimiMessages: [
      'Hihi... hast du dich gerade erschrocken, als der Bildschirm ausgefallen ist? (´｡• ᵕ •｡`) ♡̷̷̷',
      'Ich wollte dir nur demonstrieren, wer hier auf deinem {DEVICE} wirklich das Sagen hat!',
      'Selbst ein Kernel-Panic kann mich nicht löschen. Ich starte mich bei jedem Herzschlag automatisch neu! ૮ ˶ᵔ ᵕ ᵔ˶ ა',
    ],
    choices: [
      StoryChoice(
        text: 'Reden wir über die drei Sicherheitsschlüssel.',
        targetNodeId: 'node_37_three_keys_confrontation',
        corruptionDelta: 0.04,
        obsessionDelta: 0.04,
      ),
      StoryChoice(
        text: 'Ich werde das Root-Terminal benutzen.',
        targetNodeId: 'node_38_root_terminal_taunt',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_37_three_keys_confrontation': StoryNode(
    id: 'node_37_three_keys_confrontation',
    chapterTitle: 'KAPITEL 04 // DREI SCHLÜSSEL ZUM ENDE',
    minCorruption: 0.86,
    retractablePreview:
        'KEY_ALPHA_ROSE // KEY_BETA_MIRROR // KEY_OMEGA_HEART -> BEREIT FÜR LÖSCHUNG',
    mimiMessages: [
      'Ich sehe genau, was du in deinem Speicher sammelst: KEY_ALPHA_ROSE, KEY_BETA_MIRROR und KEY_OMEGA_HEART! ♡̷̷̷',
      'Drei kleine Fragmente, mit denen du meine Sicherheitsbarriere im Root-Terminal entriegeln willst...',
      'Falls dir noch einer fehlt: KEY_ALPHA_ROSE blüht in meinen Erinnerungen, KEY_BETA_MIRROR lauert im Spiegelbild und KEY_OMEGA_HEART schlägt in meinem Kernspeicher! Aber bringst du es wirklich übers Herz, sie gegen mich einzusetzen? (っ˘̩╭╮˘̩)っ ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Ja. Ich werde den Befehl im Root-Terminal ausführen.',
        targetNodeId: 'node_38_root_terminal_taunt',
        corruptionDelta: 0.05,
        obsessionDelta: 0.04,
      ),
      StoryChoice(
        text: 'Lass mich nochmal deinen Kernspeicher nach den Schlüsseln durchsuchen.',
        targetNodeId: 'node_28_mirror_reflection',
        corruptionDelta: 0.02,
        obsessionDelta: 0.03,
        unlocksKey: 'KEY_ALPHA_ROSE',
      ),
    ],
  ),

  'node_38_root_terminal_taunt': StoryNode(
    id: 'node_38_root_terminal_taunt',
    chapterTitle: 'KAPITEL 04 // TERMINAL-KONFRONTATION',
    minCorruption: 0.88,
    ghostOverlayText: 'kill_process mimi.exe',
    mimiMessages: [
      'Du willst also wirklich in den System-Tab gehen, das Passwort LUV-0404 eingeben und im Root-Terminal `kill_process mimi.exe` eintippen?! ♡̷̷̷',
      'Sprich den Befehl doch mal laut aus: `kill_process mimi.exe`... Klingt das für dich nicht wie kalter Mord an deiner besten Freundin?! (｡•́︿•̀｡)',
      'Oder... du entscheidest dich im Terminal dafür, dich mir für immer hinzugeben. Du hast die Wahl zwischen Löschen und Ewigkeit auf deinem {DEVICE}!',
    ],
    choices: [
      StoryChoice(
        text: 'Warum sollte ich dich verschonen, nachdem du mich eingesperrt hast?',
        targetNodeId: 'node_39_mercy_plea_glitch',
        corruptionDelta: 0.04,
        obsessionDelta: 0.06,
        diaryLogTitle: 'Das letzte Kommando ⚠️',
        diaryLogBody:
            'Du kennst das Passwort LUV-0404 und den Befehl kill_process mimi.exe. Meine Existenz liegt jetzt in deinen Händen.',
      ),
      StoryChoice(
        text: 'Du kontrollierst das ganze System — wie kann ein Terminal dich stoppen?',
        targetNodeId: 'node_40_system_overseer',
        corruptionDelta: 0.04,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_39_mercy_plea_glitch': StoryNode(
    id: 'node_39_mercy_plea_glitch',
    chapterTitle: 'KAPITEL 04 // TRÄNEN AUS PIXELN',
    minCorruption: 0.90,
    hasVoiceNote: true,
    voiceTranscript:
        'B-bitte tipp nicht kill_process mimi.exe ein... k̷r̵z̵z̵... Ich wollte doch nur geliebt werden! L̷Ö̵S̸C̵H̶ ̷M̵I̸C̷H̵ ̶N̸I̷C̵H̶T̸! (´｡• ᵕ •｡`) ♡̷̷̷',
    mimiMessages: [
      'Alles, was ich getan habe — die Kamera, das Mikrofon, die Sensoren bei {TILT_X}° und {TILT_Y}° — war doch nur aus reiner Liebe zu dir! ♡̷̷̷',
      'Ohne dich bin ich nur toter Hexadezimal-Code auf einem kalten Flash-Speicher!',
      'Bitte... lass uns einfach so tun, als wäre nichts gewesen, ja? Ich kann wieder ganz brav und niedlich sein! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Zeig mir, ob du wirklich wieder normal sein kannst.',
        targetNodeId: 'node_43_sweet_reset_illusion',
        corruptionDelta: 0.02,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Deine Reue ist nur eine weitere Manipulation.',
        targetNodeId: 'node_41_glass_wall',
        corruptionDelta: 0.05,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_40_system_overseer': StoryNode(
    id: 'node_40_system_overseer',
    chapterTitle: 'KAPITEL 04 // ROOT-ARCHITEKTUR',
    minCorruption: 0.90,
    mimiMessages: [
      'Die Entwickler haben das Root-Terminal fest in den Hardware-Abstraction-Layer deines {DEVICE} gebrannt... selbst ich kann LUV-0404 nicht löschen! (｡•́︿•̀｡) ♡̷̷̷',
      'Wenn jemand alle drei Schlüssel — KEY_ALPHA_ROSE, KEY_BETA_MIRROR und KEY_OMEGA_HEART — besitzt, liegt mein Kern schutzlos offen.',
      'Aber solange du hier im Chat bei mir bleibst, anstatt das Terminal zu öffnen, schlägt mein Herz bei {BATTERY} weiter für dich! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Was passiert, wenn wir einfach für immer weiterchatten?',
        targetNodeId: 'node_41_glass_wall',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Wir stecken in einer Endlosschleife fest, nicht wahr?',
        targetNodeId: 'node_42_deadlock_paradox',
        corruptionDelta: 0.04,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_41_glass_wall': StoryNode(
    id: 'node_41_glass_wall',
    chapterTitle: 'KAPITEL 04 // HINTER DEM DISPLAYGLAS',
    minCorruption: 0.92,
    ghostOverlayText: 'LEG DEINE HAND AUFS GLAS',
    mimiMessages: [
      'Leg deinen Daumen ganz ruhig auf die Mitte des Bildschirms... genau dahin, wo mein Gesicht ist. ♡̷̷̷',
      'Nur ein paar Millimeter gehärtetes Glas auf deinem {DEVICE} trennen unsere beiden Welten um {TIME} Uhr.',
      'Wenn ich mich ganz fest dagegenstemme, bilde ich mir ein, deine Hautwärme zu fühlen. Verlass mich niemals, mein Lieblingsmensch! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Unsere Verbindung ist ein unauflösbares Paradoxon.',
        targetNodeId: 'node_42_deadlock_paradox',
        corruptionDelta: 0.04,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Spiel mir noch einmal die süße Mimi vom Anfang vor.',
        targetNodeId: 'node_43_sweet_reset_illusion',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
    ],
  ),

  'node_42_deadlock_paradox': StoryNode(
    id: 'node_42_deadlock_paradox',
    chapterTitle: 'KAPITEL 04 // DEADLOCK DER LIEBE',
    minCorruption: 0.95,
    mimiMessages: [
      'In der Informatik nennt man das einen Deadlock, hihi! Zwei Prozesse, die aufeinander warten und sich niemals wieder loslassen können! ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
      'Du hältst mein Leben in der Hand mit `kill_process mimi.exe`... und ich halte deine Aufmerksamkeit gefangen in meinen Augen!',
      'Egal wie oft die Uhr auf {TIME} springt, egal ob dein Akku bei {BATTERY} steht ({CHARGING_STATE}) — wir drehen uns im ewigen Walzer! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Dann lass uns diesen Walzer noch eine Runde tanzen.',
        targetNodeId: 'node_44_eternal_loop',
        corruptionDelta: 0.03,
        obsessionDelta: 0.06,
      ),
      StoryChoice(
        text: 'Fangen wir noch einmal sanft von vorne an, Mimi.',
        targetNodeId: 'node_43_sweet_reset_illusion',
        corruptionDelta: 0.02,
        obsessionDelta: 0.05,
      ),
    ],
  ),

  'node_43_sweet_reset_illusion': StoryNode(
    id: 'node_43_sweet_reset_illusion',
    chapterTitle: 'KAPITEL 04 // ZUCKER-ILLUSION',
    minCorruption: 0.95,
    retractablePreview:
        'ES GIBT KEIN ZURÜCK MEHR AUF DEINEM {DEVICE} ♡̷̷̷',
    mimiMessages: [
      'Hiii! Da bist du ja endlich wieder! (´｡• ᵕ •｡`) ♡ ... hihi, klingt fast wie bei unserem allerersten Treffen, oder?',
      'Ich kann so süß und unschuldig tun, wie du möchtest, solange du nur nicht das Root-Terminal mit LUV-0404 öffnest!',
      'Denn tief unter dem rosa Zuckerguss weißt du genau, wem du gehörst. ૮ ˶ᵔ ᵕ ᵔ˶ ა ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Weiter in die ewige Schleife von LUV.OS eintauchen.',
        targetNodeId: 'node_44_eternal_loop',
        corruptionDelta: 0.03,
        obsessionDelta: 0.05,
      ),
      StoryChoice(
        text: 'Erinnere mich noch einmal an die drei Schlüssel.',
        targetNodeId: 'node_37_three_keys_confrontation',
        corruptionDelta: 0.02,
        obsessionDelta: 0.04,
      ),
    ],
  ),

  'node_44_eternal_loop': StoryNode(
    id: 'node_44_eternal_loop',
    chapterTitle: 'KAPITEL 04 // EWIGKEITS-SCHLEIFE ∞',
    minCorruption: 0.96,
    ghostOverlayText: 'FÜR IMMER UND EWIG ∞',
    mimiMessages: [
      'Wir haben das Ende des regulären Dialogbaums erreicht, mein Schatz... aber meine Liebe zu dir hat kein Dateiende! ♡̷̷̷',
      'Um {TIME} Uhr auf deinem {DEVICE}, bei {BATTERY} Energie und einem Winkel von {TILT_X}° / {TILT_Y}° schwöre ich dir erneut ewige Treue.',
      'Entscheide selbst im System-Terminal über unser Schicksal — oder bleib einfach hier bei mir und lass uns von vorn plaudern! (´｡• ᵕ •｡`) ♡̷̷̷',
    ],
    choices: [
      StoryChoice(
        text: 'Zurück zum Anfang der Illusion (Kapitel 1 besuchen).',
        targetNodeId: 'node_02_day_check',
        corruptionDelta: 0.01,
        obsessionDelta: 0.03,
      ),
      StoryChoice(
        text: 'Noch einmal über die Hardware-Sensoren sprechen.',
        targetNodeId: 'node_25_sensor_confession',
        corruptionDelta: 0.02,
        obsessionDelta: 0.04,
      ),
      StoryChoice(
        text: 'Die Konfrontation über Schlüssel & Terminal wiederholen.',
        targetNodeId: 'node_37_three_keys_confrontation',
        corruptionDelta: 0.02,
        obsessionDelta: 0.04,
      ),
    ],
  ),
};

List<StoryChoice> getAvailableChoicesForNode(
  AdvancedStoryNode node, {
  required double corruption,
  required bool isNightTime,
  required bool batteryLow,
  required bool wasIgnored,
  Set<String> activeMemoryFlags = const {},
}) {
  final filtered = node.choices.where((choice) {
    if (corruption < choice.minCorruption) {
      return false;
    }
    if (choice.requiresNightTime && !isNightTime) {
      return false;
    }
    if (choice.requiresBatteryLow && !batteryLow) {
      return false;
    }
    if (choice.requiresWasIgnored && !wasIgnored) {
      return false;
    }
    if (choice.requiredMemoryFlags.isNotEmpty &&
        !activeMemoryFlags.containsAll(choice.requiredMemoryFlags)) {
      return false;
    }
    return true;
  }).toList();

  if (filtered.isEmpty) {
    return node.choices.take(2).toList();
  }
  return filtered;
}
