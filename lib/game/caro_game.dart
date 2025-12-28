import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/board.dart';
import 'components/piece.dart';
import 'components/last_move_indicator.dart';
import 'caro_theme.dart';
import '../logic/game_state.notifier.dart';

class CaroGame extends FlameGame with TapDetector, PanDetector {
  final WidgetRef ref;
  late final CaroBoard board;
  // Track pieces by their grid coordinates
  final Map<String, CaroPiece> _piecesMap = {};
  LastMoveIndicator? lastMoveIndicator;

  CaroGame(this.ref);

  @override
  Future<void> onLoad() async {
    print('CaroGame: onLoad started');

    board = CaroBoard();
    board.priority = -1;

    // Add components to the world
    world.add(board);

    // Setup camera
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = 1.0;

    // Initial position: center of the board
    final centerX = (board.cols * CaroTheme.cellSize) / 2;
    final centerY = (board.rows * CaroTheme.cellSize) / 2;
    camera.viewfinder.position = Vector2(centerX, centerY);

    print(
      'CaroGame: board added to world and camera centered at ($centerX, $centerY)',
    );
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Move the camera in the opposite direction of the pan (to simulate dragging the board)
    camera.viewfinder.position -= info.delta.global;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final gameState = ref.read(gameStateProvider);
    _syncPieces(gameState);
    _syncLastMove(gameState);
  }

  @override
  void onTapDown(TapDownInfo info) {
    // Convert screen coordinates to world coordinates using the camera
    final worldPosition = camera.globalToLocal(info.eventPosition.widget);
    print('CaroGame: TapDown (World) at $worldPosition');

    final gameState = ref.read(gameStateProvider);
    if (gameState.winner != null) {
      print('CaroGame: Click ignored (winner exists)');
      return;
    }

    final gridX = (worldPosition.x / CaroTheme.cellSize).floor();
    final gridY = (worldPosition.y / CaroTheme.cellSize).floor();

    print('CaroGame: Grid attempt at ($gridX, $gridY)');
    if (gridX >= 0 && gridX < board.cols && gridY >= 0 && gridY < board.rows) {
      if (gameState.board[gridY][gridX] == null) {
        print('CaroGame: Placing piece at ($gridX, $gridY)');
        ref
            .read(gameStateProvider.notifier)
            .placePiece(gridX, gridY, gameState.currentTurn);
      } else {
        print('CaroGame: Cell ($gridX, $gridY) already occupied');
      }
    } else {
      print('CaroGame: Click out of bounds');
    }
  }

  void _syncPieces(GameState state) {
    for (int y = 0; y < state.board.length; y++) {
      for (int x = 0; x < state.board[y].length; x++) {
        final type = state.board[y][x];
        if (type != null) {
          final key = '$x,$y';
          if (!_piecesMap.containsKey(key)) {
            print('CaroGame: Adding new piece for $type at ($x, $y)');
            final pos = Vector2(x * CaroTheme.cellSize, y * CaroTheme.cellSize);
            final piece = CaroPiece(type: type, position: pos);
            piece.priority = 1;
            world.add(piece); // Add to world
            _piecesMap[key] = piece;
          }
        }
      }
    }

    if (_isBoardEmpty(state.board) && _piecesMap.isNotEmpty) {
      print('CaroGame: Board reset detected');
      for (var p in _piecesMap.values) {
        p.removeFromParent();
      }
      _piecesMap.clear();
    }
  }

  bool _isBoardEmpty(List<List<PlayerType?>> board) {
    for (var row in board) {
      for (var cell in row) {
        if (cell != null) return false;
      }
    }
    return true;
  }

  void _syncLastMove(GameState state) {
    if (state.lastMove != null) {
      final pos = Vector2(
        state.lastMove!.$1 * CaroTheme.cellSize,
        state.lastMove!.$2 * CaroTheme.cellSize,
      );

      if (lastMoveIndicator == null || lastMoveIndicator!.position != pos) {
        if (lastMoveIndicator != null) lastMoveIndicator!.removeFromParent();
        lastMoveIndicator = LastMoveIndicator(position: pos);
        lastMoveIndicator!.priority = 2;
        world.add(lastMoveIndicator!); // Add to world
      }
    }
  }

  @override
  Color backgroundColor() => CaroTheme.backgroundColor;
}
