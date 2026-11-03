import 'package:flutter/material.dart';
import '../models/pos_models.dart';
import 'canvas_painters.dart';

class FloorPlanCanvas extends StatelessWidget {
  final double virtualCanvasWidth;
  final double virtualCanvasHeight;
  final double minBoundSize;
  final List<TableModel> currentTables;
  final Space currentSpace;
  final Map<String, TableOrder> orders;
  final TransformationController mapTransformCtrl;
  final double effectiveBaseScale;
  final bool clampToSpaceBounds;
  final bool isMapEditMode;
  final bool isSettingBoundsMode;
  final Rect tempBounds;

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

  const FloorPlanCanvas({
    super.key,
    required this.virtualCanvasWidth,
    required this.virtualCanvasHeight,
    required this.minBoundSize,
    required this.currentTables,
    required this.currentSpace,
    required this.orders,
    required this.mapTransformCtrl,
    required this.effectiveBaseScale,
    required this.clampToSpaceBounds,
    required this.isMapEditMode,
    required this.isSettingBoundsMode,
    required this.tempBounds,
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
    final double currentViewerScale = mapTransformCtrl.value.getMaxScaleOnAxis();
    final double totalScreenScale =
        (effectiveBaseScale * currentViewerScale).clamp(0.15, 5.0);

    final double handleSize = (38.0 / totalScreenScale).clamp(28.0, 140.0);
    final double halfHandle = handleSize / 2.0;

    final double tLeft = tempBounds.left;
    final double tTop = tempBounds.top;
    final double tWidth = tempBounds.width;
    final double tHeight = tempBounds.height;

    return SizedBox(
      width: virtualCanvasWidth,
      height: virtualCanvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: isMapEditMode
                  ? Colors.blue.shade50.withOpacity(0.5)
                  : Colors.white,
              child: CustomPaint(
                painter:
                    VirtualCanvasBackgroundPainter(isEditMode: isMapEditMode),
              ),
            ),
          ),
          if (!isSettingBoundsMode &&
              !clampToSpaceBounds &&
              currentSpace.hasBounds)
            Positioned(
              left: currentSpace.boundLeft!,
              top: currentSpace.boundTop!,
              width: currentSpace.boundWidth!,
              height: currentSpace.boundHeight!,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.6),
                      width: 3.0 / totalScreenScale,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          for (final table in currentTables)
            Builder(
              builder: (context) {
                final master = getMasterTable(table);
                final group = getMergedGroup(master);
                final bool isMerged = group.length > 1;
                final bool hasActiveOrder =
                    orders[master.id]?.items.isNotEmpty ?? false;
                final String? mergeLabel = isMerged
                    ? (table.id == master.id
                        ? '${group.length} Τρ.'
                        : master.name)
                    : null;

                final double tableDiameter = 76.0 * table.scale;
                final double scaledRadius =
                    (tableDiameter * totalScreenScale) / 2.0;

                final double minX =
                    (clampToSpaceBounds && currentSpace.hasBounds)
                        ? currentSpace.boundLeft! + 4.0
                        : 8.0;
                final double minY =
                    (clampToSpaceBounds && currentSpace.hasBounds)
                        ? currentSpace.boundTop! + 4.0
                        : 8.0;
                final double maxX =
                    (clampToSpaceBounds && currentSpace.hasBounds)
                        ? (currentSpace.boundLeft! +
                                currentSpace.boundWidth! -
                                tableDiameter -
                                4.0)
                            .clamp(minX, virtualCanvasWidth - tableDiameter)
                        : virtualCanvasWidth - tableDiameter;
                final double maxY =
                    (clampToSpaceBounds && currentSpace.hasBounds)
                        ? (currentSpace.boundTop! +
                                currentSpace.boundHeight! -
                                tableDiameter -
                                4.0)
                            .clamp(minY, virtualCanvasHeight - tableDiameter)
                        : virtualCanvasHeight - tableDiameter;

                return Positioned(
                  left:
                      table.left.clamp(0.0, virtualCanvasWidth - tableDiameter),
                  top: table.top
                      .clamp(0.0, virtualCanvasHeight - tableDiameter),
                  child: IgnorePointer(
                    ignoring: isSettingBoundsMode,
                    child: isMapEditMode
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onEditTable(table),
                            onPanUpdate: (details) {
                              final double newLeft =
                                  (table.left + details.delta.dx)
                                      .clamp(minX, maxX);
                              final double newTop =
                                  (table.top + details.delta.dy)
                                      .clamp(minY, maxY);

                              if (!checkCollision(
                                  table.id, newLeft, newTop, table.scale)) {
                                onTableMoved(table, newLeft, newTop);
                              }
                            },
                            onPanEnd: (_) => onTableMoveEnded(),
                            child: TableCircleWidget(
                              table: table,
                              hasActiveOrder: hasActiveOrder,
                              isMerged: isMerged,
                              mergeLabel: mergeLabel,
                            ),
                          )
                        : DragTarget<TableModel>(
                            onWillAcceptWithDetails: (details) =>
                                details.data.id != table.id,
                            onAcceptWithDetails: (details) {
                              onTransferOrMergeRequested(details.data, table);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final bool isTargetHighlighted =
                                  candidateData.isNotEmpty;
                              return LongPressDraggable<TableModel>(
                                data: table,
                                delay: const Duration(milliseconds: 350),
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                feedback: Transform.translate(
                                  offset: Offset(-scaledRadius, -scaledRadius),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Transform.scale(
                                      scale: totalScreenScale,
                                      alignment: Alignment.topLeft,
                                      child: Opacity(
                                        opacity: 0.85,
                                        child: TableCircleWidget(
                                          table: table,
                                          hasActiveOrder: hasActiveOrder,
                                          isMerged: isMerged,
                                          mergeLabel: mergeLabel,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.35,
                                  child: TableCircleWidget(
                                    table: table,
                                    hasActiveOrder: hasActiveOrder,
                                    isMerged: isMerged,
                                    mergeLabel: mergeLabel,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () => onOpenOrder(table),
                                  child: TableCircleWidget(
                                    table: table,
                                    hasActiveOrder: hasActiveOrder,
                                    isMerged: isMerged,
                                    mergeLabel: mergeLabel,
                                    isHighlightedTarget: isTargetHighlighted,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          if (isSettingBoundsMode) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CropMaskPainter(cropRect: tempBounds),
                ),
              ),
            ),
            Positioned(
              left: tLeft,
              top: tTop,
              width: tWidth,
              height: tHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final newL = (tLeft + details.delta.dx)
                      .clamp(0.0, virtualCanvasWidth - tWidth);
                  final newT = (tTop + details.delta.dy)
                      .clamp(0.0, virtualCanvasHeight - tHeight);
                  onTempBoundsChanged(
                      Rect.fromLTWH(newL, newT, tWidth, tHeight));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: (3.0 / totalScreenScale).clamp(2.0, 10.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Παράθυρο Χώρου: ${tWidth.round()} x ${tHeight.round()}\n(Σύρετε εδώ για μετακίνηση ή τις γωνίες για μέγεθος)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: (12.0 / totalScreenScale).clamp(11.0, 32.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ΓΩΝΙΑ 1: ΠΑΝΩ ΑΡΙΣΤΕΡΑ
            Positioned(
              left: tLeft - halfHandle,
              top: tTop - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final double right = tLeft + tWidth;
                  final double bottom = tTop + tHeight;
                  final double newL = (tLeft + details.delta.dx)
                      .clamp(0.0, right - minBoundSize);
                  final double newT = (tTop + details.delta.dy)
                      .clamp(0.0, bottom - minBoundSize);
                  onTempBoundsChanged(
                      Rect.fromLTRB(newL, newT, right, bottom));
                },
                child: const CropHandleWidget(),
              ),
            ),
            // ΓΩΝΙΑ 2: ΠΑΝΩ ΔΕΞΙΑ
            Positioned(
              left: tLeft + tWidth - halfHandle,
              top: tTop - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final double bottom = tTop + tHeight;
                  final double newW = (tWidth + details.delta.dx)
                      .clamp(minBoundSize, virtualCanvasWidth - tLeft);
                  final double newT = (tTop + details.delta.dy)
                      .clamp(0.0, bottom - minBoundSize);
                  onTempBoundsChanged(
                      Rect.fromLTWH(tLeft, newT, newW, bottom - newT));
                },
                child: const CropHandleWidget(),
              ),
            ),
            // ΓΩΝΙΑ 3: ΚΑΤΩ ΑΡΙΣΤΕΡΑ
            Positioned(
              left: tLeft - halfHandle,
              top: tTop + tHeight - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final double right = tLeft + tWidth;
                  final double newL = (tLeft + details.delta.dx)
                      .clamp(0.0, right - minBoundSize);
                  final double newH = (tHeight + details.delta.dy)
                      .clamp(minBoundSize, virtualCanvasHeight - tTop);
                  onTempBoundsChanged(
                      Rect.fromLTWH(newL, tTop, right - newL, newH));
                },
                child: const CropHandleWidget(),
              ),
            ),
            // ΓΩΝΙΑ 4: ΚΑΤΩ ΔΕΞΙΑ
            Positioned(
              left: tLeft + tWidth - halfHandle,
              top: tTop + tHeight - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final double newW = (tWidth + details.delta.dx)
                      .clamp(minBoundSize, virtualCanvasWidth - tLeft);
                  final double newH = (tHeight + details.delta.dy)
                      .clamp(minBoundSize, virtualCanvasHeight - tTop);
                  onTempBoundsChanged(
                      Rect.fromLTWH(tLeft, tTop, newW, newH));
                },
                child: const CropHandleWidget(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}