import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'routes/app_router.dart';
import 'services/auto_fill_service.dart';
import 'services/auto_fill_checker.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  // Init notification service untuk auto-fill
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
    // Cek auto-fill saat app pertama kali launch
    _runAutoFillCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cek lagi saat app resume dari background
    if (state == AppLifecycleState.resumed) {
      _runAutoFillCheck();
    }
  }

  Future<void> _runAutoFillCheck() async {
    await ref.read(autoFillCheckerProvider).checkAndFill();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
