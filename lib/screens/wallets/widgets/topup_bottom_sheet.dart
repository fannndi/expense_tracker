import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/wallet.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/wallet_providers.dart';
import '../../../services/wallet_transaction_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/currency_input_formatter.dart';

class TopUpBottomSheet extends ConsumerStatefulWidget {
  final Wallet destinationWallet;

  const TopUpBottomSheet({super.key, required this.destinationWallet});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required Wallet destinationWallet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TopUpBottomSheet(destinationWallet: destinationWallet),
    );
  }

  @override
  ConsumerState<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends ConsumerState<TopUpBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String? _selectedSourceId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Default source: first cash wallet
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final cashWallets =
        wallets.where((w) => w.type == WalletType.cash).toList();
    if (cashWallets.isNotEmpty) {
      _selectedSourceId = cashWallets.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  AppStrings get _s {
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    return settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = _s;
    final amount =
        ThousandSeparatorFormatter.parseFormatted(_amountCtrl.text.trim()) ?? 0;
    if (_selectedSourceId == null) return;
    if (_selectedSourceId == widget.destinationWallet.id) return;

    setState(() => _loading = true);
    try {
      await ref.read(walletTransactionServiceProvider).topUpWithRecord(
            sourceId: _selectedSourceId!,
            destId: widget.destinationWallet.id,
            amount: amount,
            destName: widget.destinationWallet.name,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToSave}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final sourceWallets =
        wallets.where((w) => w.id != widget.destinationWallet.id).toList();

    final destColor =
        AppConstants.colorForWalletType(widget.destinationWallet.type);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: destColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppConstants.iconForWalletType(widget.destinationWallet.type),
                    color: destColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.topUp,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${s.topUpTo} ${widget.destinationWallet.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Source wallet selector
            DropdownButtonFormField<String>(
              initialValue: _selectedSourceId,
              decoration: InputDecoration(
                labelText: s.topUpFrom,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              isExpanded: true,
              items: sourceWallets.map((w) {
                final color = AppConstants.colorForWalletType(w.type);
                return DropdownMenuItem<String>(
                  value: w.id,
                  child: Row(
                    children: [
                      Icon(
                        AppConstants.iconForWalletType(w.type),
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(w.name)),
                      Text(
                        CurrencyFormatter.format(w.balance),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedSourceId = v),
              validator: (v) {
                if (v == null || v.isEmpty) return s.sourceWallet;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandSeparatorFormatter(),
              ],
              decoration: InputDecoration(
                labelText: s.amount,
                hintText: '50.000',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.amountRequired;
                final n = ThousandSeparatorFormatter.parseFormatted(v.trim());
                if (n == null) return s.enterValidNumber;
                if (n <= 0) return s.amountGreaterThanZero;
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.topUp),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
