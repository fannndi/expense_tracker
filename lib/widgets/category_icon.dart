import 'package:flutter/material.dart';

import '../utils/category_color.dart';

/// Widget icon bulat per kategori.
/// [category] adalah ALWAYS the English storage key (Food, Fuel, etc.)
/// karena itu yang disimpan di JSON.
class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
  });

  static IconData iconFor(String categoryKey) {
    switch (categoryKey) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Internet':
        return Icons.wifi_rounded;
      case 'Subscription':
        return Icons.subscriptions_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Other':
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryColor.forCategory(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        iconFor(category),
        color: color,
        size: size * 0.55,
      ),
    );
  }
}
