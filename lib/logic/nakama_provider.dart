import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nakama_service.dart';

final nakamaServiceProvider = Provider<NakamaService>((ref) {
  return NakamaService();
});
