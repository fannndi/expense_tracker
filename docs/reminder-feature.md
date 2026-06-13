# Reminder Feature — Pengingat Pembayaran Berulang

## Overview

Fitur Reminder memungkinkan kamu membuat **template pengeluaran berulang** yang akan mengingatkan kamu via notifikasi ketika jatuh tempo.

**Use case:**
- Paket data internet 28 hari
- Asuransi kesehatan tiap tanggal 27
- Subscription AI setiap 30 hari
- Makan siang harian

Reminder bersifat **independen** — tidak terikat ke expense tertentu. Kamu bisa membuat reminder dari form tambah expense (pre-filled) atau sebagai reminder standalone.

---

## Konsep Penting

### Reminder vs Expense
- **Reminder** = template pengeluaran berulang (data master)
- **Expense** = hasil rekaman pembayaran (bisa dilink via `reminderId`)
- Menghapus expense tidak menghapus reminder
- Mengedit reminder tidak mengubah expense historis

### Status Pembayaran
Di home screen, reminder yang jatuh tempo hari ini punya 2 status:

| Status | Tampilan | Kondisi |
|--------|----------|---------|
| **Bayar** | Tombol "Pay" | Belum ada expense hari ini dengan `reminderId` ini |
| **Sudah dibayar** | Badge "Paid" 🟢 | Ada expense hari ini dengan `reminderId` ini |

### Recurrence Options

| Tipe | Contoh Penggunaan | Kalkulasi Next Due |
|------|-------------------|-------------------|
| **Daily** | Jajan harian | Today + 1 day |
| **Weekly** | Laundry mingguan | Today + 7 days |
| **Monthly** | Asuransi tgl 27 | Next month on day X (auto-handles Feb 30 → Feb 28) |
| **Custom** | Paket data 28 hari | Today + N days |

---

## Data Model

### Reminder

```
Reminder {
  id: String                  // "rem_<uuid>"
  title: String               // "Paket Data", "Asuransi"
  category: String            // "Internet", "Other", dll
  amount: int                 // nominal IDR
  note: String?               // catatan opsional
  walletId: String?           // wallet default untuk pembayaran
  recurrence: ReminderRecurrence  // daily | weekly | monthlyByDate | customDays
  dayOfMonth: int?            // 1-31, untuk monthlyByDate
  customIntervalDays: int?    // untuk customDays (e.g. 28)
  nextDueDate: DateTime       // kapan jatuh tempo berikutnya
  isActive: bool              // true = aktif (notifikasi jalan)
  createdAt: DateTime         // waktu dibuat
  notificationId: int         // ID notifikasi (stabil antar restart)
}
```

### Expense (updated)

```
Expense {
  ...
  reminderId: String?         // NEW — link ke reminder yang melahirkan expense ini
}
```

### ReminderData (DTO)

```
ReminderData {
  recurrence: ReminderRecurrence
  dayOfMonth: int?
  customIntervalDays: int?
}
```

Digunakan untuk passing data dari `ExpenseForm` ke screen callback.

---

## Storage

Disimpan di `app_data.json` di key `"reminders"`:

```json
{
  "version": 2,
  "expenses": [...],
  "incomes": [...],
  "wallets": [...],
  "reminders": [
    {
      "id": "rem_xxx",
      "title": "Paket Data",
      "category": "Internet",
      "amount": 50000,
      "note": "Telkomsel 28GB",
      "walletId": "wal_yyy",
      "recurrence": "customDays",
      "customIntervalDays": 28,
      "nextDueDate": "2026-07-11T00:00:00Z",
      "isActive": true,
      "createdAt": "2026-06-13T12:00:00Z",
      "notificationId": 104567
    }
  ]
}
```

---

## Notification System

### Channel
- **ID:** `reminder_channel`
- **Name:** "Payment Reminders"
- **Waktu:** 12:00 siang setiap hari

### Scheduling
| Event | Aksi |
|-------|------|
| Reminder dibuat | `scheduleReminder(reminder)` — jadwal notifikasi di `nextDueDate` jam 12:00 |
| Pembayaran dicatat | `rescheduleReminder(reminder)` — cancel notifikasi lama, jadwal baru untuk `nextDueDate` berikutnya |
| Reminder dinonaktifkan | `cancelReminder(notificationId)` |
| Reminder dihapus | `cancelReminder(notificationId)` |

### Notification ID
Setiap reminder punya notification ID unik yang **stabil antar restart** (dihitung dari hash string ID reminder):
```
notificationId = 10000 + (hash(id) % 900000)
```

---

## UI Flow

### 1. Membuat Reminder dari Expense
1. Buka form **Tambah Pengeluaran** (FAB → +)
2. Isi jumlah, kategori, wallet, dll seperti biasa
3. Di bagian bawah, aktifkan toggle **"Atur Pengingat"**
4. Pilih tipe perulangan: Harian / Mingguan / Bulanan / Kustom
5. Jika Bulanan: pilih tanggal (1-31)
6. Jika Kustom: masukkan jumlah hari (e.g. 28)
7. Ketuk **Simpan**
8. Expense tercatat + Reminder tersimpan + Notifikasi terjadwal

### 2. Membuat Reminder Standalone
1. Buka **Settings** → **Reminders**
2. Ketuk tombol **+** (FAB)
3. Isi judul, kategori, jumlah, note, wallet (opsional)
4. Pilih tipe perulangan
5. Ketuk **Simpan**

