import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/wallet.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_providers.dart';
import '../../utils/constants.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const AddWalletScreen({super.key, this.initialWallet});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late WalletType _selectedType;
  bool _loading = false;

  bool get _isEditing => widget.initialWallet != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialWallet?.name ?? '');
    _selectedType = widget.initialWallet?.type ?? WalletType.cash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
    setState(() => _loading = true);

    try {
      if (_isEditing) {
        final updated = widget.initialWallet!.copyWith(
          name: _nameCtrl.text.trim(),
          type: _selectedType,
        );
        await ref.read(walletsProvider.notifier).updateWallet(updated);
      } else {
        await ref.read(walletsProvider.notifier).addWallet(
              name: _nameCtrl.text.trim(),
              type: _selectedType,
            );
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editWallet : s.addWallet),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              tooltip: s.delete,
              onPressed: _loading ? null : _onDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: s.walletName,
                  hintText: s.walletNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.walletName;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Wallet type
              Text(
                s.walletType,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _WalletTypeSelector(
                selected: _selectedType,
                onChanged: (type) => setState(() => _selectedType = type),
                strings: s,
              ),
              const SizedBox(height: 32),

              // Save button
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.save),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed:
                    _loading ? null : () => Navigator.of(context).pop(),
                child: Text(s.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete() async {
    final s = _s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteWallet),
        content: Text(s.deleteWalletConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final wallet = widget.initialWallet!;
      if (wallet.balance > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.walletBalanceNotEmpty)),
          );
        }
        return;
      }
      await ref.read(walletsProvider.notifier).deleteWallet(wallet.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.failedToDelete}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _WalletTypeSelector extends StatelessWidget {
  final WalletType selected;
  final ValueChanged<WalletType> onChanged;
  final AppStrings strings;

  const _WalletTypeSelector({
    required this.selected,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: WalletType.values.map((type) {
        final isSelected = type == selected;
        final color = AppConstants.colorForWalletType(type);
        final icon = AppConstants.iconForWalletType(type);

        String label;
        switch (type) {
          case WalletType.cash:
            label = strings.walletTypeCash;
            break;
          case WalletType.eMoney:
            label = strings.walletTypeEMoney;
            break;
          case WalletType.debitCredit:
            label = strings.walletTypeDebitCredit;
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected ? color.withAlpha(25) : cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(type),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: color, size: 22),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
