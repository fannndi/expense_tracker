import 'package:go_router/go_router.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/wallet.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/income/income_screen.dart';
import '../screens/wallets/wallet_screen.dart';
import '../screens/wallets/add_wallet_screen.dart';
import '../screens/expense_form/add_expense_screen.dart';
import '../screens/expense_form/edit_expense_screen.dart';
import '../screens/income/add_income_screen.dart';
import '../screens/income/edit_income_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const history = '/history';
  static const statistics = '/statistics';
  static const income = '/income';
  static const wallets = '/wallets';
  static const addExpense = '/add-expense';
  static const editExpense = '/edit-expense';
  static const addIncome = '/add-income';
  static const editIncome = '/edit-income';
  static const settings = '/settings';
  static const addWallet = '/add-wallet';
  static const editWallet = '/edit-wallet';
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
        GoRoute(
          path: AppRoutes.wallets,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WalletScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.income,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: IncomeScreen(),
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
    GoRoute(
      path: AppRoutes.addIncome,
      builder: (context, state) => const AddIncomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.editIncome,
      builder: (context, state) {
        final income = state.extra as Income;
        return EditIncomeScreen(income: income);
      },
    ),
    GoRoute(
      path: AppRoutes.addWallet,
      builder: (context, state) => const AddWalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.editWallet,
      builder: (context, state) {
        final wallet = state.extra as Wallet;
        return AddWalletScreen(initialWallet: wallet);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
