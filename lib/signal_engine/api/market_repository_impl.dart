import 'package:gold_signal/signal_engine/api/binance_api_service.dart';
import 'package:gold_signal/signal_engine/model/multi_timeframe_model.dart';
import '../model/candle.dart';
import '../model/timeframe.dart';

abstract class MarketRepository {
  Future<List<Candle>> getCandles(Timeframe tf);
  Future<MultiTimeFrameModel> getBinanceCandles();
}

class MarketRepositoryImpl implements MarketRepository {
  final BinanceApiService binanceApiService;

  MarketRepositoryImpl(
      {required this.binanceApiService});

  @override
  Future<List<Candle>> getCandles(Timeframe tf) async {    
      final interval = mapTimeFrameToBinance(tf);
      return await binanceApiService.getCandles(interval);
   
  }

  @override
  Future<MultiTimeFrameModel> getBinanceCandles() async {
    final h1Candles = await binanceApiService.getCandles('1h');
    final m15Candles = await binanceApiService.getCandles('15m');
    final m5Candles = await binanceApiService.getCandles('5m');
    final h4Candles = await binanceApiService.getCandles('4h');
    return MultiTimeFrameModel(h4:h4Candles,h1: h1Candles, m15: m15Candles, m5: m5Candles);
  }

  String mapTimeFrameToBinance(Timeframe tf) {
    switch (tf) {
      case Timeframe.m1:
        return '1m';
      case Timeframe.m5:
        return '5m';
      case Timeframe.m15:
        return '15m';
      case Timeframe.m30:
        return '30m';
      case Timeframe.h1:
        return '1h';
      case Timeframe.h4:
        return '4h';
      case Timeframe.d1:
        return '1d';
      default:
        return '1h';
    }
  }
}
