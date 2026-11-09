import 'package:flutter/material.dart';

import '../models/pos_models.dart';
import 'canvas_painters.dart';

class FloorPlanCanvas extends StatefulWidget {
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
  State<FloorPlanCanvas> createState() => _FloorPlanCanvasState();
}

class _FloorPlanCanvasState extends State<FloorPlanCanvas> {
  final GlobalKey _canvasKey = GlobalKey();
  Offset? _dragStartCanvasPos;
  Offset? _dragStartTablePosition;
  Rect? _dragStartBounds;

  Offset _globalToCanvas(Offset globalPosition) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.globalToLocal(globalPosition);
    }

    final scale = widget.mapTransformCtrl.value.getMaxScaleOnAxis();
    return Offset(globalPosition.dx / scale, globalPosition.dy / scale);
  }

  void _startTableDrag(TableModel table, DragStartDetails details) {
    _dragStartCanvasPos = _globalToCanvas(details.globalPosition);
    _dragStartTablePosition = Offset(table.left, table.top);
  }

  void _startBoundsDrag(DragStartDetails details) {
    _dragStartCanvasPos = _globalToCanvas(details.globalPosition);
    _dragStartBounds = widget.tempBounds;
  }

  Offset _canvasDragDelta(Offset globalPosition) {
    return _globalToCanvas(globalPosition) - _dragStartCanvasPos!;
  }

  void _clearDragState() {
    _dragStartCanvasPos = null;
    _dragStartTablePosition = null;
    _dragStartBounds = null;
  }

  @override
  Widget build(BuildContext context) {
    final virtualCanvasWidth = widget.virtualCanvasWidth;
    final virtualCanvasHeight = widget.virtualCanvasHeight;
    final minBoundSize = widget.minBoundSize;
    final currentTables = widget.currentTables;
    final currentSpace = widget.currentSpace;
    final orders = widget.orders;
    final mapTransformCtrl = widget.mapTransformCtrl;
    final effectiveBaseScale = widget.effectiveBaseScale;
    final clampToSpaceBounds = widget.clampToSpaceBounds;
    final isMapEditMode = widget.isMapEditMode;
    final isSettingBoundsMode = widget.isSettingBoundsMode;
    final tempBounds = widget.tempBounds;
    final getMasterTable = widget.getMasterTable;
    final getMergedGroup = widget.getMergedGroup;
    final checkCollision = widget.checkCollision;
    final onTableMoved = widget.onTableMoved;
    final onTableMoveEnded = widget.onTableMoveEnded;
    final onEditTable = widget.onEditTable;
    final onOpenOrder = widget.onOpenOrder;
    final onTransferOrMergeRequested = widget.onTransferOrMergeRequested;
    final onTempBoundsChanged = widget.onTempBoundsChanged;

    final double currentViewerScale = mapTransformCtrl.value
        .getMaxScaleOnAxis();
    final double totalScreenScale = (effectiveBaseScale * currentViewerScale)
        .clamp(0.15, 5.0);

    final double handleSize = (38.0 / totalScreenScale).clamp(28.0, 140.0);
    final double halfHandle = handleSize / 2.0;

    final double tLeft = tempBounds.left;
    final double tTop = tempBounds.top;
    final double tWidth = tempBounds.width;
    final double tHeight = tempBounds.height;

    return SizedBox(
      key: _canvasKey,
      width: virtualCanvasWidth,
      height: virtualCanvasHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: isMapEditMode
                  ? Colors.blue.shade50.withValues(alpha: 0.5)
                  : Colors.white,
              child: CustomPaint(
                painter: VirtualCanvasBackgroundPainter(
                  isEditMode: isMapEditMode,
                ),
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
                      color: Colors.teal.withValues(alpha: 0.6),
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
                          ? '${group.length} Tbl.'
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
                  left: table.left.clamp(
                    0.0,
                    virtualCanvasWidth - tableDiameter,
                  ),
                  top: table.top.clamp(
                    0.0,
                    virtualCanvasHeight - tableDiameter,
                  ),
                  child: IgnorePointer(
                    ignoring: isSettingBoundsMode,
                    child: isMapEditMode
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onEditTable(table),
                            onPanStart: (details) =>
                                _startTableDrag(table, details),
                            onPanUpdate: (details) {
                              final startPosition = _dragStartTablePosition;
                              final startCanvasPosition = _dragStartCanvasPos;
                              if (startPosition == null ||
                                  startCanvasPosition == null) {
                                return;
                              }

                              final canvasDelta =
                                  _globalToCanvas(details.globalPosition) -
                                  startCanvasPosition;
                              final double newLeft =
                                  (startPosition.dx + canvasDelta.dx).clamp(
                                    minX,
                                    maxX,
                                  );
                              final double newTop =
                                  (startPosition.dy + canvasDelta.dy).clamp(
                                    minY,
                                    maxY,
                                  );

                              if (!checkCollision(
                                table.id,
                                newLeft,
                                newTop,
                                table.scale,
                              )) {
                                onTableMoved(table, newLeft, newTop);
                              }
                            },
                            onPanEnd: (_) {
                              onTableMoveEnded();
                              _clearDragState();
                            },
                            onPanCancel: () {
                              onTableMoveEnded();
                              _clearDragState();
                            },
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
                onPanStart: _startBoundsDrag,
                onPanUpdate: (details) {
                  final startBounds = _dragStartBounds;
                  if (startBounds == null) return;
                  final canvasDelta = _canvasDragDelta(details.globalPosition);
                  final newL = (startBounds.left + canvasDelta.dx).clamp(
                    0.0,
                    virtualCanvasWidth - tWidth,
                  );
                  final newT = (startBounds.top + canvasDelta.dy).clamp(
                    0.0,
                    virtualCanvasHeight - tHeight,
                  );
                  onTempBoundsChanged(
                    Rect.fromLTWH(newL, newT, tWidth, tHeight),
                  );
                },
                onPanEnd: (_) => _clearDragState(),
                onPanCancel: _clearDragState,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: (3.0 / totalScreenScale).clamp(2.0, 10.0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Space window: ${tWidth.round()} x ${tHeight.round()}\n(Drag here to move or use the corners to resize)',
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
            // CORNER 1: TOP LEFT
            Positioned(
              left: tLeft - halfHandle,
              top: tTop - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _startBoundsDrag,
                onPanUpdate: (details) {
                  final startBounds = _dragStartBounds;
                  if (startBounds == null) return;
                  final canvasDelta = _canvasDragDelta(details.globalPosition);
                  final double right = startBounds.right;
                  final double bottom = startBounds.bottom;
                  final double newL = (startBounds.left + canvasDelta.dx).clamp(
                    0.0,
                    right - minBoundSize,
                  );
                  final double newT = (startBounds.top + canvasDelta.dy).clamp(
                    0.0,
                    bottom - minBoundSize,
                  );
                  onTempBoundsChanged(Rect.fromLTRB(newL, newT, right, bottom));
                },
                onPanEnd: (_) => _clearDragState(),
                onPanCancel: _clearDragState,
                child: const CropHandleWidget(),
              ),
            ),
            // CORNER 2: TOP RIGHT
            Positioned(
              left: tLeft + tWidth - halfHandle,
              top: tTop - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _startBoundsDrag,
                onPanUpdate: (details) {
                  final startBounds = _dragStartBounds;
                  if (startBounds == null) return;
                  final canvasDelta = _canvasDragDelta(details.globalPosition);
                  final double newW = (startBounds.width + canvasDelta.dx)
                      .clamp(
                        minBoundSize,
                        virtualCanvasWidth - startBounds.left,
                      );
                  final double newT = (startBounds.top + canvasDelta.dy).clamp(
                    0.0,
                    startBounds.bottom - minBoundSize,
                  );
                  final double bottom = startBounds.bottom;
                  onTempBoundsChanged(
                    Rect.fromLTWH(startBounds.left, newT, newW, bottom - newT),
                  );
                },
                onPanEnd: (_) => _clearDragState(),
                onPanCancel: _clearDragState,
                child: const CropHandleWidget(),
              ),
            ),
            // CORNER 3: BOTTOM LEFT
            Positioned(
              left: tLeft - halfHandle,
              top: tTop + tHeight - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _startBoundsDrag,
                onPanUpdate: (details) {
                  final startBounds = _dragStartBounds;
                  if (startBounds == null) return;
                  final canvasDelta = _canvasDragDelta(details.globalPosition);
                  final double newL = (startBounds.left + canvasDelta.dx).clamp(
                    0.0,
                    startBounds.right - minBoundSize,
                  );
                  final double newH = (startBounds.height + canvasDelta.dy)
                      .clamp(
                        minBoundSize,
                        virtualCanvasHeight - startBounds.top,
                      );
                  onTempBoundsChanged(
                    Rect.fromLTWH(
                      newL,
                      startBounds.top,
                      startBounds.right - newL,
                      newH,
                    ),
                  );
                },
                onPanEnd: (_) => _clearDragState(),
                onPanCancel: _clearDragState,
                child: const CropHandleWidget(),
              ),
            ),
            // CORNER 4: BOTTOM RIGHT
            Positioned(
              left: tLeft + tWidth - halfHandle,
              top: tTop + tHeight - halfHandle,
              width: handleSize,
              height: handleSize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _startBoundsDrag,
                onPanUpdate: (details) {
                  final startBounds = _dragStartBounds;
                  if (startBounds == null) return;
                  final canvasDelta = _canvasDragDelta(details.globalPosition);
                  final double newW = (startBounds.width + canvasDelta.dx)
                      .clamp(
                        minBoundSize,
                        virtualCanvasWidth - startBounds.left,
                      );
                  final double newH = (startBounds.height + canvasDelta.dy)
                      .clamp(
                        minBoundSize,
                        virtualCanvasHeight - startBounds.top,
                      );
                  onTempBoundsChanged(
                    Rect.fromLTWH(
                      startBounds.left,
                      startBounds.top,
                      newW,
                      newH,
                    ),
                  );
                },
                onPanEnd: (_) => _clearDragState(),
                onPanCancel: _clearDragState,
                child: const CropHandleWidget(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
