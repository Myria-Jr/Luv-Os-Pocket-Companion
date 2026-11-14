import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/hardware_bridge_service.dart';
import 'core/services/notification_service.dart';
import 'features/shell/luv_os_shell.dart';
import 'state/corruption_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for authentic Found-Phone feel
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {
    // Ignore on platforms that do not support orientation lock
  }

  // Warm up the GLSL Yandere Glitch Fragment Shader during bootstrap
  try {
    await ui.FragmentProgram.fromAsset('shaders/yandere_glitch.frag');
  } catch (_) {
    // Graceful fallback handled in GlitchShaderWrapper if shader asset fails in test runner
  }

  runApp(
    const ProviderScope(
      child: LuvOsApp(),
    ),
  );
}

class LuvOsApp extends ConsumerStatefulWidget {
  const LuvOsApp({super.key});

  @override
  ConsumerState<LuvOsApp> createState() => _LuvOsAppState();
}

class _LuvOsAppState extends ConsumerState<LuvOsApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationServiceProvider).initialize();
      ref.read(hardwareBridgeProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final corruptionState = ref.watch(corruptionProvider);
    final palette = corruptionState.palette;

    return MaterialApp(
      title: 'LUV.OS // Pocket Companion',
      debugShowCheckedModeBanner: false,
      theme: palette.toThemeData(),
      home: const LuvOsShell(),
    );
  }
}
