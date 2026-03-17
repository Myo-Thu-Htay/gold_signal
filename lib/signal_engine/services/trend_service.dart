import '../model/candle.dart';
import 'atr_service.dart';
import 'signal_service.dart';

enum TrendDirection { up, down, sideways }

class TrendInfo {
  final TrendDirection direction;
  final double strength;
  final bool isHealthy;
  final bool isPullback;

  TrendInfo({
    required this.direction,
    required this.strength,
    required this.isHealthy,
    required this.isPullback,
  });
}

class TrendService {
 final SignalService _signalService = SignalService();
 final AtrService _atrService = AtrService();
  TrendInfo analyzeTrend(List<Candle> candles) {
    if (candles.length < 50) {
      return TrendInfo(
        direction: TrendDirection.sideways,
        strength: 0.0,
        isHealthy: false,
        isPullback: false,
      );
    }

    double ema50 = _signalService.calculateEMA(candles, 50);
    double atr = _atrService.calculateATR(candles, 14);
    final price = candles.last.close;
   
    TrendDirection direction;
    if (price > ema50) {
      direction = TrendDirection.up;
    } else if (price < ema50) {
      direction = TrendDirection.down;
    } else {
      direction = TrendDirection.sideways;
    }

    double strength = ((price - ema50).abs()) / atr;
    bool isHealthy = strength > 0.8;
    final prev = candles[candles.length - 2].close;
    bool isPullback = (direction == TrendDirection.up && price < prev) ||
        (direction == TrendDirection.down && price > prev);
    return TrendInfo(
      direction: direction,
      strength: strength,
      isHealthy: isHealthy,
      isPullback: isPullback,
    );
  }

  
}
