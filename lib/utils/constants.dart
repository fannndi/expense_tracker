import 'package:flutter/material.dart';

import '../models/wallet.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Student Expense Tracker';

  /// Single JSON file untuk semua data (expenses + incomes + wallets)
  static const String dataFileName = 'expenses.json';

  static const List<String> categories = [
    'Food',
    'Fuel',
    'Internet',
    'Subscription',
    'Education',
    'Entertainment',
    'Other',
  ];

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Jam auto-fill: 23:00
  static const int autoFillHour = 23;
  static const int autoFillMinute = 0;

  /// Kategori default untuk entry auto-fill
  static const String autoFillCategory = 'Other';

  /// Colors untuk wallet type
  static Color colorForWalletType(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return const Color(0xFF4CAF50); // green
      case WalletType.eMoney:
        return const Color(0xFF2196F3); // blue
      case WalletType.debitCredit:
        return const Color(0xFFFF9800); // orange
    }
  }

  /// Icons untuk wallet type
  static IconData iconForWalletType(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments_outlined;
      case WalletType.eMoney:
        return Icons.phone_android;
      case WalletType.debitCredit:
        return Icons.credit_card;
    }
  }
}
