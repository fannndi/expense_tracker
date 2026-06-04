import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../models/expense.dart';
import '../../models/expense_filter.dart';
import '../../providers/expense_providers.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/loading_view.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = settings.locale == const Locale('id') ? AppStrings.id : AppStrings.en;

    final filter = ref.watch(filterProvider);
    final expenses = ref.watch(filteredExpensesProvider);
    final allExpenses = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: filter.hasActiveFilter
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: s.clearFilters,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter panel
          if (_showFilters)
            _FilterPanel(filter: filter, allExpenses: allExpenses, strings: s),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: s.searchByNote,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.searchNote != null &&
                        filter.searchNote!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(filterProvider.notifier)
                              .setSearchNote(null);
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(filterProvider.notifier).setSearchNote(v),
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: expenses.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: s.noExpensesFound,
                    subtitle: filter.hasActiveFilter
                        ? s.tryChangingFilters
                        : s.addFirstExpense,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = list[index];
                    return ExpenseListTile(
                      expense: expense,
                      autoLabel: s.auto,
                      autoFillLabel: s.autoFill,
                      onTap: () => context.push(
                        AppRoutes.editExpense,
                        extra: expense,
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(expensesProvider.notifier).reload(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  final ExpenseFilter filter;
  final AsyncValue<List<Expense>> allExpenses;
  final AppStrings strings;

  const _FilterPanel({
    required this.filter,
    required this.allExpenses,
    required this.strings,
  });

  List<({int year, int month})> _availableMonths(List<Expense> list) {
    final seen = <String>{};
    final months = <({int year, int month})>[];
    for (final e in list) {
      final key = '${e.date.year}-${e.date.month}';
      if (seen.add(key)) {
        months.add((year: e.date.year, month: e.date.month));
      }
    }
    months.sort((a, b) {
      final cmp = b.year.compareTo(a.year);
      return cmp != 0 ? cmp : b.month.compareTo(a.month);
    });
    return months;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = strings;
    final months = allExpenses.whenData(_availableMonths).valueOrNull ?? [];
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: filter.category,
                  decoration: InputDecoration(
                    labelText: s.category,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  hint: Text(s.all),
                  items: [
                    DropdownMenuItem<String>(
                        value: null, child: Text(s.all)),
                    ...AppConstants.categories.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(filterProvider.notifier).setCategory(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<({int year, int month})?>(
                  initialValue: filter.year != null && filter.month != null
                      ? (year: filter.year!, month: filter.month!)
                      : null,
                  decoration: InputDecoration(
                    labelText: s.month,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  hint: Text(s.all),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.all)),
                    ...months.map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                            '${DateFormatter.monthName(m.month)} ${m.year}'),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) {
                      ref.read(filterProvider.notifier).setMonth(
                            DateTime.now().year,
                            DateTime.now().month,
                          );
                    } else {
                      ref
                          .read(filterProvider.notifier)
                          .setMonth(v.year, v.month);
                    }
                  },
                ),
              ),
            ],
          ),
          if (filter.hasActiveFilter) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  ref.read(filterProvider.notifier).reset(),
              icon: const Icon(Icons.clear, size: 16),
              label: Text(s.clearFilters),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
