import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/floor_plan_canvas.dart';
import '../../theme/app_theme.dart';

class FloorPlanTab extends StatelessWidget {
  final double virtualCanvasWidth;
  final double virtualCanvasHeight;
  final double minBoundSize;
  final List<Space> spaces;
  final Space? activeSpace;
  final List<TableModel> currentTables;
  final Map<String, TableOrder> orders;
  final List<OrderTicket> pendingTickets;
  final TransformationController mapTransformCtrl;
  final bool isMapEditMode;
  final bool isSettingBoundsMode;
  final bool isBoundsLocked;
  final Rect tempBounds;

  final void Function(Space) onSelectSpace;
  final VoidCallback onAutoBoundsRequested;
  final VoidCallback onClearBoundsRequested;
  final VoidCallback onSaveBoundsRequested;
  final void Function(Size) onViewportSizeReported;
  final VoidCallback onViewerInteractionUpdate;

  final TableModel Function(TableModel) getMasterTable;
  final List<TableModel> Function(TableModel) getMergedGroup;
  final bool Function(String tableId, double left, double top, double scale)
  checkCollision;
  final void Function(TableModel table, double newLeft, double newTop)
  onTableMoved;
  final VoidCallback onTableMoveEnded;
  final void Function(TableModel) onEditTable;
  final void Function(TableModel) onOpenOrder;
  final void Function(TableModel source, TableModel target)
  onTransferOrMergeRequested;
  final void Function(Rect newTempBounds) onTempBoundsChanged;

