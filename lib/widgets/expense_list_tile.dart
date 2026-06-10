import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../models/expense.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_providers.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'category_icon.dart';

class ExpenseListTile extends ConsumerWidget {
  final Expense expense;
  final VoidCallback? onTap;
  /// Override label untuk "auto" badge — kalau null ambil dari locale
  final String? autoLabel;
  final String? autoFillLabel;

  const ExpenseListTile({
    super.key,
    required this.expense,
    this.onTap,
    this.autoLabel,
    this.autoFillLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = AppStrings.forLocale(settings.locale);

    final isAutoFill = expense.isAutoFill;
    final isTransfer = expense.isTransfer;
    final autoLbl = autoLabel ?? s.auto;
    final autoFillLbl = autoFillLabel ?? s.autoFill;
    final theme = Theme.of(context);

    // Tampilkan nama kategori sesuai locale
    final categoryDisplay = isTransfer ? s.topUp : s.categoryDisplayName(expense.category);

    // Get wallet name if walletId exists
    String? walletName;
    if (expense.walletId != null) {
      final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
      final wallet = wallets.where((w) => w.id == expense.walletId).firstOrNull;
      walletName = wallet?.name;
    }

    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isTransfer)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.swap_horiz,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
            )
          else
            CategoryIcon(category: expense.category),
          if (isAutoFill)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  autoLbl,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            categoryDisplay,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isAutoFill) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                autoFillLbl,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
          if (walletName != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                walletName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.formatDisplay(expense.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (expense.note != null && expense.note!.isNotEmpty)
            Text(
              expense.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isAutoFill
                    ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
                    : theme.colorScheme.onSurfaceVariant,
                fontStyle:
                    isAutoFill ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      isThreeLine: expense.note != null && expense.note!.isNotEmpty,
      trailing: Text(
        expense.amount == 0 && isAutoFill
            ? 'Rp 0'
            : CurrencyFormatter.format(expense.amount),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: expense.amount == 0 && isAutoFill
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
