import 'package:flutter/material.dart';
import '../../signal_engine/model/candle.dart';

class Controller{
  final ValueNotifier<double> livePrice = ValueNotifier(0);
  final ValueNotifier<List<Candle>> candles = ValueNotifier([]);

  void initialCandles(List<Candle> data) {
    candles.value = data;
  }
  void updatePrice(double price) {
    livePrice.value = price;
  }

  double calculatePreview(List<Candle> candles,bool isBuy,double entry,double sl,double tp,double lot,double exitManual,String result)  {
      if (entry == 0.0 || sl == 0.0 || tp ==0.0 || lot == 0.0) return 0.0;
    double price = candles.last.close;
    double exit = 0.0;
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      if (result == "TP") {
        exit = tp;
      } else if (result == "SL") {
        exit = sl;
      } else if (result == "Manual") {
        exit = exitManual;
      } else {
        if (isBuy) {
          lastCandle.low <= sl ? exit = sl : exit = price;
          lastCandle.high >= tp ? exit = tp : exit = price;
        } else {
          lastCandle.high >= sl ? exit = sl : exit = price;
          lastCandle.low <= tp ? exit = tp : exit = price;
        }
      }
    }

    final pnl = isBuy ? (exit - entry) * lot * 100 : (entry - exit) * lot * 100;
    return pnl;
  }

  
  

}