// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/features/demography/presentation/screens/demography_screen.dart';
import 'package:uae_stats/features/economy/presentation/screens/economy_screen.dart';
import 'package:uae_stats/features/environment/presentation/screens/environment_screen.dart';
import 'package:uae_stats/features/home/presentation/screens/home_screen.dart';
import 'package:uae_stats/features/indicator_detail/presentation/screens/indicator_detail_screen.dart';
import 'package:uae_stats/features/population_growth/presentation/screens/population_growth_screen.dart';
import 'package:uae_stats/features/search/presentation/screens/search_screen.dart';
import 'package:uae_stats/features/splash/presentation/splash_screen.dart';

/// Named route paths — never use raw strings in navigation calls.
abstract final class AppRoutes {
  static const String splash            = '/';
  static const String home              = '/home';
  static const String demography        = '/demography';
  static const String economy           = '/economy';
  static const String environment       = '/environment';
  static const String indicator         = '/indicator/:id';
  static const String populationGrowth  = '/population-growth';
  static const String search            = '/search';

  static String indicatorPath(String id) => '/indicator/$id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.demography,
      builder: (context, state) => const DemographyScreen(),
    ),
    GoRoute(
      path: AppRoutes.economy,
      builder: (context, state) => const EconomyScreen(),
    ),
    GoRoute(
      path: AppRoutes.environment,
      builder: (context, state) => const EnvironmentScreen(),
    ),
    GoRoute(
      path: AppRoutes.indicator,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'population';
        return IndicatorDetailScreen(indicatorId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.populationGrowth,
      builder: (context, state) => const PopulationGrowthScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Route not found: ${state.uri}',
        style: const TextStyle(color: Colors.red),
      ),
    ),
  ),
);
