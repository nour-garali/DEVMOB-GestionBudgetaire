import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class Category {
  final String id;
  final String userId;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;
// Monthly budget goal (Moved to BudgetGoal)

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      icon: IconData(map['iconCode'] ?? Icons.help.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] ?? Colors.grey.value),
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'type': type == CategoryType.income ? 'income' : 'expense',
    };
  }
}
