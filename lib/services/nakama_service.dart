import 'dart:async';
import 'dart:convert';
import 'package:nakama/nakama.dart' as nk;
import 'package:uuid/uuid.dart';

class NakamaService {
  late final nk.NakamaBaseClient _client;
  nk.Session? _session;
  nk.NakamaWebsocketClient? _socket;

  static const String host = String.fromEnvironment(
    'NAKAMA_HOST',
    defaultValue: '127.0.0.1',
  );
  static const int port = int.fromEnvironment(
    'NAKAMA_PORT',
    defaultValue: 7350,
  );
  static const String serverKey = String.fromEnvironment(
    'NAKAMA_SERVER_KEY',
    defaultValue: 'defaultkey',
  );
  static const bool ssl = bool.fromEnvironment(
    'NAKAMA_SSL',
    defaultValue: false,
  );

  final _matchDataController = StreamController<nk.MatchData>.broadcast();
  Stream<nk.MatchData> get matchDataStream => _matchDataController.stream;

  final _matchPresenceController =
      StreamController<nk.MatchPresenceEvent>.broadcast();
  Stream<nk.MatchPresenceEvent> get matchPresenceStream =>
      _matchPresenceController.stream;

  final _matchmakerMatchedController =
      StreamController<nk.MatchmakerMatched>.broadcast();
  Stream<nk.MatchmakerMatched> get matchmakerMatchedStream =>
      _matchmakerMatchedController.stream;

  NakamaService() {
    _client = nk.getNakamaClient(
      host: host,
      httpPort: port,
      serverKey: serverKey,
      ssl: ssl,
    );
  }

  Future<void> authenticate() async {
    final deviceId = const Uuid().v4();
    _session = await _client.authenticateDevice(deviceId: deviceId);

    _socket = nk.NakamaWebsocketClient.init(
      host: host,
      port: port,
      ssl: ssl,
      token: _session!.token,
    );

    _socket!.onMatchData.listen(
      (data) {
        print(
          'NakamaService: [RAW] MatchData received: channel=${data.matchId} opCode=${data.opCode} sender=${data.presence?.userId}',
        );
        _matchDataController.add(data);
      },
      onError: (e) =>
          print('NakamaService: [ERROR] Socket matchData error: $e'),
    );

    _socket!.onMatchPresence.listen(
      (event) {
        print(
          'NakamaService: [RAW] MatchPresence event: joins=${event.joins.length} leaves=${event.leaves.length}',
        );
        _matchPresenceController.add(event);
      },
      onError: (e) =>
          print('NakamaService: [ERROR] Socket matchPresence error: $e'),
    );

    _socket!.onMatchmakerMatched.listen(
      (event) {
        print(
          'NakamaService: [RAW] MatchmakerMatched: matchId=${event.matchId}',
        );
        _matchmakerMatchedController.add(event);
      },
      onError: (e) =>
          print('NakamaService: [ERROR] Socket matchmakerMatched error: $e'),
    );
  }

  Future<void> startMatchmaking() async {
    if (_socket == null) throw Exception('Socket not initialized');

    await _socket!.addMatchmaker(minCount: 2, maxCount: 2, query: '*');
  }

  Future<nk.Match> joinMatch({String? matchId, String? token}) async {
    if (_socket == null) throw Exception('Socket not initialized');
    print('NakamaService: Joining match with matchId: $matchId, token: $token');
    // The Nakama SDK positional argument for matchId is usually String? but let's be safe.
    return await _socket!.joinMatch(matchId ?? '', token: token);
  }

  void sendMove(String matchId, int x, int y, int opCode) {
    if (_socket == null) {
      print('NakamaService: [ERROR] Cannot send move, socket is NULL');
      return;
    }

    try {
      final data = jsonEncode({'x': x, 'y': y});
      print(
        'NakamaService: [TX] Sending move to match $matchId (opCode: $opCode): $data',
      );
      _socket!.sendMatchData(
        matchId: matchId,
        opCode: opCode,
        data: utf8.encode(data),
      );
    } catch (e) {
      print('NakamaService: [ERROR] sendMatchData exception: $e');
    }
  }

  String? get myUserId => _session?.userId;
}
