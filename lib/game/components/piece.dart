import 'dart:ui';
import 'package:flame/components.dart';
import '../caro_theme.dart';

class CaroPiece extends PositionComponent {
  final PlayerType type;
  final double cellSize;

  CaroPiece({
    required this.type,
    this.cellSize = CaroTheme.cellSize,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(cellSize));

  @override
  void render(Canvas canvas) {
    final margin = cellSize * 0.2;
    final rect = Rect.fromLTWH(margin, margin, cellSize - 2 * margin, cellSize - 2 * margin);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = CaroTheme.pieceStrokeWidth
      ..strokeCap = StrokeCap.round;

    if (type == PlayerType.o) {
      paint.color = CaroTheme.playerOColor;
      canvas.drawCircle(
        Offset(cellSize / 2, cellSize / 2),
        (cellSize - 2 * margin) / 2,
        paint,
      );
    } else {
      paint.color = CaroTheme.playerXColor;
      canvas.drawLine(
        Offset(margin, margin),
        Offset(cellSize - margin, cellSize - margin),
        paint,
      );
      canvas.drawLine(
        Offset(cellSize - margin, margin),
        Offset(margin, cellSize - margin),
        paint,
      );
    }
  }
}
