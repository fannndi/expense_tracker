import 'package:go_router/go_router.dart';

import '../models/expense.dart';
import '../screens/shell/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/expense_form/add_expense_screen.dart';
import '../screens/expense_form/edit_expense_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const history = '/history';
  static const statistics = '/statistics';
  static const addExpense = '/add-expense';
  static const editExpense = '/edit-expense';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.history,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: AppRoutes.editExpense,
      builder: (context, state) {
        final expense = state.extra as Expense;
        return EditExpenseScreen(expense: expense);
      },
    ),
  ],
);
