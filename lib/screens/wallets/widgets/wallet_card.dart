import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/wallet.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_formatter.dart';

class WalletCard extends ConsumerWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onTopUp;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
    this.onTopUp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s =
        settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = AppConstants.colorForWalletType(wallet.type);
    final icon = AppConstants.iconForWalletType(wallet.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          wallet.typeDisplayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTopUp != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: s.topUp,
                      onPressed: onTopUp,
                      color: color,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                CurrencyFormatter.format(wallet.balance),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                s.walletBalance,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
