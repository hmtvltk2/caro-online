import 'dart:ui';
import 'package:flame/components.dart';
import '../caro_theme.dart';

class LastMoveIndicator extends PositionComponent {
  final double cellSize;

  LastMoveIndicator({
    this.cellSize = CaroTheme.cellSize,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(cellSize));

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = CaroTheme.lastMoveColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, cellSize, cellSize),
      paint,
    );
  }
}
