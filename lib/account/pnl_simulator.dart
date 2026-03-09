import '../dashboard/models/trade_model.dart';
import '../../signal_engine/model/candle.dart';

class PnLSimulator {
  Trade simulate(
    bool isBuy,
    double entry,
    double sl,
    double tp,
    double lotSize,
    List<Candle> futureCandles,
  ) {
    for (final candle in futureCandles) {
      if (isBuy) {
        if (candle.low <= sl) {
          final loss = (entry - sl) * lotSize;
          return Trade(
            isBuy: true,
            entry: entry,
            stopLoss: sl,
            takeProfit: tp,
            lotSize: lotSize,
            isWin: false,
            pnl: -loss,
            entryTime: candle.time,
            type: isBuy ? "BUY" : "SELL",
          );
        }
        if (candle.high >= tp) {
          final profit = (tp - entry) * lotSize;
          return Trade(
            isBuy: true,
            entry: entry,
            stopLoss: sl,
            takeProfit: tp,
            lotSize: lotSize,
            isWin: true,
            pnl: profit,
            entryTime: candle.time,
            type: isBuy ? "BUY" : "SELL",
          );
        }
      } else {
        if (candle.high >= sl) {
          final loss = (sl - entry) * lotSize;
          return Trade(
            isBuy: false,
            entry: entry,
            stopLoss: sl,
            takeProfit: tp,
            lotSize: lotSize,
            isWin: false,
            pnl: -loss,
            entryTime: candle.time,
            type: isBuy ? "BUY" : "SELL",
          );
        }
        if (candle.low <= tp) {
          final profit = (entry - tp) * lotSize;
          return Trade(
            isBuy: false,
            entry: entry,
            stopLoss: sl,
            takeProfit: tp,
            lotSize: lotSize,
            isWin: true,
            pnl: profit,
            entryTime: candle.time,
            type: isBuy ? "BUY" : "SELL",
          );
        }
      }
    }

    // If neither hit, treat as breakeven
    return Trade(
      isBuy: isBuy,
      entry: entry,
      stopLoss: sl,
      takeProfit: tp,
      lotSize: lotSize,
      isWin: false,
      pnl: 0,
      entryTime: futureCandles.last.time,
      type: isBuy ? "BUY" : "SELL",
    );
  }
}