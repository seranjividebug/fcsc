// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uae_stats/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── System UI ────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock portrait orientation for POC
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Hive (local cache) ───────────────────────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox<String>('indicator_cache');

  // ─── Run ─────────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: UaeStatsApp(),
    ),
  );
}
