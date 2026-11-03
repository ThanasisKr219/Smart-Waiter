import 'package:flutter/material.dart';
import '../models/pos_models.dart';

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
      borderColor = Colors.greenAccent.shade700;
      borderWidth = 5.0;
    } else if (hasActiveOrder && isMerged) {
      borderColor = Colors.amber;
      borderWidth = 4.5;
    } else if (hasActiveOrder) {
      borderColor = Colors.amber;
      borderWidth = 4.0;
    } else if (isMerged) {
      borderColor = Colors.cyanAccent.shade700;
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
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12 * table.scale,
            ),
          ),
          if (isMerged && mergeLabel != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.cyan.shade900.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🔗 $mergeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.cyanAccent,
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
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: const Icon(Icons.open_with, color: Colors.white, size: 16),
    );
  }
}