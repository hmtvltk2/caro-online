import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../caro_theme.dart';

class CaroBoard extends PositionComponent with TapCallbacks {
  final int rows;
  final int cols;
  final double cellSize;

  CaroBoard({
    this.rows = 15,
    this.cols = 15,
    this.cellSize = CaroTheme.cellSize,
  }) : super(size: Vector2(cols * cellSize, rows * cellSize));

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = CaroTheme.gridColor
      ..strokeWidth = CaroTheme.gridStrokeWidth
      ..style = PaintingStyle.stroke;

    // Draw background
    canvas.drawRect(
      size.toRect(),
      Paint()..color = CaroTheme.backgroundColor,
    );

    // Draw vertical lines
    for (int i = 0; i <= cols; i++) {
      double x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      double y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Handling taps will be delegated to the game class or a specialized controller
    super.onTapDown(event);
  }
}
