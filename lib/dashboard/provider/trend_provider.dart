import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../signal_engine/provider/market_provider.dart';
import '../../signal_engine/services/trend_service.dart';

final trendProvider = Provider((ref) {
  final candles = ref.watch(binanceCandlesProvider).value;
  if (candles == null) return "Loading";
  final trendService = TrendService();

  final trendInfo = trendService.analyzeTrend(candles);
  switch (trendInfo.direction) {
    case TrendDirection.up:
      return "Uptrend";
    case TrendDirection.down:
      return "Downtrend";
    case TrendDirection.sideways:
      return "Sideways";
  }
});
