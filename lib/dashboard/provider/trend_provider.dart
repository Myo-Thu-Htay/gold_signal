import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../signal_engine/provider/market_provider.dart';
import '../../signal_engine/services/trend_service.dart';

final trendProvider = Provider((ref) {
  final candles = ref.watch(binanceCandlesProvider).value;
  if (candles == null) return "Loading";
  final trendService = TrendService();

  if (trendService.isTrendReversal(candles)) {
    return "Reversal";
  }
  if (trendService.isUptrend(candles)) {
    return "Uptrend";
  }
  if (trendService.isDowntrend(candles)) {
    return "Downtrend";
  }
  if (trendService.isTrendContinuation(candles)) {
    return "Continuation";
  }
  if (trendService.isSideways(candles)) {
    return "Sideways";
  }
  return "Unknown";
});


