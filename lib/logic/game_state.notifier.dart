import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nakama/nakama.dart' as nk;
import 'dart:convert';
import '../game/caro_theme.dart';
import 'win_condition_checker.dart';
import '../services/nakama_service.dart';
import 'nakama_provider.dart';

class GameState {
  final List<List<PlayerType?>> board;
  final PlayerType? winner;
  final PlayerType currentTurn;
  final PlayerType? myType;
  final bool isMyTurn;
  final (int, int)? lastMove;
  final String? matchId;
  final bool isSearching;

  GameState({
    required this.board,
    this.winner,
    this.currentTurn = PlayerType.x,
    this.myType,
    this.isMyTurn = false,
    this.lastMove,
    this.matchId,
    this.isSearching = false,
  });

  GameState copyWith({
    List<List<PlayerType?>>? board,
    PlayerType? winner,
    PlayerType? currentTurn,
    PlayerType? myType,
    bool? isMyTurn,
    (int, int)? lastMove,
    String? matchId,
    bool? isSearching,
  }) {
    return GameState(
      board: board ?? this.board,
      winner: winner ?? this.winner,
      currentTurn: currentTurn ?? this.currentTurn,
      myType: myType ?? this.myType,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      lastMove: lastMove ?? this.lastMove,
      matchId: matchId ?? this.matchId,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class GameStateNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    final nakama = ref.watch(nakamaServiceProvider);
    _listenToNakama(nakama);
    return GameState(board: List.generate(50, (_) => List.filled(50, null)));
  }

  void _listenToNakama(NakamaService nakama) {
    // Match data listener
    nakama.matchDataStream.listen((data) {
      final String opCodeStr = data.opCode.toString();
      print(
        'GameStateNotifier: [RX] opCode=$opCodeStr from ${data.presence?.userId}',
      );

      if (data.data != null && data.data!.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(data.data!));
          print('GameStateNotifier: [RX] Decoded content: $decoded');

          if (opCodeStr == '1') {
            final int x = decoded['x'];
            final int y = decoded['y'];
            _handleRemoteMove(x, y);
          }
        } catch (e) {
          print('GameStateNotifier: [ERROR] Failed to decode match data: $e');
        }
      } else {
        print(
          'GameStateNotifier: [RX] Received empty data payload for opCode $opCodeStr',
        );
      }
    });

    // Matchmaker listener
    nakama.matchmakerMatchedStream.listen((event) async {
      print('MatchmakerMatched event received: ${event.matchId}');
      print(
        'Matched users: ${event.users.map((u) => u.presence.userId).toList()}',
      );

      final match = await nakama.joinMatch(
        matchId: event.matchId,
        token: event.token,
      );
      print('Joined match as: ${nakama.myUserId}');

      // Determine player type deterministically.
      // X is the player with the lexicographically smaller userId.
      final participants = event.users.map((u) => u.presence!.userId).toList();
      participants.sort();

      final myUserId = nakama.myUserId;
      final myType = (myUserId == participants.first)
          ? PlayerType.x
          : PlayerType.o;

      print(
        'Match roles: First=${participants.first}, Second=${participants.length > 1 ? participants[1] : "N/A"}',
      );
      print('My Role: $myType');

      state = state.copyWith(
        matchId: match.matchId,
        myType: myType,
        isMyTurn: myType == PlayerType.x,
        isSearching: false,
      );
    });
  }

  Future<void> joinGame() async {
    final nakama = ref.read(nakamaServiceProvider);
    state = state.copyWith(isSearching: true);

    await nakama.authenticate();
    await nakama.startMatchmaking();
  }

  void placePiece(int x, int y, PlayerType type) {
    if (state.board[y][x] != null || state.winner != null || !state.isMyTurn)
      return;

    _applyMove(x, y, type);

    if (state.matchId != null) {
      ref.read(nakamaServiceProvider).sendMove(state.matchId!, x, y, 1);
    }
  }

  void _handleRemoteMove(int x, int y) {
    final opponentType = state.myType == PlayerType.x
        ? PlayerType.o
        : PlayerType.x;
    _applyMove(x, y, opponentType);
  }

  void _applyMove(int x, int y, PlayerType type) {
    print('Applying move: ($x, $y) for $type');
    final newBoard = state.board
        .map((row) => List<PlayerType?>.from(row))
        .toList();
    newBoard[y][x] = type;

    final winner = WinConditionChecker.checkWin(newBoard, x, y);
    final nextTurn = type == PlayerType.x ? PlayerType.o : PlayerType.x;

    state = state.copyWith(
      board: newBoard,
      winner: winner,
      currentTurn: nextTurn,
      isMyTurn: state.myType == nextTurn,
      lastMove: (x, y),
    );
    print(
      'New state applied. Winner: ${state.winner}, IsMyTurn: ${state.isMyTurn}',
    );
  }

  void reset() {
    state = GameState(
      board: List.generate(50, (_) => List.filled(50, null)),
      myType: state.myType,
      isMyTurn: state.myType == PlayerType.x,
    );
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(() {
  return GameStateNotifier();
});
