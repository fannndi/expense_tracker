enum WalletType { cash, eMoney, debitCredit }

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final int balance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0,
  });

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    int? balance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletType.cash,
      ),
      balance: json['balance'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Wallet(id: $id, name: $name, type: ${type.name}, balance: $balance)';

  String get typeDisplayName {
    switch (type) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.eMoney:
        return 'E-Money';
      case WalletType.debitCredit:
        return 'Debit/Credit';
    }
  }
}
