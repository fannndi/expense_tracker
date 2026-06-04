import 'package:flutter/services.dart';

/// TextInputFormatter yang otomatis format angka dengan titik ribuan.
/// Input: user ketik angka → tampil "15.000", "1.500.000"
/// Value yang disimpan di controller adalah angka bersih tanpa titik,
/// tapi display-nya pakai titik. Parse balik pakai [rawValue].
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Ambil angka saja dari input baru
    final rawDigits = newValue.text.replaceAll('.', '');

    if (rawDigits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Jangan proses kalau bukan angka
    if (int.tryParse(rawDigits) == null) return oldValue;

    // Format dengan titik ribuan
    final formatted = addThousandSeparator(rawDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Tambah titik setiap 3 digit dari kanan
  static String addThousandSeparator(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      // Posisi dari kanan
      final fromRight = length - 1 - i;
      buffer.write(digits[i]);
      if (fromRight > 0 && fromRight % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  /// Extract raw integer dari teks yang sudah diformat
  static int? parseFormatted(String formatted) {
    final raw = formatted.replaceAll('.', '').trim();
    return int.tryParse(raw);
  }
}
