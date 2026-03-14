class BudgetGoal {
  final String id;
  final String userId;
  final String name;
  final String categoryId;
  final double currentAmount;
  final double targetAmount;
  final int iconCode;
  final int month; // 1-12
  final int year;

  BudgetGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.categoryId,
    required this.currentAmount,
    required this.targetAmount,
    required this.iconCode,
    required this.month,
    required this.year,
  });

  factory BudgetGoal.fromMap(String id, Map<String, dynamic> map) {
    return BudgetGoal(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      currentAmount: (map['currentAmount'] ?? 0.0).toDouble(),
      targetAmount: (map['targetAmount'] ?? 0.0).toDouble(),
      iconCode: map['iconCode'] ?? 0xe1d7,
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'categoryId': categoryId,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'iconCode': iconCode,
      'month': month,
      'year': year,
    };
  }

  BudgetGoal copyWith({
    String? id,
    String? userId,
    String? name,
    String? categoryId,
    double? currentAmount,
    double? targetAmount,
    int? iconCode,
    int? month,
    int? year,
  }) {
    return BudgetGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      iconCode: iconCode ?? this.iconCode,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}
