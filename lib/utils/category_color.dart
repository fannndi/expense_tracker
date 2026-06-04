import 'package:flutter/material.dart';

class CategoryColor {
  CategoryColor._();

  static const Map<String, Color> _colors = {
    'Food': Color(0xFF4CAF50),
    'Fuel': Color(0xFFFF9800),
    'Internet': Color(0xFF2196F3),
    'Subscription': Color(0xFF9C27B0),
    'Education': Color(0xFF3F51B5),
    'Entertainment': Color(0xFFE91E63),
    'Other': Color(0xFF607D8B),
  };

  static Color forCategory(String category) =>
      _colors[category] ?? const Color(0xFF607D8B);

  static Map<String, Color> get all => Map.unmodifiable(_colors);
}
