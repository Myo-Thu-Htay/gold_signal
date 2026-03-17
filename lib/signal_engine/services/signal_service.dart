import '../model/multi_timeframe_model.dart';
import '../model/candle.dart';
import 'trend_service.dart';
import 'volume_filter.dart';

class SignalService {
  final VolumeFilter _volumeFilter = VolumeFilter();
  final TrendService _trendService = TrendService();
  bool isBullish(List<Candle> candles) {
    if (candles.length < 50) return false;
    double ema50 = calculateEMA(candles, 50);
    final lastClose = candles.last.close > ema50;
    //print(  'EMA50: $ema50, Last Close: ${candles.last.close}, Bullish: $lastClose');
    return lastClose;
  }

  bool isBearish(List<Candle> candles) {
    if (candles.length < 50) return false;
    double ema50 = calculateEMA(candles, 50);
    final lastClose = candles.last.close < ema50;
    //print(  'EMA50: $ema50, Last Close: ${candles.last.close}, Bearish: $lastClose');
    return lastClose;
  }

  int calculateConfidence(MultiTimeFrameModel multiTf) {
    int score = 0;
    if (isBullish(multiTf.h1)) score += 4;
    if (isBearish(multiTf.h1)) score -= 4;
    if (isBullish(multiTf.m15)) score += 3;
    if (isBearish(multiTf.m15)) score -= 3;
    if (isBullish(multiTf.m5)) score += 2;
    if (isBearish(multiTf.m5)) score -= 2;
    if (rsiBullish(multiTf.m15)) score += 2;
    if (rsiBearish(multiTf.m15)) score -= 2;
    if (_volumeFilter.confirmBullish(multiTf.m5)) score += 1;
    if (_volumeFilter.confirmBearish(multiTf.m5)) score -= 1;
    return score;
  }

  double calculateSMA(List<Candle> candles, int period) {
    if (candles.length < period) return 0.0;
    double sum = 0.0;
    for (int i = candles.length - period; i < candles.length; i++) {
      sum += candles[i].close;
    }
    return sum / period;
  }

  double calculateEMA(List<Candle> candles, int period) {
    if (candles.length < period) return 0.0;
    double k = 2 / (period + 1);
    //Step 1 : first EMA = SMA
    double ema = calculateSMA(candles.sublist(0, period), period);
    //Step 2 : Continue EMA
    for (int i = period; i < candles.length; i++) {
      ema = (candles[i].close * k) + (ema * (1 - k));
    }
    return ema;
  }

  bool isPullBackToEMA50(List<Candle> candles) {
    if (candles.length < 52) return false;

    const k = 2 / (50 + 1);

    double ema = calculateSMA(candles.sublist(0, 50), 50);

    for (int i = 50; i < candles.length; i++) {
      ema = (candles[i].close * k) + (ema * (1 - k));
    }

    double prevClose = candles[candles.length - 2].close;
    double lastClose = candles.last.close;

    // bullish pullback
    bool bullishPullback = prevClose > ema && lastClose <= ema;

    // bearish pullback
    bool bearishPullback = prevClose < ema && lastClose >= ema;
    // print(
    //     'bullishPullback: $bullishPullback, bearishPullback: $bearishPullback, EMA50: $ema, Prev Close: $prevClose, Last Close: $lastClose');
    return bullishPullback || bearishPullback;
  }

  bool bullishBreak(List<Candle> m5) {
    if (m5.length < 2) return false;
    final lastCandle = m5.last;
    final prevCandle = m5[m5.length - 2];
    return lastCandle.close > prevCandle.high &&
        lastCandle.close > prevCandle.close;
  }

  double calculateRSI(List<Candle> candles, {int period = 14}) {
    if (candles.length < 14) {
      return 50.0;
    }
    double gain = 0.0;
    double loss = 0.0;
    // Initial average gain/loss
    for (int i = 1; i < period; i++) {
      double change = candles[i].close - candles[i - 1].close;
      if (change > 0) {
        gain += change;
      } else {
        loss += change.abs();
      }
    }
    double avgGain = gain / period;
    double avgLoss = loss / period;
    // Continue smoothing (Wilder's smoothing)
    for (int i = period + 1; i < candles.length; i++) {
      double change = candles[i].close - candles[i - 1].close;
      double currentGain = change > 0 ? change : 0;
      double currentLoss = change < 0 ? change.abs() : 0;
      avgGain = ((avgGain * (period - 1)) + currentGain) / period;
      avgLoss = ((avgLoss * (period - 1)) + currentLoss) / period;
    }
    if (avgLoss == 0) return 100.0;
    double rs = avgGain / avgLoss;
    double rsi = 100 - (100 / (1 + rs));

    return rsi;
  }

  // RSI confirmation
  bool rsiBullish(List<Candle> candles) {
    double rsi = calculateRSI(candles);
    return rsi > 50 && rsi < 70;
  }

  bool rsiBearish(List<Candle> candles) {
    double rsi = calculateRSI(candles);
    return rsi < 50 && rsi > 30;
  }

  List<Candle> calculateMA(List<Candle> candles, int period) {
    List<Candle> maCandles = [];
    for (int i = 0; i < candles.length; i++) {
      if (i >= period - 1) {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += candles[i - j].close;
        }
        double maValue = sum / period;
        maCandles.add(Candle(
          time: candles[i].time,
          open: maValue,
          high: maValue,
          low: maValue,
          close: maValue,
          volume: candles[i].volume,
        ));
      }
    }
    return maCandles;
  }

  bool isBuyRejection(List<Candle> candles) {
    if (candles.length < 2) return false;
    final lastCandle = candles.last;
    final prevCandle = candles[candles.length - 2];
    bool lowerRejection =
        lastCandle.open - lastCandle.low > (lastCandle.close - lastCandle.open) * 2 &&
            lastCandle.close > prevCandle.close;
    return lowerRejection;
  }
  bool isSellRejection(List<Candle> candles) {
    if (candles.length < 2) return false;
    final lastCandle = candles.last;
    final prevCandle = candles[candles.length - 2];
    bool upperRejection =
        lastCandle.high - lastCandle.close > (lastCandle.close - lastCandle.open) * 2 &&
            lastCandle.close < prevCandle.close;
    return upperRejection;
  }

  String generateSignal(MultiTimeFrameModel multiTf, int score) {
    final trend = _trendService.analyzeTrend(multiTf.h1);
    if (trend.direction == TrendDirection.sideways && !trend.isHealthy) {
      return 'Hold';
    }
    bool h1Bull = isBullish(multiTf.h1);
    bool h1Bear = isBearish(multiTf.h1);
    bool pullBack = isPullBackToEMA50(multiTf.m15);
    bool rsiBull = rsiBullish(multiTf.m15);
    bool rsiBear = rsiBearish(multiTf.m15);
    bool isBullishBreak = bullishBreak(multiTf.m5);
    bool isBuyReject = isBuyRejection(multiTf.m5);
    bool isSellReject = isSellRejection(multiTf.m5);


    if (h1Bull && pullBack && rsiBull && isBullishBreak && isBuyReject) {
      return 'Strong Buy';
    }
    if (h1Bear && pullBack && rsiBear && !isBullishBreak && isSellReject) {
      return 'Strong Sell';
    }
    if (h1Bull && rsiBull && isBuyReject && isBullishBreak) {
      return 'Buy';
    }
    if (h1Bear && rsiBear && isSellReject && !isBullishBreak) {
      return 'Sell';
    }
    return 'Hold';
  }
}
