# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

---

## [1.4.0] - 2026-06-13

### Added

#### Income Credits Wallet
- **Income.walletId** — New optional field to link income to a wallet (nullable for backward compatibility)
- **Wallet picker in IncomeForm** — Dropdown to select destination wallet when recording income
- **Auto credit on save** — Income amount is automatically added to the selected wallet balance
- **Auto debit on delete** — Deleting an income deducts the amount from the credited wallet
- **Auto rebalance on edit** — Editing income refunds the old wallet and credits the new one
- **Wallet badge in IncomeScreen** — `_IncomeTile` shows wallet icon and name in subtitle

#### Transactional Safety (Income)
- **Rollback on add** — If wallet credit fails, the created income is deleted
- **Rollback on update** — If wallet operations fail, original income is restored
- **Rollback on delete** — If wallet debit fails, the deleted income is restored

### Changed
- **IncomeForm** — Added wallet picker dropdown (defaults to first Cash wallet)
- **IncomeProviders** — `addIncome`, `updateIncome`, `deleteIncome` now handle wallet credit/debit with rollback
- **WalletsNotifier** — Added `creditWallet(walletId, amount)` method
- **IncomeScreen** — Changed `_IncomeTile` from `StatelessWidget` to `ConsumerWidget` to access wallet data
- **OnIncomeCallback** — Extended with optional `walletId` parameter

---

## [1.3.0] - 2026-06-13

### Added

#### Reminder / Recurring Payments
- **Reminder model** — New `Reminder` data model with `ReminderRecurrence` enum (daily, weekly, monthlyByDate, customDays)
- **Reminder CRUD** — Add, edit, delete reminders via `ReminderRepository` + `RemindersNotifier`
- **Add/Edit Reminder screen** — Full form with title, category, amount, note, wallet, and recurrence settings
- **Reminder list screen** — All reminders with enable/disable toggle, delete, and edit capabilities
- **Today's reminders on home** — `TodayRemindersSection` widget showing due/overdue reminders with Pay/Paid status
- **One-tap Pay** — Record an expense from a reminder with automatic wallet debit
- **Smart status** — Shows "Paid today" if expense with matching `reminderId` exists for today, "Pay" button otherwise
- **Settings entry** — "Reminders" menu item in Settings screen

#### Recurrence Options
| Type | Behavior |
|------|----------|
| **Daily** | Every day at 12:00 PM |
| **Weekly** | Every 7 days at 12:00 PM |
| **Monthly** | On specific day of month (1-31), auto-handles overflow (e.g. Feb 30 → Feb 28) |
| **Custom** | Every N days (e.g. 28 for Indonesian data packages, 30 for subscriptions) |

#### Reminder from Expense Form
- **"Set Reminder" toggle** — Optional section in `ExpenseForm` to create a reminder alongside an expense
- **Auto-fill** — Title, category, amount, note, and wallet are pre-filled from the expense
- **Separate lifecycle** — Reminder is independent; editing/deleting the expense does not affect the reminder

#### Notification System
- **`ReminderNotificationService`** — Dedicated notification channel (`reminder_channel`) separate from auto-fill
- **12:00 PM scheduling** — Customizable notification time set to noon
- **Per-reminder scheduling** — Each reminder has a unique, stable `notificationId` stored in JSON
- **Auto-reschedule** — After recording payment, next due date is computed and notification rescheduled
- **Permission request** — Requests notification + exact alarm permissions at startup

#### Data Model Changes
- **Expense.reminderId** — New nullable field to trace payments back to their originating reminder
- **ReminderData** — Lightweight DTO class for passing recurrence config from form to screen

### Changed
- **Storage format** — `app_data.json` now includes `reminders` array; version bumped to 2
- **StorageService** — Added `loadReminders()` / `saveReminders()` with mutex safety
- **ExpenseProviders** — `addExpense()` now accepts optional `reminderId` parameter
- **WalletTransactionService** — `addExpenseWithWalletDebit()` now accepts optional `reminderId` parameter
- **OnSaveCallback** — Extended with optional `ReminderData? reminderData` parameter
- **Home screen** — Added `TodayRemindersSection` between total balance and hero section
- **Expense form** — Added reminder recurrence section (switch + dropdown for daily/weekly/monthly/custom)
- **AddExpenseScreen** — Creates reminder + schedules notification when reminder data is provided
- **EditExpenseScreen** — Shows info banner when editing expense linked to a reminder
- **Localization** — 20 new string keys (EN + ID) for all reminder UI texts

### Fixed
- **Wallet balance tracking** — Payment from reminder correctly debits the selected wallet via `WalletTransactionService`

---

## [1.2.0] - 2026-06-11

### Added

#### Data Safety
- **Atomic writes** — Data saved to temp file first, then renamed (prevents corruption on crash)
- **Mutex lock** — `Completer<void>` lock prevents concurrent read/write race conditions
- **Backup & recovery** — Automatic restore from `.bak` file if main file is corrupted
- **Auto-migration** — Seamless migration from legacy `expenses.json` to `app_data.json`
- **Data versioning** — JSON includes `version` field for future schema migrations

#### Transactional Wallet Operations
- **`WalletTransactionService`** — Centralized service with automatic rollback on failure
- **Rollback on expense creation** — If wallet debit fails, the created expense is deleted
- **Rollback on expense update** — If new wallet debit fails, old balances are restored
- **Rollback on expense delete** — If deletion fails after wallet refund, the debit is reversed
- **Rollback on top-up** — If transfer record creation fails, wallet balances are reversed

