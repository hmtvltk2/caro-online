import 'package:flutter/material.dart';

class CaroTheme {
  static const Color gridColor = Color(0xFFCCCCCC);
  static const Color backgroundColor = Color(0xFFFDFDF6);
  static const Color playerXColor = Color(0xFF1A237E); // Deep Blue
  static const Color playerOColor = Color(0xFFD32F2F); // Bright Red
  static const Color lastMoveColor = Color(0xFF90CAF9); // Light Blue

  static const double gridStrokeWidth = 1.0;
  static const double pieceStrokeWidth = 4.0;
  static const double cellSize = 40.0;
}

enum PlayerType { x, o }
