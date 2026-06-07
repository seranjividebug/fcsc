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
  await Hive.openBox('kpi_cache');
  await Hive.openBox<String>('bookmarks'); // saved indicator IDs (insertion order)

  // Clear stale cache for education & health IDs so they always re-fetch
  // (previously cached zero-values caused persistent empty display)
  final indicatorBox = Hive.box<String>('indicator_cache');
  const staleCacheIds = [
    'indicator_student_enrolment', 'indicator_student_enrolment_meta',
    'indicator_teaching_staff',    'indicator_teaching_staff_meta',
    'indicator_higher_education',  'indicator_higher_education_meta',
    'indicator_health_services',   'indicator_health_services_meta',
    'indicator_health_clinics_centers', 'indicator_health_clinics_centers_meta',
    'indicator_health_hospital_beds',   'indicator_health_hospital_beds_meta',
    'indicator_health_professionals',   'indicator_health_professionals_meta',
  ];
  for (final key in staleCacheIds) {
    await indicatorBox.delete(key);
  }
  final kpiBox = Hive.box('kpi_cache');
  const staleKpiIds = [
    'kpi_general_education', 'kpi_general_education_v2',
    'kpi_higher_education',  'kpi_higher_education_v2',
    'kpi_hospitals',         'kpi_hospitals_v2',
    'kpi_clinics_centers',   'kpi_clinics_centers_v2',
  ];
  for (final key in staleKpiIds) {
    await kpiBox.delete(key);
  }

  // ─── Run ─────────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: UaeStatsApp(),
    ),
  );
}
