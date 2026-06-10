import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/wallet_providers.dart';
import '../../../utils/currency_formatter.dart';

/// Replaces the old BalanceCard. Shows a prominent hero section with the
/// monthly spending total and income/balance pills.
class HeroSection extends ConsumerWidget {
  final int income;
  final int expense;
  final int balance;
  final String monthLabel;

  const HeroSection({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(expense),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.totalSpending,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                icon: Icons.arrow_downward_rounded,
                label: s.income,
                value: CurrencyFormatter.format(income),
                iconColor: cs.tertiary,
              ),
              const SizedBox(width: 24),
              _StatPill(
                icon: isPositive ? Icons.trending_up : Icons.trending_down,
                label: s.balance,
                value: '${isPositive ? '+' : '-'}${CurrencyFormatter.format(balance.abs())}',
                iconColor: isPositive ? cs.tertiary : cs.error,
                valueColor: isPositive ? cs.tertiary : cs.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan total saldo keseluruhan
class TotalBalanceSection extends ConsumerWidget {
  const TotalBalanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalBalance = ref.watch(grandTotalBalanceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.totalBalance,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    totalBalance.when(
                      data: (total) => Text(
                        CurrencyFormatter.format(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Text(
                        '-',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
