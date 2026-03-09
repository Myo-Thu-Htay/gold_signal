import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../api/binance_api_service.dart';
import '../model/candle.dart';
import '../model/multi_timeframe_model.dart';
import '../model/timeframe.dart';
import '../api/market_repository_impl.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepositoryImpl(binanceApiService: BinanceApiService());
});

final selectedTimeframeProvider = StateProvider<Timeframe>((ref) {
  return Timeframe.h1; // Default timeframe
});

final binanceCandlesProvider = FutureProvider<List<Candle>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  final tf = ref.watch(selectedTimeframeProvider);
  return await repository.getCandles(tf);
});
final getBinanceCandles = FutureProvider<MultiTimeFrameModel>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  return await repository.getBinanceCandles();
});