#### Code Quality
- **`CurrencyAbbreviator`** — Locale-aware utility (EN: M/K, ID: jt/rb) replacing duplicated `_formatShort` in charts
- **`_HeroSectionBuilder`** — Extracted nested `.when()` callbacks from home screen into dedicated widget
- **`_kFabPadding`** — Named constant replacing magic number `SizedBox(height: 100)`
- **Type safety** — `List wallets` → `List<Wallet>` in home screen
- **Enum comparison** — `w.type.name == 'cash'` → `w.type == WalletType.cash`
- **Code cleanup** — Removed stale stub comment in `settings_provider.dart`; fixed two-statements-on-one-line in `report_service.dart`

#### Testing — 128 Tests
| Area | Tests |
|------|-------|
| Models | 4 files — expense, income, wallet, expense_filter |
| Services | 1 file — report_service |
| Repository | 1 file — expense, income, wallet repositories |
| Providers | 3 files — expense, income, wallet providers |
| Utils | 3 files — currency_abbreviator, currency_formatter, currency_input_formatter |
| Widgets | 3 files — category_icon, empty_state, expense_list_tile |
| Integration | 1 file — widget_test (3 variants) |

#### Backup & Share
- **`BackupService`** — Export data to `.json` file, import from file via share dialog
- **Export from Settings** — One-tap share of all data as JSON file
- **Import placeholder** — Dialog with warning before replacing all data

#### Settings & About
- **About section** — Displays app name, version, and description in Settings
- **Export/Import UI** — Menu entries in Settings for data management

### Changed
- **Storage file** — Renamed from `expenses.json` to `app_data.json` (stores expenses + incomes + wallets)
- **AppStrings** — Added `localeCode` getter via `AppStringsExtension`
- **ErrorView** — Converted from `StatelessWidget` to `ConsumerWidget` with localized strings (`somethingWentWrong`, `tryAgain`)
- **Wallet section** — Localized section titles and wallet type labels (Cash/E-Money/Debit-Credit)
- **Income form** — `_sourcePlaceholder` now locale-dependent

---

## [1.1.0] - 2026-06-10

### Added

#### Wallet Management
- **Wallet model** — New `Wallet` data model with `WalletType` enum (cash, eMoney, debitCredit)
- **Wallet CRUD** — Add, edit, and delete wallets with balance tracking
- **Wallet screen** — New dedicated screen for managing all wallets, accessible from bottom navigation
- **Add/Edit Wallet screen** — Form to create or modify wallets with name and type selection
- **Wallet card widget** — Reusable card component showing wallet name, type icon, and balance

#### Top-up Feature
- **Top-up bottom sheet** — Modal dialog for transferring funds between wallets
- **Source wallet selector** — Choose which wallet to take funds from during top-up
- **Balance validation** — Prevents top-up if source wallet has insufficient balance
- **Transfer recording** — Each top-up creates an expense record with `isTransfer: true` flag

#### Expense Payment Source
- **Wallet picker in expense form** — New "Pay from" dropdown when adding/editing expenses
- **Wallet balance tracking** — Expense automatically debits the selected wallet's balance
- **Wallet name badge** — Expense list tiles show which wallet was used for payment
- **Transfer icon** — Top-up entries display a distinct swap icon instead of category icon

#### Total Balance
- **Grand total balance** — Prominent display on home screen showing all-time income minus expenses
- **Real-time updates** — Total balance updates instantly with every income, expense, or top-up
- **Wallet summary on home** — Horizontal scrollable wallet cards showing individual balances

#### Statistics Accuracy
- **Transfer exclusion** — Top-up/transfer expenses excluded from:
  - Monthly spending totals
  - Today's spending totals
  - Category breakdown (pie chart)
  - Monthly trend chart (6 months)
  - Category analysis (statistics screen)
- **Grand total calculation** — `Total Income (all time) - Total Expenses non-transfer (all time)`

#### Navigation
- **5-tab bottom navigation** — Added "Dompet/Wallets" tab between Statistics and Income
- **Wallet routes** — New routes: `/wallets`, `/add-wallet`, `/edit-wallet`

#### Localization
- **27 new string keys** — Full English and Indonesian translations for all wallet-related UI
- **Wallet type display names** — Localized names for Cash, E-Money, Debit/Credit Card

### Changed
- **Expense model** — Added `walletId` (String?) and `isTransfer` (bool) fields
- **Expense form** — Updated callback to include `walletId` and `isTransfer` parameters
- **AddExpenseScreen** — Now debits wallet balance on save
- **EditExpenseScreen** — Now refunds old wallet and debits new wallet on save; refunds on delete
- **ExpenseListTile** — Shows wallet name badge and transfer icon for top-up entries
- **Home screen** — Added total balance section and wallet summary section
- **Storage format** — `expenses.json` now includes `wallets` array alongside `expenses` and `incomes`

### Fixed
- **Balance accuracy** — Top-ups no longer inflate spending statistics
- **Backward compatibility** — Existing expenses without `walletId` or `isTransfer` fields work correctly (default to null/false)

---

## [1.0.0] - 2026-06-01

### Added
- Initial release
- Expense tracking with categories (Food, Fuel, Internet, Subscription, Education, Entertainment, Other)
- Income tracking (Allowance, From Person, Project, Other)
- Monthly balance calculation
- History with search and filters
- Statistics with 6-month trend chart and category analysis
- PDF report generation and sharing
- Auto-fill system for missing weekday entries (23:00 daily notification)
- English and Indonesian localization
- Light/Dark/System theme support
- Material 3 design
