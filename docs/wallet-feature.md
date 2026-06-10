# Wallet Feature — E-Money, Debit/Credit Card & Total Saldo

## Overview

Fitur Wallet memungkinkan kamu melacak semua sumber dana dalam satu aplikasi:
- **Cash / Dompet** — uang tunai
- **E-Money** — GoPay, OVO, Dana, LinkAja, dll
- **Debit/Credit Card** — kartu debit atau kredit

Setiap wallet memiliki saldo sendiri yang otomatis berubah setiap kali ada expense, income, atau top-up.

---

## Konsep Penting

### Total Saldo (Grand Total Balance)

**Total Saldo = Total Semua Pemasukan (all time) - Total Pengeluaran non-transfer (all time)**

Ini adalah angka presisi yang merepresentasikan seluruh uang kamu saat ini, tersebar di semua wallet. Angka ini:
- **BERTAMBAH** saat ada pemasukan (uang saku, dll)
- **BERKURANG** saat ada pengeluaran (makan, BBM, dll)
- **TIDAK BERUBAH** saat top-up antar wallet (karena cuma pindah dompet)

### Wallet Balance (Saldo per Wallet)

Setiap wallet memiliki saldo individual:
- Saldo wallet **berkurang** saat kamu bayar pakai wallet tersebut
- Saldo wallet **bertambah** saat top-up ke wallet tersebut
- Saldo wallet **berkurang** saat kamu top-up DARI wallet tersebut

### Transfer / Top-up

Top-up adalah perpindahan saldo antar wallet. Di sistem ini:
1. Saldo dikurangi dari source wallet
2. Saldo ditambahkan ke destination wallet
3. Sebuah expense record dibuat dengan flag `isTransfer: true`
4. Expense transfer **TIDAK dihitung** sebagai pengeluaran di statistik

---

## Data Model

### Wallet

```
Wallet {
  id: String          // "wal_<uuid>"
  name: String        // "GoPay", "BCA Debit", "Dompet"
  type: WalletType    // cash | eMoney | debitCredit
  balance: int        // saldo saat ini (IDR)
}
```

### Expense (updated)

```
Expense {
  id: String
  date: DateTime
  category: String
  amount: int
  note: String?
  isAutoFill: bool
  walletId: String?   // NEW — wallet yang dipakai bayar
  isTransfer: bool    // NEW — true jika ini top-up antar wallet
}
```

---

## Storage

Semua data disimpan di satu file JSON: `expenses.json`

```json
{
  "expenses": [
    {
      "id": "exp_xxx",
      "date": "2026-06-10T00:00:00Z",
      "category": "Food",
      "amount": 15000,
      "note": "Lunch",
      "walletId": "wal_xxx",
      "isTransfer": false
    }
  ],
  "incomes": [...],
  "wallets": [
    {
      "id": "wal_xxx",
      "name": "Dompet",
      "type": "cash",
      "balance": 500000
    },
    {
      "id": "wal_yyy",
      "name": "GoPay",
      "type": "eMoney",
      "balance": 150000
    }
  ]
}
```

---

## File Structure (New & Updated)

### New Files

| File | Purpose |
|---|---|
| `lib/models/wallet.dart` | Wallet model + WalletType enum |
| `lib/repositories/wallet_repository.dart` | Abstract + LocalWalletRepository |
| `lib/providers/wallet_providers.dart` | Wallet state management + grandTotalBalanceProvider |
| `lib/screens/wallets/wallet_screen.dart` | Wallet management screen |
| `lib/screens/wallets/add_wallet_screen.dart` | Add/edit wallet form |
| `lib/screens/wallets/widgets/wallet_card.dart` | Wallet card widget |
| `lib/screens/wallets/widgets/topup_bottom_sheet.dart` | Top-up dialog |
| `docs/wallet-feature.md` | This documentation |

### Updated Files

| File | Changes |
|---|---|
| `lib/models/expense.dart` | +`walletId`, +`isTransfer`, updated copyWith/fromJson/toJson |
| `lib/services/storage_service.dart` | +`loadWallets()`, +`saveWallets()` |
| `lib/providers/expense_providers.dart` | +`grandTotalBalanceProvider`, all spending providers exclude transfers |
| `lib/screens/expense_form/widgets/expense_form.dart` | +wallet picker dropdown, updated OnSaveCallback |
| `lib/screens/expense_form/add_expense_screen.dart` | Wallet balance debit on save |
| `lib/screens/expense_form/edit_expense_screen.dart` | Wallet balance refund on edit/delete |
| `lib/screens/home/home_screen.dart` | +wallet summary section |
| `lib/screens/home/widgets/balance_card.dart` | +TotalBalanceSection widget |
| `lib/screens/shell/main_shell.dart` | 5-tab bottom navigation |
| `lib/routes/app_router.dart` | +wallet routes |
| `lib/l10n/app_strings.dart` | +27 new string keys (EN + ID) |
| `lib/utils/constants.dart` | +wallet type colors/icons |
| `lib/widgets/expense_list_tile.dart` | +wallet name badge, +transfer icon |