### 3. Membayar dari Reminder (Home Screen)
1. Di **Home Screen**, lihat section **"Pengingat Hari Ini"**
2. Reminder yang jatuh tempo tampil dengan tombol **Bayar**
3. Ketuk **Bayar**
4. Expense otomatis tercatat (dengan data reminder + tanggal hari ini)
5. Wallet otomatis didebit (jika wallet diset di reminder)
6. Notifikasi dijadwalkan ulang untuk periode berikutnya

### 4. Melihat & Mengelola Reminder
1. Buka **Settings** → **Reminders**
2. Daftar semua reminder (aktif & non-aktif), diurutkan: aktif dulu, lalu berdasarkan nextDueDate
3. Tap reminder → edit
4. Popup menu → Disable/Enable atau Delete
5. Delete → konfirmasi dulu → notifikasi dicancel

---

## File Structure

### New Files

| File | Purpose |
|------|---------|
| `lib/models/reminder.dart` | Reminder model + ReminderRecurrence enum + ReminderData DTO |
| `lib/repositories/reminder_repository.dart` | Abstract + LocalReminderRepository |
| `lib/providers/reminder_providers.dart` | RemindersNotifier + dueRemindersProvider + reminderNotificationServiceProvider |
| `lib/services/reminder_notification_service.dart` | Channel, schedule, cancel, reschedule, permission |
| `lib/widgets/today_reminders.dart` | TodayRemindersSection widget for home screen |
| `lib/screens/reminders/reminder_list_screen.dart` | List all reminders with toggle/delete/edit |
| `lib/screens/reminders/add_reminder_screen.dart` | Add/edit reminder form |
| `docs/reminder-feature.md` | This documentation |

### Updated Files

| File | Changes |
|------|---------|
| `lib/models/expense.dart` | +`reminderId` field + copyWith/fromJson/toJson |
| `lib/utils/constants.dart` | Bump `dataVersion` 1 → 2 |
| `lib/services/storage_service.dart` | +`loadReminders()` + `saveReminders()` |
| `lib/services/wallet_transaction_service.dart` | +`reminderId` param on `addExpenseWithWalletDebit` |
| `lib/providers/expense_providers.dart` | +`reminderId` param on `addExpense` |
| `lib/screens/expense_form/widgets/expense_form.dart` | +Reminder section UI, +`ReminderData?` on callback |
| `lib/screens/expense_form/add_expense_screen.dart` | Creates reminder + schedules notification |
| `lib/screens/expense_form/edit_expense_screen.dart` | Info banner for reminder-linked expenses |
| `lib/screens/home/home_screen.dart` | +`TodayRemindersSection` |
| `lib/screens/settings/settings_screen.dart` | +"Reminders" menu entry |
| `lib/routes/app_router.dart` | +`/reminders`, +`/add-reminder` |
| `lib/l10n/app_strings.dart` | +20 string keys (EN + ID) |
| `lib/main.dart` | Init `ReminderNotificationService` + permission |

---

## Providers

| Provider | Type | Description |
|----------|------|-------------|
| `remindersProvider` | `AsyncNotifier<List<Reminder>>` | Core reminder state |
| `dueRemindersProvider` | `Provider<AsyncValue<List<Reminder>>>` | Filtered: `isActive && nextDueDate <= today`, sorted by date asc |
| `reminderNotificationServiceProvider` | `Provider<ReminderNotificationService>` | Notification scheduling service |
| `reminderRepositoryProvider` | `Provider<ReminderRepository>` | Data access |

### RemindersNotifier Methods

| Method | Description |
|--------|-------------|
| `addReminder(title, category, amount, ...)` | Create reminder + persist + reload |
| `updateReminder(reminder)` | Save changes + reload |
| `deleteReminder(id)` | Remove from storage + reload |
| `toggleActive(reminder)` | Toggle `isActive` flag + reload |
| `findById(id)` | Lookup from current state |

---

## Business Rules

| Rule | Detail |
|------|--------|
| Reminder independen | Tidak terikat ke expense — bisa diedit/dihapus tanpa pengaruh historis |
| Tidak ada duplikasi | "Paid today" dideteksi lewat `reminderId` + date matching |
| Wallet opsional | Reminder bisa tanpa wallet — Pay akan buat expense tanpa wallet debit |
| Notifikasi 12:00 | Selalu jam 12 siang, tidak peduli kapan reminder dibuat |
| Monthly overflow | Tanggal 31 → bulan dengan 30 hari pake hari terakhir (30). Februari pake 28/29. |
| Custom min 1 hari | Custom interval minimal 1 hari |
| Non-aktif = no notif | Toggle OFF → cancel notifikasi, tidak muncul di Today's Reminders |

---

## Localization

20 string baru EN + ID:

| Key | EN | ID |
|-----|----|----|
| `reminders` | Reminders | Pengingat |
| `addReminder` | Add Reminder | Tambah Pengingat |
| `editReminder` | Edit Reminder | Edit Pengingat |
| `deleteReminder` | Delete Reminder | Hapus Pengingat |
| `deleteReminderConfirm` | Delete this reminder? | Hapus pengingat ini? |
| `noReminders` | No reminders yet | Belum ada pengingat |
| `setReminder` | Set Reminder | Atur Pengingat |
| `reminderRecurrence` | Repeat | Ulangi |
| `daily` | Daily | Harian |
| `weekly` | Weekly | Mingguan |
| `monthly` | Monthly | Bulanan |
| `customDays` | Custom | Kustom |
| `everyNDays` | Every N days | Setiap N hari |
| `dayOfMonth` | Day of month | Tanggal |
| `pay` | Pay | Bayar |
| `paidToday` | Paid today | Sudah dibayar |
| `remindersToday` | Today's Reminders | Pengingat Hari Ini |
| `recordPayment` | Record Payment | Catat Pembayaran |
| `reminderTitle` | Title | Judul |
