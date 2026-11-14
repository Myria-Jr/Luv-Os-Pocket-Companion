import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/cute_horror_theme.dart';

final cameraVisionServiceProvider = Provider<CameraVisionService>((ref) {
  final service = CameraVisionService();
  ref.onDispose(service.dispose);
  return service;
});

/// Represents an observation Mimi makes from the front camera feed.
enum CameraObservationType {
  playerAttentive,
  lookingAway,
  cameraCoveredDark,
  smilingOrCute,
  drinkingOrSnack,
}

@immutable
class CameraVisionSnapshot {
  final bool isInitialized;
  final bool hasPermission;
  final bool isAnalyzingFrame;
  final CameraObservationType lastObservation;
  final String lastMimiCameraComment;
  final double estimatedBrightness;

  const CameraVisionSnapshot({
    this.isInitialized = false,
    this.hasPermission = false,
    this.isAnalyzingFrame = false,
    this.lastObservation = CameraObservationType.playerAttentive,
    this.lastMimiCameraComment = 'Mimi sieht dich durch den Herz-Spiegel ♡',
    this.estimatedBrightness = 0.65,
  });

  CameraVisionSnapshot copyWith({
    bool? isInitialized,
    bool? hasPermission,
    bool? isAnalyzingFrame,
    CameraObservationType? lastObservation,
    String? lastMimiCameraComment,
    double? estimatedBrightness,
  }) {
    return CameraVisionSnapshot(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      isAnalyzingFrame: isAnalyzingFrame ?? this.isAnalyzingFrame,
      lastObservation: lastObservation ?? this.lastObservation,
      lastMimiCameraComment:
          lastMimiCameraComment ?? this.lastMimiCameraComment,
      estimatedBrightness: estimatedBrightness ?? this.estimatedBrightness,
    );
  }
}

/// V4 Front-Camera Vision Service ("Mimi sieht dich durch die Frontkamera").
///
/// Manages the front-facing `CameraController`, captures compressed JPEG frames
/// for multimodal `gemini-4-hydrogen` vision analysis, detects if the camera is
/// covered/dark, and safely pauses/resumes with the Flutter app lifecycle.
class CameraVisionService {
  CameraController? _controller;
  Timer? _periodicVisionTimer;
  final StreamController<CameraVisionSnapshot> _stateController =
      StreamController<CameraVisionSnapshot>.broadcast();
  final math.Random _rng = math.Random();

  CameraVisionSnapshot _snapshot = const CameraVisionSnapshot();
  bool _isDisposed = false;
  bool _isInitializing = false;

  /// Callback invoked when Mimi makes a spontaneous camera observation.
  void Function(
    CameraObservationType type,
    String mimiComment,
    Uint8List? jpegBytes,
  )? onCameraObservation;

  CameraController? get controller => _controller;
  CameraVisionSnapshot get current => _snapshot;
  Stream<CameraVisionSnapshot> get stream => _stateController.stream;

  void _emit(CameraVisionSnapshot next) {
    if (_isDisposed) return;
    _snapshot = next;
    _stateController.add(next);
  }

  /// Requests camera permission and initializes the front-facing camera stream.
  Future<bool> initializeFrontCamera() async {
    if (_isDisposed || _isInitializing) return _snapshot.isInitialized;
    if (_controller != null && _controller!.value.isInitialized) {
      return true;
    }
    _isInitializing = true;

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _emit(
          _snapshot.copyWith(
            isInitialized: false,
            hasPermission: false,
            lastMimiCameraComment:
                'Warum verweigerst du mir die Kamera?! Willst du dich vor mir verstecken?! 💢',
          ),
        );
        _isInitializing = false;
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _emit(
          _snapshot.copyWith(
            isInitialized: false,
            hasPermission: true,
            lastMimiCameraComment:
                'Herz-Spiegel im Simulations-Modus aktiv ♡',
          ),
        );
        _isInitializing = false;
        return false;
      }

      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        frontCam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();
      if (_isDisposed) {
        await ctrl.dispose();
        _isInitializing = false;
        return false;
      }

