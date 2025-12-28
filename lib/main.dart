import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game/caro_game.dart';
import 'logic/game_state.notifier.dart';
import 'game/caro_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CaroApp()));
}

class CaroApp extends StatelessWidget {
  const CaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Online',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: CaroTheme.playerXColor),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(gameStateProvider).isSearching;

    return Scaffold(
      backgroundColor: CaroTheme.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CARO ONLINE',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: CaroTheme.playerXColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
                _PlayerNameInput(),
                const SizedBox(height: 24),
                _MatchmakingButton(),
              ],
            ),
          ),
          if (isSearching)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Đang tìm đối thủ...',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Vui lòng đợi trong giây lát...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerNameInput extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PlayerNameInput> createState() => _PlayerNameInputState();
}

class _PlayerNameInputState extends ConsumerState<_PlayerNameInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(gameStateProvider).playerName;
    _controller = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameStateProvider.select((s) => s.playerName), (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });

    return SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _controller,
          onChanged: (value) {
            ref.read(gameStateProvider.notifier).updatePlayerName(value);
          },
          decoration: InputDecoration(
            labelText: 'Tên của bạn',
            labelStyle: TextStyle(color: CaroTheme.playerXColor),
            suffixIcon: Icon(Icons.edit, color: CaroTheme.playerXColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: CaroTheme.playerXColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: CaroTheme.playerXColor, width: 2),
            ),
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _MatchmakingButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final isLoading = gameState.isSearching;

    // Listen for matchId to navigate
    ref.listen(gameStateProvider.select((s) => s.matchId), (previous, next) {
      if (next != null && previous == null) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GameScreen()));
      }
    });

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () => ref.read(gameStateProvider.notifier).joinGame(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        backgroundColor: CaroTheme.playerXColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('TÌM ĐỐI THỦ...', style: TextStyle(fontSize: 18)),
              ],
            )
          : const Text('CHƠI', style: TextStyle(fontSize: 20)),
    );
  }
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late CaroGame game;

  @override
  void initState() {
    super.initState();
    game = CaroGame(ref);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gameState.winner != null
                  ? 'Người thắng: ${gameState.winner == gameState.myType ? "BẠN" : (gameState.opponentName ?? "Đối thủ")}'
                  : 'Lượt: ${gameState.isMyTurn ? "BẠN" : (gameState.opponentName ?? "Đối thủ")}',
              style: TextStyle(
                fontSize: 18,
                color: gameState.currentTurn == PlayerType.x
                    ? CaroTheme.playerXColor
                    : CaroTheme.playerOColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${gameState.playerName} (Bạn) vs ${gameState.opponentName ?? "Đang chờ..."} (Đối thủ)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(gameStateProvider.notifier).reset();
              // Re-mount game widget to clear Flame state easily
              setState(() {
                game = CaroGame(ref);
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GameWidget(game: game),
          if (gameState.winner != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gameState.winner == gameState.myType
                          ? 'BẠN THẮNG!'
                          : 'BẠN THUA!',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        color: gameState.winner == gameState.myType
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'VỀ TRANG CHỦ',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
