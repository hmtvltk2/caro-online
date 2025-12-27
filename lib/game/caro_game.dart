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
    camera.viewfinder.anchor = Anchor.topLeft;

    board = CaroBoard();
    board.priority = -1; // Ensure board is below pieces
    add(board);
    print('CaroGame: board added with priority ${board.priority}');
  }

  int _updateCounter = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _updateCounter++;
    if (_updateCounter % 300 == 0) {
      print('CaroGame: update heartbeat (frame ${_updateCounter})');
    }

    final gameState = ref.read(gameStateProvider);
    _syncPieces(gameState);
    _syncLastMove(gameState);
  }

  @override
  void onTapDown(TapDownInfo info) {
    final localPosition = info.eventPosition.widget;
    print('CaroGame: TapDown at $localPosition');

    final gameState = ref.read(gameStateProvider);
    if (gameState.winner != null) {
      print('CaroGame: Click ignored (winner exists: ${gameState.winner})');
      return;
    }

    final gridX = (localPosition.x / CaroTheme.cellSize).floor();
    final gridY = (localPosition.y / CaroTheme.cellSize).floor();

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
            piece.priority = 1; // Above board
            add(piece);
            _piecesMap[key] = piece;
          }
        }
      }
    }

    // Handle reset (optional, if state board becomes empty)
    if (_isBoardEmpty(state.board) && _piecesMap.isNotEmpty) {
      print('CaroGame: Board reset detected, clearing visual pieces');
      for (var p in _piecesMap.values) {
        remove(p);
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
        if (lastMoveIndicator != null) remove(lastMoveIndicator!);
        lastMoveIndicator = LastMoveIndicator(position: pos);
        lastMoveIndicator!.priority = 2; // Above pieces
        add(lastMoveIndicator!);
      }
    }
  }

  @override
  Color backgroundColor() => CaroTheme.backgroundColor;
}
