import 'package:flutter/material.dart';
import '../models/pos_models.dart';
import '../theme/app_theme.dart';

class TableCircleWidget extends StatelessWidget {
  final TableModel table;
  final bool hasActiveOrder;
  final bool isMerged;
  final String? mergeLabel;
  final bool isHighlightedTarget;

  const TableCircleWidget({
    super.key,
    required this.table,
    required this.hasActiveOrder,
    required this.isMerged,
    required this.mergeLabel,
    this.isHighlightedTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = 76.0 * table.scale;

    Color? borderColor;
    double borderWidth = 0.0;
    if (isHighlightedTarget) {
      borderColor = AppColors.emerald;
      borderWidth = 5.0;
    } else if (hasActiveOrder && isMerged) {
      borderColor = AppColors.amber;
      borderWidth = 4.5;
    } else if (hasActiveOrder) {
      borderColor = AppColors.amber;
      borderWidth = 4.0;
    } else if (isMerged) {
      borderColor = AppColors.electricCyan;
      borderWidth = 4.0;
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Color(table.colorValue),
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
              color: AppColors.midnightNavy.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: Offset(0, 3))
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.frostWhite,
              fontWeight: FontWeight.bold,
              fontSize: 12 * table.scale,
            ),
          ),
          if (isMerged && mergeLabel != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.deepSlateNavy.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔗 $mergeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.electricCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 9.5 * table.scale,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CropHandleWidget extends StatelessWidget {
  const CropHandleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.electricCyan,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.frostWhite, width: 3),
        boxShadow: [
          BoxShadow(
              color: AppColors.midnightNavy.withValues(alpha: 0.55),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: const Icon(Icons.open_with, color: AppColors.midnightNavy, size: 16),
    );
  }
}