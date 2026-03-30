import 'package:flutter/material.dart';
import '../models/Category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final String subtitle;
  final double amount;
  final String? budgetStatus;
  final String? trailingSubtitle;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.subtitle,
    required this.amount,
    this.budgetStatus,
    this.trailingSubtitle,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate color based on budget status if it's an expense
    Color amountColor = category.type == CategoryType.income ? const Color(0xFF10B981) : const Color(0xFF1F2937);
    String prefix = category.type == CategoryType.income ? '+' : '-';
    IconData typeIcon = category.type == CategoryType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    Color typeColor = category.type == CategoryType.income ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    
    // Determine the secondary status text
    String? displayStatus = budgetStatus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1644FF).withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF1644FF) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    activeColor: const Color(0xFF1644FF),
                  ),
                  const SizedBox(width: 8),
                ],
                // Icon container matching the premium design
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name and Date/Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Trailing side: Amount and actions
                Flexible(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$prefix ${amount.toStringAsFixed(2)} DT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(typeIcon, color: typeColor, size: 14),
                        ],
                      ),
                      
                      // Action Buttons moved here to save horizontal space
                      if (isSelectionMode && isSelected) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1644FF), size: 18),
                                onPressed: onEdit,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            const SizedBox(width: 12),
                            if (onDelete != null)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                onPressed: onDelete,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ] else if (displayStatus != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          displayStatus,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
