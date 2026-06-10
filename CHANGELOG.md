# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

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
