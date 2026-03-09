// ignore_for_file: curly_braces_in_flow_control_structures

import '../model/multi_timeframe_model.dart';

import '../model/candle.dart';
import 'volume_filter.dart';

class SignalService {
  final VolumeFilter _volumeFilter = VolumeFilter();
  bool isBullish(List<Candle> candles) {
    if (candles.length < 50) return false;
    double ema50 = calculatEMA50(candles);
    final lastClose = candles.last.close > ema50;
    //print(  'EMA50: $ema50, Last Close: ${candles.last.close}, Bullish: $lastClose');
    return lastClose;
  }

  bool isBearish(List<Candle> candles) {
    if (candles.length < 50) return false;
    double ema50 = calculatEMA50(candles);
    final lastClose = candles.last.close < ema50;
    //print(  'EMA50: $ema50, Last Close: ${candles.last.close}, Bearish: $lastClose');
    return lastClose;
  }

  double calculateTrendStrength(List<Candle> candles) {
    if (candles.isEmpty) return 0.0;
    final first = candles.first;
    final last = candles.last;
    final priceChange = last.close - first.open;
    final trendStrength = (priceChange / first.open) * 100;
    //print('Price Change: $priceChange, Trend Strength: ${trendStrength.clamp(-100, 100)}%');
    return trendStrength.clamp(-100, 100);
  }

  List<double> calculateTrend(List<Candle> candles) {
    final List<double> strengths = [];
    for (int i = 1; i < candles.length; i++) {
      final sublist = candles.sublist(0, i + 1);
      strengths.add(calculateTrendStrength(sublist));
    }
    //print('Trend strengths: $strengths');
    return strengths;
  }

  int calculateConfidence(MultiTimeFrameModel multiTf) {
    int score = 0;
    if (isBullish(multiTf.h1) || isBearish(multiTf.h1)) score += 3;
    if (isBullish(multiTf.m15) || isBearish(multiTf.m15)) score += 2;
    if (isBullish(multiTf.m5) || isBearish(multiTf.m5)) score += 1;
    if (rsiBullish(multiTf.h1) || rsiBearish(multiTf.h1)) score += 3;
    if (rsiBullish(multiTf.m15) || rsiBearish(multiTf.m15)) score += 2;
    if (rsiBullish(multiTf.m5) || rsiBearish(multiTf.m5)) score += 1;
    if (_volumeFilter.confirmBullish(multiTf.h1)) score += 3;
    if (_volumeFilter.confirmBullish(multiTf.m15)) score += 2;
    if (_volumeFilter.confirmBullish(multiTf.m5)) score += 1;
    
    return score;
  }

  String quality(int score) {
    if (score >= 15) return "A+";
    if (score >= 12) return "B";
    if (score >= 6) return "C";
    return "Hold";
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

  double calculatEMA50(List<Candle> candles) {
    return calculateEMA(candles, 50);
  }

  bool isPullBackToEMA50(List<Candle> candles) {
    if (candles.length < 51) return false;
    const k = 2 / (50 + 1);
    // Calculate full EMA50 series
    List<double> ema50Series = [];
    double ema = calculateSMA(candles.sublist(0, 50), 50);
    ema50Series.add(ema);
    for (int i = 50; i < candles.length; i++) {
      ema = (candles[i].close * k) + (ema * (1 - k));
      ema50Series.add(ema);
    }
    if (ema50Series.length < 2) return false;
    //int lastIndex = ema50Series.length - 1;
    double prevClose = candles[candles.length - 2].close;
    double lastClose = candles[candles.length - 1].close;
    double prevEma = ema50Series[ema50Series.length - 2];
    double lastEma = ema50Series[ema50Series.length - 1];
    bool pullback = (prevClose > prevEma && lastClose < lastEma) ||
        (prevClose < prevEma && lastClose > lastEma);
    //print('Prev Close: $prevClose, Last Close: $lastClose, Prev EMA: $prevEma, Last EMA: $lastEma, Pullback: $pullback');
    return pullback;
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
    return rsi > 45 && rsi < 75;
  }

  bool rsiBearish(List<Candle> candles) {
    double rsi = calculateRSI(candles);
    return rsi < 45 && rsi > 30;
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

  String generateSignal(MultiTimeFrameModel multiTf, int score) {
    if (multiTf.h1.length < 50 ||
        multiTf.m15.length < 50 ||
        multiTf.m5.length < 50) return 'Hold';
    bool h1Bull = isBullish(multiTf.h1);
    bool h1Bear = isBearish(multiTf.h1);
    bool pullBack = isPullBackToEMA50(multiTf.m15);
    bool rsiBull = rsiBullish(multiTf.m15);
    bool rsiBear = rsiBearish(multiTf.m15);

    //print( 'H1 Bull: $h1Bull, H1 Bear: $h1Bear, PullBack: $pullBack,  RSI Bull: $rsiBull, RSI Bear: $rsiBear');
    if (h1Bull && pullBack && score >= 15 && rsiBull) {     
      return 'Strong Buy';
    } else if (h1Bear && pullBack && score >= 15 && rsiBear) {   
      return 'Strong Sell';
    } else if (h1Bull && score >= 12) {
      return 'Buy';
    } else if (h1Bear && score >= 12) {
      return 'Sell';
    } else {
      return 'Hold';
    }
  }
}
