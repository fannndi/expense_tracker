# Student Expense Tracker

A Flutter Android application for personal expense tracking, designed for university students.

## Features

### Expense & Income
- **Add / Edit Expense** — Amount, category, date picker, optional note, wallet selection; full edit and delete with confirmation
- **Income Tracking** — Record allowance, payments from others, projects, and other income sources; income automatically credits the selected wallet balance
- **Auto-fill System** — Automatic entries for missing weekday spending (daily 23:00 notification)

### Reminder / Recurring Payments
- **Smart Reminders** — Create recurring payment templates for bills, subscriptions, and regular expenses
- **Recurrence Options** — Daily, Weekly, Monthly (by date), or Custom (e.g., every 28 days for data packages)
- **Home Screen Integration** — Due reminders appear on the home screen with one-tap "Pay" or "Paid today" status
- **12:00 PM Notifications** — Get reminded at noon when a payment is due
- **Independent Lifecycle** — Reminders are separate from expenses; editing/deleting an expense doesn't affect its reminder

### Wallet Management
- **Multiple Wallets** — Create and manage Cash, E-Money (GoPay, OVO, Dana, etc.), and Debit/Credit Card wallets
- **Wallet Balance** — Each wallet tracks its own balance independently
- **Top-up** — Transfer funds between wallets (e.g., cash to GoPay), recorded as expense + balance transfer
- **Payment Source** — Select which wallet to use when recording expenses
- **Income Credit** — Income automatically adds to the selected wallet balance

### Total Saldo (Grand Total Balance)
- **Real-time Balance** — See your total money across all wallets at a glance
- **Precision Tracking** — `Total Income - Total Expenses (non-transfer)` = your actual remaining balance
- **Transfer Safe** — Top-ups between wallets don't inflate your spending stats

### Dashboard
- **Home Screen** — Total balance, monthly spending overview, today's spending, category breakdown with pie chart
- **Reminder Overview** — Due reminders with Pay/Paid status right on the home screen
- **Wallet Summary** — Horizontal scrollable cards showing all wallet balances on the home screen

### History & Statistics
- **History** — All expenses sorted newest first, with filter by month/category/wallet and note search
- **Statistics** — 6-month trend line chart, category analysis with highest/lowest spending
- **Monthly Report** — Share as plain text or export as professional PDF via Android share sheet

### Localization & Theme
- **Bilingual** — Full English and Bahasa Indonesia support
- **Theme** — Light, Dark, and System theme options
- **Data Export/Import** — Backup and restore all data via JSON file

## Tech Stack

| Concern | Choice |
|---|---|
| UI Framework | Flutter 3.x + Material 3 |
| State Management | Riverpod |
| Navigation | Go Router |
| Storage | Local JSON (`path_provider` + `dart:convert`, atomic writes, mutex lock) |
| Charts | fl_chart |
| PDF Export | pdf + printing |
| Sharing | share_plus |
| Notifications | flutter_local_notifications |

## Architecture

```
lib/
├── models/          # Expense, Income, Wallet, Reminder, ExpenseFilter, CategorySummary, MonthlySummary
├── services/        # StorageService, WalletTransactionService, BackupService, ReportService,
│                    # AutoFillService, AutoFillChecker, ReminderNotificationService
├── repositories/    # ExpenseRepository, IncomeRepository, WalletRepository, ReminderRepository
├── providers/       # Riverpod providers (expenses, incomes, wallets, reminders, filters, derived)
├── screens/
│   ├── home/        # Dashboard with balance, due reminders, summary, pie chart, wallet cards
│   ├── expense_form/# Add/edit expense with wallet picker + optional reminder setup
│   ├── history/     # Expense list with filters
│   ├── statistics/  # Charts and report generation
│   ├── income/      # Income management
│   ├── wallets/     # Wallet management, top-up, add/edit wallet
│   ├── reminders/   # Reminder list + add/edit reminder
│   └── settings/    # Theme, language, reminders link, data export/import, about
├── widgets/         # Shared reusable widgets (ExpenseListTile, CategoryIcon, TodayReminders, ErrorView, etc.)
├── utils/           # Constants, formatters, theme, category colors, wallet type helpers, currency abbreviator
├── routes/          # Go Router config
└── main.dart
```

## Getting Started

```bash
# Get dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
```

## Data Storage

All data is stored locally in `app_data.json` inside the app's documents directory. No internet connection required.

```json
{
  "version": 2,
  "expenses": [...],
  "incomes": [
    {
      "id": "inc_xxx",
      "date": "2026-06-13T00:00:00Z",
      "type": "allowance",
      "amount": 500000,
      "walletId": "wal_xxx"    // income credited to this wallet
    }
  ],
  "wallets": [...],
  "reminders": [...]
}
```

Safety features: atomic writes (temp file + rename), automatic backup recovery from `.bak`, mutex lock for concurrent access.

## Wallet Types

| Type | Description | Examples |
|---|---|---|
| Cash / Tunai | Uang tunai | Dompet, Saku |
| E-Money | Uang elektronik digital | GoPay, OVO, Dana, LinkAja |
| Debit/Credit | Kartu bank | BCA Debit, Mandiri Kredit |

## Currency

All amounts are formatted in Indonesian Rupiah (Rp), e.g. `Rp 15.000`. Large numbers are abbreviated using locale-aware formatting (EN: 1.5M / ID: 1,5jt).

## Documentation

- [Wallet Feature](docs/wallet-feature.md) — Wallet management, top-up, balances
- [Reminder Feature](docs/reminder-feature.md) — Recurring payment reminders, notification scheduling
