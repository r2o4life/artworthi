import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/portfolio_project.dart';
import 'package:portfoliox/core/models/system_log.dart';
import 'package:portfoliox/core/repository/portfolio_repository.dart';
import 'package:portfoliox/core/repository/portfolio_repository_factory.dart';
import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/core/state/app_state.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/nav.dart';
import 'package:portfoliox/widgets/observable_runtime_shell.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() {
  // Initialize the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = SystemsProfileSeed.systemsProfileArturoRobertoGarcia;
    return MultiProvider(
      providers: [
        Provider<SystemsProfile>.value(value: profile),
        Provider<PortfolioRepository>(
          create: (_) => PortfolioRepositoryFactory.create(),
          dispose: (_, repo) => repo.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => AppController(initial: const AppState.initial(), profile: profile)),
        StreamProvider<List<FrameworkMetric>>(
          create: (ctx) => ctx.read<PortfolioRepository>().watchMetrics(),
          initialData: const [],
          catchError: (_, __) => const [],
        ),
        StreamProvider<List<PortfolioProject>>(
          create: (ctx) => ctx.read<PortfolioRepository>().watchProjects(),
          initialData: const [],
          catchError: (_, __) => const [],
        ),
        StreamProvider<List<SystemLog>>(
          create: (ctx) => ctx.read<PortfolioRepository>().watchSystemLogs(),
          initialData: const [],
          catchError: (_, __) => const [],
        ),
      ],
      child: MaterialApp.router(
        title: 'PortfolioX',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        builder: (context, child) => ObservableRuntimeShell(child: child ?? const SizedBox.shrink()),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
