import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/settings_provider.dart';
import 'routes/app_router.dart';
import 'services/auto_fill_service.dart';
import 'services/auto_fill_checker.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  final notifService = AutoFillNotificationService();
  await notifService.init();
  await notifService.requestPermission();
  await notifService.scheduleDailyReminder();

  runApp(
    const ProviderScope(
      child: StudentExpenseTrackerApp(),
    ),
  );
}

class StudentExpenseTrackerApp extends ConsumerStatefulWidget {
  const StudentExpenseTrackerApp({super.key});

  @override
  ConsumerState<StudentExpenseTrackerApp> createState() =>
      _StudentExpenseTrackerAppState();
}

class _StudentExpenseTrackerAppState
    extends ConsumerState<StudentExpenseTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runAutoFillCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAutoFillCheck();
    }
  }

  Future<void> _runAutoFillCheck() async {
    await ref.read(autoFillCheckerProvider).checkAndFill();
  }

  @override
  Widget build(BuildContext context) {
    // Watch settings — rebuild MaterialApp setiap kali locale/theme berubah
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,

      // ── Locale setup ──────────────────────────────────────────────────
      // locale diset dari settings — trigger rebuild seluruh widget tree
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      // Delegates ini penting agar DatePicker, Material widgets, dll
      // juga ikut ganti bahasa (nama bulan, hari, dll)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: appRouter,
    );
  }
}