---

## UI Flow

### 1. Menambah Wallet

1. Buka tab **Dompet** di bottom navigation
2. Ketuk tombol **+** (FAB)
3. Isi nama wallet (mis: "GoPay", "BCA Debit")
4. Pilih tipe: Cash / E-Money / Debit-Credit
5. Ketuk **Simpan**
6. Wallet baru muncul di daftar dengan saldo Rp 0

### 2. Top-up Wallet

1. Buka tab **Dompet**
2. Ketuk tombol **Top-up** (ikon +) di wallet card
3. Pilih source wallet (dari mana uang diambil, mis: Dompet)
4. Masukkan jumlah
5. Ketuk **Isi Ulang**
6. Saldo source berkurang, saldo destination bertambah
7. Sebuah expense record "Top-up [nama wallet]" tercatat

### 3. Mencatat Expense dengan Wallet

1. Ketuk tombol **+** (FAB) di nav bar
2. Pilih **"Bayar dari"** — pilih wallet yang dipakai bayar
3. Isi jumlah, kategori, tanggal, catatan
4. Ketuk **Simpan**
5. Saldo wallet yang dipilih otomatis berkurang

### 4. Melihat Total Saldo

- Di **Home Screen**, bagian paling atas menampilkan **Total Saldo** (angka besar)
- Ini adalah jumlah seluruh uang kamu di semua wallet
- Di bawahnya ada **ringkasan wallet** dalam bentuk horizontal scrollable cards

### 5. Mengedit/Menghapus Wallet

1. Ketuk wallet card di tab Dompet
2. Edit nama atau tipe
3. Ketuk **Simpan** atau **Hapus**
4. Wallet dengan saldo > 0 tidak bisa dihapus

---

## Business Rules

| Rule | Detail |
|---|---|
| Top-up tidak mengubah Total Saldo | Karena cuma transfer antar wallet |
| Top-up tercatat sebagai expense | Dengan flag `isTransfer: true` |
| Expense transfer tidak dihitung di statistik | Pie chart, trend, breakdown exclude transfer |
| Wallet dengan saldo > 0 tidak bisa dihapus | Mencegah kehilangan data |
| Delete expense mengembalikan saldo wallet | Saldo wallet di-refund |
| Edit expense menyesuaikan saldo wallet | Saldo lama di-refund, saldo baru di-debit |
| Default wallet untuk expense | Wallet tipe Cash pertama yang tersedia |

---

## Localization

Semua string tersedia dalam **English** dan **Bahasa Indonesia**:

| Key | EN | ID |
|---|---|---|
| `wallets` | Wallets | Dompet |
| `addWallet` | Add Wallet | Tambah Dompet |
| `editWallet` | Edit Wallet | Edit Dompet |
| `deleteWallet` | Delete Wallet | Hapus Dompet |
| `walletName` | Wallet Name | Nama Dompet |
| `walletType` | Wallet Type | Tipe Dompet |
| `walletTypeCash` | Cash | Tunai |
| `walletTypeEMoney` | E-Money | Uang Elektronik |
| `walletTypeDebitCredit` | Debit/Credit Card | Kartu Debit/Kredit |
| `payFrom` | Pay from | Bayar dari |
| `topUp` | Top-up | Isi Ulang |
| `topUpFrom` | Top up from | Isi ulang dari |
| `topUpTo` | Top up to | Isi ulang ke |
| `totalBalance` | Total Balance | Total Saldo |
| `walletBalance` | Wallet Balance | Saldo Dompet |
| `noWallets` | No wallets yet | Belum ada dompet |
| `createFirstWallet` | Add a wallet to start tracking | Tambah dompet untuk mulai mencatat |
| `insufficientBalance` | Insufficient balance | Saldo tidak cukup |
| `walletBalanceNotEmpty` | Cannot delete wallet with balance | Tidak bisa hapus dompet dengan saldo |
| `sourceWallet` | From | Dari |
| `destinationWallet` | To | Ke |

---

## Providers

| Provider | Type | Description |
|---|---|---|
| `walletsProvider` | `AsyncNotifier<List<Wallet>>` | Core wallet state |
| `totalWalletBalanceProvider` | `Provider<AsyncValue<int>>` | Total semua saldo wallet |
| `walletByIdProvider` | `Provider.family` | Get wallet by ID |
| `grandTotalBalanceProvider` | `Provider<AsyncValue<int>>` | Total Income - Total Expense (non-transfer) |

### WalletsNotifier Methods

| Method | Description |
|---|---|
| `addWallet(name, type)` | Buat wallet baru, saldo awal 0 |
| `updateWallet(wallet)` | Edit nama/tipe wallet |
| `deleteWallet(id)` | Hapus wallet (error jika saldo > 0) |
| `debitFromWallet(id, amount)` | Kurangi saldo wallet |
| `refundToWallet(id, amount)` | Tambah saldo wallet (untuk refund) |
| `topUpWallet(sourceId, destId, amount)` | Transfer antar wallet |
