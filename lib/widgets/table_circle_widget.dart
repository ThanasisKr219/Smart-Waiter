import 'package:flutter/material.dart';

import '../models/pos_models.dart';
import '../theme/app_theme.dart';

class TableCircleWidget extends StatelessWidget {
  final TableModel table;
  final bool hasActiveOrder;
  final bool hasPendingTickets;
  final double currentTotal;
  final bool isMerged;
  final String? mergeLabel;
  final bool isHighlightedTarget;

  const TableCircleWidget({
    super.key,
    required this.table,
    required this.hasActiveOrder,
    required this.hasPendingTickets,
    required this.currentTotal,
    required this.isMerged,
    required this.mergeLabel,
    this.isHighlightedTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = 76.0 * table.scale;
    final bool isOccupied = hasActiveOrder && !hasPendingTickets;
    final Color stateColor = hasPendingTickets
        ? AppColors.electricCyan
        : isOccupied
        ? AppColors.amber
        : AppColors.steelGrey;
    final List<Color> surfaceColors = hasPendingTickets
        ? const [Color(0xFF1A3344), Color(0xFF102030)]
        : isOccupied
        ? const [Color(0xFF2D261E), Color(0xFF1A1918)]
        : const [Color(0xFF1E2D42), Color(0xFF142030)];

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: diameter * 0.38,
            width: diameter * 0.24,
            height: diameter * 0.12,
            child: _Chair(color: stateColor),
          ),
          Positioned(
            bottom: 0,
            left: diameter * 0.38,
            width: diameter * 0.24,
            height: diameter * 0.12,
            child: _Chair(color: stateColor),
          ),
          Positioned(
            left: 0,
            top: diameter * 0.38,
            width: diameter * 0.12,
            height: diameter * 0.24,
            child: _Chair(color: stateColor),
          ),
          Positioned(
            right: 0,
            top: diameter * 0.38,
            width: diameter * 0.12,
            height: diameter * 0.24,
            child: _Chair(color: stateColor),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.4),
                    radius: 1.15,
                    colors: surfaceColors,
                  ),
                  border: Border.all(
                    color: isHighlightedTarget ? AppColors.emerald : stateColor,
                    width: isHighlightedTarget
                        ? 5
                        : hasPendingTickets
                        ? 3
                        : isOccupied
                        ? 3
                        : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasPendingTickets
                          ? AppColors.electricCyan.withValues(alpha: 0.8)
                          : isOccupied
                          ? AppColors.amber.withValues(alpha: 0.55)
                          : AppColors.midnightNavy.withValues(alpha: 0.45),
                      blurRadius: hasPendingTickets
                          ? 16
                          : isOccupied
                          ? 12
                          : 6,
                      spreadRadius: hasPendingTickets ? 2 : 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          table.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: AppColors.frostWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12 * table.scale,
                          ),
                        ),
                        if (hasPendingTickets) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Pending',
                            maxLines: 1,
                            style: TextStyle(
                              color: AppColors.electricCyan,
                              fontWeight: FontWeight.w600,
                              fontSize: 8 * table.scale,
                            ),
                          ),
                        ] else if (isOccupied) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${currentTotal.toStringAsFixed(2)} €',
                            maxLines: 1,
                            style: TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 10 * table.scale,
                            ),
                          ),
                        ],
                        if (isMerged && mergeLabel != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepSlateNavy.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🔗 $mergeLabel',
                              maxLines: 1,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chair extends StatelessWidget {
  final Color color;

  const _Chair({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.open_with,
        color: AppColors.midnightNavy,
        size: 16,
      ),
    );
  }
}
