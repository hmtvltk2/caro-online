import '../game/caro_theme.dart';

class WinConditionChecker {
  static PlayerType? checkWin(List<List<PlayerType?>> board, int lastX, int lastY) {
    final PlayerType? type = board[lastY][lastX];
    if (type == null) return null;

    final directions = [
      [0, 1],  // Horizontal
      [1, 0],  // Vertical
      [1, 1],  // Diagonal \
      [1, -1], // Diagonal /
    ];

    for (final dir in directions) {
      int count = 1;
      
      // Positive direction
      count += _countInDirection(board, lastX, lastY, dir[0], dir[1], type);
      // Negative direction
      count += _countInDirection(board, lastX, lastY, -dir[0], -dir[1], type);

      if (count >= 5) return type;
    }

    return null;
  }

  static int _countInDirection(
    List<List<PlayerType?>> board,
    int x,
    int y,
    int dx,
    int dy,
    PlayerType type,
  ) {
    int count = 0;
    int curX = x + dx;
    int curY = y + dy;
    final rows = board.length;
    final cols = board[0].length;

    while (curX >= 0 && curX < cols && curY >= 0 && curY < rows && board[curY][curX] == type) {
      count++;
      curX += dx;
      curY += dy;
    }
    return count;
  }
}
