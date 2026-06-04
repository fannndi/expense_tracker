import 'package:flutter/material.dart';

import '../utils/category_color.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
  });

  IconData _iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Internet':
        return Icons.wifi;
      case 'Subscription':
        return Icons.subscriptions;
      case 'Education':
        return Icons.school;
      case 'Entertainment':
        return Icons.movie;
      case 'Other':
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryColor.forCategory(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        _iconFor(category),
        color: color,
        size: size * 0.55,
      ),
    );
  }
}