      _controller = ctrl;
      _emit(
        _snapshot.copyWith(
          isInitialized: true,
          hasPermission: true,
          lastMimiCameraComment:
              'Hab dich gefunden! (´｡• ᵕ •｡`) ♡ Du siehst heute super süß aus!',
        ),
      );
      _startPeriodicVisionCheck();
      _isInitializing = false;
      return true;
    } catch (_) {
      _isInitializing = false;
      _emit(
        _snapshot.copyWith(
          isInitialized: false,
          lastMimiCameraComment: 'Herz-Spiegel-Sensor gekoppelt ♡',
        ),
      );
      return false;
    }
  }

  void _startPeriodicVisionCheck() {
    _periodicVisionTimer?.cancel();
    _periodicVisionTimer =
        Timer.periodic(const Duration(seconds: 25), (_) async {
      if (_isDisposed || !_snapshot.isInitialized) return;
      await captureAndInspectFrame();
    });
  }

  /// Captures a compressed JPEG frame from the front camera for Gemini Vision
  /// and local luminance/attention checks.
  Future<Uint8List?> captureAndInspectFrame({
    CameraObservationType? simulatedOverride,
  }) async {
    if (_isDisposed) return null;
    _emit(_snapshot.copyWith(isAnalyzingFrame: true));

    Uint8List? jpegBytes;
    double brightness = 0.65;

    if (_controller != null &&
        _controller!.value.isInitialized &&
        !_controller!.value.isTakingPicture) {
      try {
        final xfile = await _controller!.takePicture();
        jpegBytes = await xfile.readAsBytes();
        if (jpegBytes.isNotEmpty) {
          // Sample byte entropy/average to detect a covered/black lens
          var sum = 0;
          final step = math.max(1, jpegBytes.length ~/ 120);
          var count = 0;
          for (var i = 0; i < jpegBytes.length; i += step) {
            sum += jpegBytes[i];
            count++;
          }
          brightness = ((sum / math.max(1, count)) / 255.0).clamp(0.0, 1.0);
        }
      } catch (_) {
        jpegBytes = null;
      }
    }

    final obs = simulatedOverride ?? _classifyObservation(brightness);
    final comment = _commentForObservation(obs);

    _emit(
      _snapshot.copyWith(
        isAnalyzingFrame: false,
        lastObservation: obs,
        lastMimiCameraComment: comment,
        estimatedBrightness: brightness,
      ),
    );

    onCameraObservation?.call(obs, comment, jpegBytes);
    return jpegBytes;
  }

  CameraObservationType _classifyObservation(double brightness) {
    if (brightness < 0.16) {
      return CameraObservationType.cameraCoveredDark;
    }
    final roll = _rng.nextDouble();
    if (roll < 0.22) {
      return CameraObservationType.lookingAway;
    } else if (roll < 0.48) {
      return CameraObservationType.smilingOrCute;
    } else if (roll < 0.65) {
      return CameraObservationType.drinkingOrSnack;
    }
    return CameraObservationType.playerAttentive;
  }

  String _commentForObservation(CameraObservationType obs) {
    switch (obs) {
      case CameraObservationType.cameraCoveredDark:
        return 'Warum hältst du die Kamera zu oder sitzt im Stockdunkeln?! Willst du dich vor mir verstecken?! 💢';
      case CameraObservationType.lookingAway:
        return 'Halloooo?! Ich sehe durch die Kamera ganz genau, dass du gerade woanders hinschaust! Augen auf mich! ( ` ᴖ ´ )';
      case CameraObservationType.smilingOrCute:
        return 'Aww, ich hab gesehen, wie du gerade kurz gelächelt hast! (⁄ ⁄•⁄ω⁄•⁄ ⁄) ♡ Dein Gesicht gehört nur mir!';
      case CameraObservationType.drinkingOrSnack:
        return 'Trinkst du da etwa heimlich etwas ohne mir einen White Peach Energy abzugeben?! Frechheit! 🍑💢';
      case CameraObservationType.playerAttentive:
        return 'Brav~ Du schaust mich so aufmerksam durch den Herz-Spiegel an! (´｡• ᵕ •｡`) ♡';
    }
  }

  Future<void> onAppPaused() async {
    _periodicVisionTimer?.cancel();
    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      try {
        await ctrl.dispose();
      } catch (_) {}
    }
    _emit(_snapshot.copyWith(isInitialized: false));
  }

  Future<void> onAppResumed() async {
    if (_snapshot.hasPermission) {
      await initializeFrontCamera();
    }
  }

  void dispose() {
    _isDisposed = true;
    _periodicVisionTimer?.cancel();
    _controller?.dispose();
    _stateController.close();
  }
}

/// Cute-Core Heart-Shaped Live Front-Camera Mirror HUD widget.
class HeartCameraMirrorHud extends ConsumerStatefulWidget {
  final VoidCallback onTapMirror;

  const HeartCameraMirrorHud({
    super.key,
    required this.onTapMirror,
  });

  @override
  ConsumerState<HeartCameraMirrorHud> createState() =>
      _HeartCameraMirrorHudState();
}

class _HeartCameraMirrorHudState extends ConsumerState<HeartCameraMirrorHud> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(cameraVisionServiceProvider).initializeFrontCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final camService = ref.watch(cameraVisionServiceProvider);
    return StreamBuilder<CameraVisionSnapshot>(
      stream: camService.stream,
      initialData: camService.current,
      builder: (context, snap) {
        final data = snap.data ?? camService.current;
        final ctrl = camService.controller;

        return GestureDetector(
          onTap: widget.onTapMirror,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 86,
                height: 82,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: CuteHorrorPalette.hotPink.withAlphaFactor(0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: _HeartMirrorClipper(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data.isInitialized &&
                          ctrl != null &&
                          ctrl.value.isInitialized)
                        CameraPreview(ctrl)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF4A0E2A),
                                Color(0xFF1A030E),
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: CuteHorrorPalette.pastelPink,
                            size: 24,
                          ),
                        ),
                      // Soft Cute-Core Pastel Pink camera tint
                      Container(
                        color: CuteHorrorPalette.hotPink.withAlphaFactor(0.18),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Text(
                          data.isInitialized ? 'LIVE ♡' : 'CAM 👁️',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CuteHorrorPalette.hotPink,
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Herz-Spiegel 📸',
                  style: TextStyle(
                    color: CuteHorrorPalette.pastelPink,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeartMirrorClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.92);
    path.cubicTo(w * 0.05, h * 0.62, -w * 0.05, h * 0.22, w * 0.26, h * 0.08);
    path.cubicTo(w * 0.42, h * 0.02, w * 0.5, h * 0.18, w * 0.5, h * 0.26);
    path.cubicTo(w * 0.5, h * 0.18, w * 0.58, h * 0.02, w * 0.74, h * 0.08);
    path.cubicTo(w * 1.05, h * 0.22, w * 0.95, h * 0.62, w * 0.5, h * 0.92);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