  const FloorPlanTab({
    super.key,
    required this.virtualCanvasWidth,
    required this.virtualCanvasHeight,
    required this.minBoundSize,
    required this.spaces,
    required this.activeSpace,
    required this.currentTables,
    required this.orders,
    required this.pendingTickets,
    required this.mapTransformCtrl,
    required this.isMapEditMode,
    required this.isSettingBoundsMode,
    required this.isBoundsLocked,
    required this.tempBounds,
    required this.onSelectSpace,
    required this.onAutoBoundsRequested,
    required this.onClearBoundsRequested,
    required this.onSaveBoundsRequested,
    required this.onViewportSizeReported,
    required this.onViewerInteractionUpdate,
    required this.getMasterTable,
    required this.getMergedGroup,
    required this.checkCollision,
    required this.onTableMoved,
    required this.onTableMoveEnded,
    required this.onEditTable,
    required this.onOpenOrder,
    required this.onTransferOrMergeRequested,
    required this.onTempBoundsChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (spaces.isEmpty || activeSpace == null) {
      return const EmptyStateWidget(
        icon: Icons.restaurant,
        message: 'No spaces available (go to "Map Setup")',
      );
    }

    final Space currentSpace = activeSpace!;
    final bool useLockedBounds =
        currentSpace.hasBounds && isBoundsLocked && !isSettingBoundsMode;

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: spaces.length,
            itemBuilder: (context, i) {
              final sp = spaces[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  avatar: sp.hasBounds
                      ? const Icon(
                          Icons.crop_free,
                          size: 14,
                          color: AppColors.electricCyan,
                        )
                      : null,
                  label: Text(sp.name),
                  selected: sp.id == currentSpace.id,
                  onSelected: (v) {
                    if (v) onSelectSpace(sp);
                  },
                ),
              );
            },
          ),
        ),
        if (isSettingBoundsMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: AppColors.deepSlateNavy,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text(
                    'Auto-fit Tables',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: onAutoBoundsRequested,
                ),
                if (currentSpace.hasBounds)
                  TextButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.coralRed,
                    ),
                    label: const Text(
                      'Clear Bounds',
                      style: TextStyle(fontSize: 12, color: AppColors.coralRed),
                    ),
                    onPressed: onClearBoundsRequested,
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    foregroundColor: AppColors.midnightNavy,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Save & Lock',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: onSaveBoundsRequested,
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: isMapEditMode
                ? AppColors.deepSlateNavy
                : (useLockedBounds
                      ? AppColors.deepSlateNavy
                      : AppColors.midnightNavy),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMapEditMode
                      ? Icons.open_with
                      : (useLockedBounds
                            ? Icons.lock_outline
                            : Icons.touch_app),
                  size: 15,
                  color: isMapEditMode
                      ? AppColors.amber
                      : (useLockedBounds
                            ? AppColors.electricCyan
                            : AppColors.steelGrey),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMapEditMode
                        ? 'Edit Mode: Drag tables | Tap to edit'
                        : (useLockedBounds
                              ? 'Locked Bounds (${currentSpace.name}): Zoom and pan within bounds • Drag a table to transfer/merge'
                              : 'Free Floor Plan: Tap the Crop icon above to set bounds'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.frostWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.midnightNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: useLockedBounds
                    ? AppColors.electricCyan
                    : AppColors.steelGrey,
                width: useLockedBounds ? 2.0 : 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  onViewportSizeReported(
                    Size(constraints.maxWidth, constraints.maxHeight),
                  );

                  if (useLockedBounds) {
                    final double bx = currentSpace.boundLeft!;
                    final double by = currentSpace.boundTop!;
                    final double bw = currentSpace.boundWidth!;
                    final double bh = currentSpace.boundHeight!;

                    final double fitScale = min(
                      constraints.maxWidth / bw,
                      constraints.maxHeight / bh,
                    );
                    final double fittedW = bw * fitScale;
                    final double fittedH = bh * fitScale;

                    return Center(
                      child: SizedBox(
                        width: fittedW,
                        height: fittedH,
                        child: InteractiveViewer(
                          key: ValueKey(
                            'locked_${currentSpace.id}_${bw.round()}_${bh.round()}',
                          ),
                          transformationController: mapTransformCtrl,
                          constrained: true,
                          boundaryMargin: EdgeInsets.zero,
                          minScale: 1.0,
                          maxScale: 4.0,
                          panEnabled: !isMapEditMode,
                          scaleEnabled: true,
                          onInteractionUpdate: (_) =>
                              onViewerInteractionUpdate(),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: bw,
                              height: bh,
                              child: ClipRect(
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Positioned(
                                      left: -bx,
                                      top: -by,
                                      width: virtualCanvasWidth,
                                      height: virtualCanvasHeight,
                                      child: FloorPlanCanvas(
                                        virtualCanvasWidth: virtualCanvasWidth,
                                        virtualCanvasHeight:
                                            virtualCanvasHeight,
                                        minBoundSize: minBoundSize,
                                        currentTables: currentTables,
                                        currentSpace: currentSpace,
                                        orders: orders,
                                        pendingTickets: pendingTickets,
                                        mapTransformCtrl: mapTransformCtrl,
                                        effectiveBaseScale: fitScale,
                                        clampToSpaceBounds: true,
                                        isMapEditMode: isMapEditMode,
                                        isSettingBoundsMode:
                                            isSettingBoundsMode,
                                        tempBounds: tempBounds,
                                        getMasterTable: getMasterTable,
                                        getMergedGroup: getMergedGroup,
                                        checkCollision: checkCollision,
                                        onTableMoved: onTableMoved,
                                        onTableMoveEnded: onTableMoveEnded,
                                        onEditTable: onEditTable,
                                        onOpenOrder: onOpenOrder,
                                        onTransferOrMergeRequested:
                                            onTransferOrMergeRequested,
                                        onTempBoundsChanged:
                                            onTempBoundsChanged,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      InteractiveViewer(
                        key: ValueKey('free_${currentSpace.id}'),
                        transformationController: mapTransformCtrl,
                        constrained: false,
                        minScale: 0.2,
                        maxScale: 2.5,
                        boundaryMargin: const EdgeInsets.all(250),
                        panEnabled: !isMapEditMode,
                        scaleEnabled: true,
                        onInteractionUpdate: (_) => onViewerInteractionUpdate(),
                        child: FloorPlanCanvas(
                          virtualCanvasWidth: virtualCanvasWidth,
                          virtualCanvasHeight: virtualCanvasHeight,
                          minBoundSize: minBoundSize,
                          currentTables: currentTables,
                          currentSpace: currentSpace,
                          orders: orders,
                          pendingTickets: pendingTickets,
                          mapTransformCtrl: mapTransformCtrl,
                          effectiveBaseScale: 1.0,
                          clampToSpaceBounds: false,
                          isMapEditMode: isMapEditMode,
                          isSettingBoundsMode: isSettingBoundsMode,
                          tempBounds: tempBounds,
                          getMasterTable: getMasterTable,
                          getMergedGroup: getMergedGroup,
                          checkCollision: checkCollision,
                          onTableMoved: onTableMoved,
                          onTableMoveEnded: onTableMoveEnded,
                          onEditTable: onEditTable,
                          onOpenOrder: onOpenOrder,
                          onTransferOrMergeRequested:
                              onTransferOrMergeRequested,
                          onTempBoundsChanged: onTempBoundsChanged,
                        ),
                      ),
                      if (currentTables.isEmpty && !isSettingBoundsMode)
                        const IgnorePointer(
                          child: EmptyStateWidget(
                            icon: Icons.table_bar,
                            message: 'No tables in this space',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
