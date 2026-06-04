import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.income)) return 3;
    if (location.startsWith(AppRoutes.statistics)) return 2;
    if (location.startsWith(AppRoutes.history)) return 1;
    return 0;
  }

  bool _isIncomeTab(BuildContext context) {
    return GoRouterState.of(context).uri.toString().startsWith(AppRoutes.income);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final currentIndex = _currentIndex(context);
    final onIncomeTab = _isIncomeTab(context);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => onIncomeTab
            ? context.push(AppRoutes.addIncome)
            : context.push(AppRoutes.addExpense),
        tooltip: onIncomeTab ? s.addIncome : s.addExpense,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.history);
            case 2:
              context.go(AppRoutes.statistics);
            case 3:
              context.go(AppRoutes.income);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: s.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: s.navStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings),
            label: s.navIncome,
          ),
        ],
      ),
    );
  }
}
