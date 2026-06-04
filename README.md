# Student Expense Tracker

A Flutter Android application for personal expense tracking, designed for university students.

## Features

- **Home Screen** — Monthly spending overview, today's spending, category breakdown with pie chart
- **Add / Edit Expense** — Amount, category, date picker, optional note; full edit and delete with confirmation
- **History** — All expenses sorted newest first, with filter by month/category and note search
- **Statistics** — 6-month trend line chart, category analysis with highest/lowest spending
- **Monthly Report** — Share as plain text or export as professional PDF via Android share sheet

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
├── models/          # Expense, ExpenseFilter, CategorySummary, MonthlySummary
├── services/        # StorageService, ReportService
├── repositories/    # ExpenseRepository (abstract) + LocalExpenseRepository
├── providers/       # Riverpod providers (expenses, filter, derived)
├── screens/         # home/, history/, statistics/, expense_form/
├── widgets/         # Shared reusable widgets
├── utils/           # Constants, formatters, theme, category colors
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

## Currency

All amounts are formatted in Indonesian Rupiah (Rp), e.g. `Rp 15.000`.
