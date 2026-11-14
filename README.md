# LUV.OS // Pocket Companion (V2 Overhaul)

**LUV.OS** ist ein interaktives Psychological-Horror-Game im *"Found-Phone"*-Format, getarnt als pastellpinke Cute-Core Virtual-Companion-App mit **Mimi (`MIMI_CORE v5.5`)**.

---

## Architektur & Features (V2 Ultra-Polish)

1. **Deep State & Verhaltens-Telemetrie (`PlayerPsychProfile` & 5D `EmotionalVector`)**
   - Echtzeit-Tracking von Tipp-Verzögerung (`typingHesitationMs`), gelöschten Zeichen (`backspaceCount`), Touch-Geschwindigkeit (`touchVelocity`), Panik-Taps und Schweige-Countdowns.
   - 5-dimensionales Emotionsmodell (`affection`, `obsession`, `paranoia`, `mania`, `trust`) und revisionssichere SQLite/Drift-Persistenz mit 64-Bit-FNV-1a-Hash-Signaturen.
2. **2.5D Procedural Avatar Rigging ("Mimi Live-Rig Engine")**
   - Gedämpfte harmonische Oszillatoren (Hookesches Gesetz + Dämpfung) für Twin-Tails, Pony, Schleifen und Katzen-/Puppy-Ohren, gekoppelt an Gyroskop/Accelerometer und Touch.
   - Mehrschichtige Iris mit erlöschenden Catchlights, pulsierendem Neon-Herz, Mikro-Sakkaden, asymmetrischer Mania-Pupille und synchronem Vokal-Lip-Sync (`A/E/I/O/U`).
3. **Hyper-Polished Y2K Cute-Core Meets Horror UI/UX**
   - `KawaiiWindowChrome` mit Spitzen-Verzierung, Glassmorphism-Blur (`BackdropFilter`), Doppel-Rahmen und Status-LEDs.
   - Physik-basierte UI-Mutationen: UI-Tremor bei Wut/Panik, `RepulsionEvasionButton` (weicht dem Finger physisch aus) und parasitäre Popups ab Phase 3.
4. **Multi-Pass GLSL Fragment Shader (`shaders/yandere_glitch.frag`)**
   - Dreamy Pastel-Halation & LCD-Subpixel-Grid in Phase 1 sowie Datamoshing, radiale RGB-Aufspaltung vom Touch-Punkt und Herzschlag-Zoom-Puls in Phase 3 & 4.
5. **Prozeduraler Dart Audio-Synthesizer (Zero External Assets)**
   - Generiert echte 16-Bit-Mono-PCM/WAV-Streams (`Uint8List`) im RAM für Mimis Sprach-Bleeps, Pitch-Drift, Bitcrushing, FM-Ringmodulation und Sub-Bass-Herzschläge.
6. **Meta-Horror Features**
   - **Incoming Call Hijack**: Vollbild-Anruf von *"Mimi ♡ (In deinem Handy)"*, bei dem der rote *"Ablehnen"*-Button bei Berührung zu *"Annehmen"* mutiert.
   - **Dark Mirror Camera Glitch**: Simulierte Frontkamera-Reflexion mit Mimis Silhouette hinter der Spielerin.

---

## Automatischer Android-APK-Build auf GitHub

Dieses Repository enthält eine fertige GitHub-Actions-Pipeline unter [`.github/workflows/flutter_build.yml`](.github/workflows/flutter_build.yml).
Bei jedem Push auf `main` kompiliert GitHub Actions automatisch eine direkt auf dem Smartphone installierbare **`app-release.apk`** und stellt sie unter **Actions → LUV-OS-Pocket-Companion-APK** zum Download bereit.

## Lokal starten

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
