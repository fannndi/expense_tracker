import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';

class MainShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final onIncomeTab = _isIncomeTab(context);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => onIncomeTab
            ? context.push(AppRoutes.addIncome)
            : context.push(AppRoutes.addExpense),
        tooltip: onIncomeTab ? 'Add Income' : 'Add Expense',
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Income',
          ),
        ],
      ),
    );
  }
}
