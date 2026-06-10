# Student Expense Tracker

A Flutter Android application for personal expense tracking, designed for university students.

## Features

### Expense & Income
- **Add / Edit Expense** — Amount, category, date picker, optional note; full edit and delete with confirmation
- **Income Tracking** — Record allowance, payments from others, projects, and other income sources
- **Auto-fill System** — Automatic Rs 0 entries for missing weekday spending (daily 23:00 notification)

### Wallet Management
- **Multiple Wallets** — Create and manage Cash, E-Money (GoPay, OVO, Dana, etc.), and Debit/Credit Card wallets
- **Wallet Balance** — Each wallet tracks its own balance independently
- **Top-up** — Transfer funds between wallets (e.g., cash to GoPay), recorded as expense + balance transfer
- **Payment Source** — Select which wallet to use when recording expenses

### Total Saldo (Grand Total Balance)
- **Real-time Balance** — See your total money across all wallets at a glance
- **Precision Tracking** — `Total Income - Total Expenses (non-transfer)` = your actual remaining balance
- **Transfer Safe** — Top-ups between wallets don't inflate your spending stats

### Dashboard
- **Home Screen** — Total balance, monthly spending overview, today's spending, category breakdown with pie chart
- **Wallet Summary** — Horizontal scrollable cards showing all wallet balances on the home screen

### History & Statistics
- **History** — All expenses sorted newest first, with filter by month/category/wallet and note search
- **Statistics** — 6-month trend line chart, category analysis with highest/lowest spending
- **Monthly Report** — Share as plain text or export as professional PDF via Android share sheet

### Localization & Theme
- **Bilingual** — Full English and Bahasa Indonesia support
- **Theme** — Light, Dark, and System theme options

## Tech Stack

| Concern | Choice |
|---|---|
| UI Framework | Flutter 3.x + Material 3 |
| State Management | Riverpod |
| Navigation | Go Router |
| Storage | Local JSON (`path_provider` + `dart:convert`) |
| Charts | fl_chart |
| PDF Export | pdf + printing |
| Sharing | share_plus |

## Architecture

```
lib/
├── models/          # Expense, Income, Wallet, ExpenseFilter, CategorySummary, MonthlySummary
├── services/        # StorageService, ReportService, AutoFillService, AutoFillChecker
├── repositories/    # ExpenseRepository, IncomeRepository, WalletRepository (abstract + local)
├── providers/       # Riverpod providers (expenses, incomes, wallets, filters, derived)
├── screens/
│   ├── home/        # Dashboard with balance, summary, pie chart, wallet cards
│   ├── expense_form/# Add/edit expense with wallet picker
│   ├── history/     # Expense list with filters
│   ├── statistics/  # Charts and report generation
│   ├── income/      # Income management
│   ├── wallets/     # Wallet management, top-up, add/edit wallet
│   └── settings/    # Theme and language settings
├── widgets/         # Shared reusable widgets (ExpenseListTile, CategoryIcon, etc.)
├── utils/           # Constants, formatters, theme, category colors, wallet type helpers
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

All data is stored locally in `expenses.json` inside the app's documents directory. No internet connection required.

```json
{
  "expenses": [...],
  "incomes": [...],
  "wallets": [
    {
      "id": "wal_xxx",
      "name": "Dompet",
      "type": "cash",
      "balance": 500000
    }
  ]
}
```

## Wallet Types

| Type | Description | Examples |
|---|---|---|
| Cash / Tunai | Uang tunai | Dompet, Saku |
| E-Money | Uang elektronik digital | GoPay, OVO, Dana, LinkAja |
| Debit/Credit | Kartu bank | BCA Debit, Mandiri Kredit |

## Currency

All amounts are formatted in Indonesian Rupiah (Rp), e.g. `Rp 15.000`.

## Documentation

Detailed documentation for the wallet feature is available at [`docs/wallet-feature.md`](docs/wallet-feature.md).
