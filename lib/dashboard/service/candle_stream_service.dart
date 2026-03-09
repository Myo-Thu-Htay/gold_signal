import 'dart:async';
import '../../../signal_engine/api/binance_futures_socket.dart';
import '../../../signal_engine/model/candle.dart';
import '../../../signal_engine/model/timeframe.dart';

class CandleStreamService {
  final _controller = StreamController<Candle>.broadcast();
  Stream<Candle> get stream => _controller.stream;

  final BinanceFuturesSocketService _socket = BinanceFuturesSocketService();

  void start(Timeframe tf) {
    _socket.connect(
      symbol: 'xauusdt',
      interval: mapTimeFrameToBinance(tf),
      onUpdate: (candle) {
        _controller.add(candle);
      },
    );
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

  void dispose() {
    _socket.dispose();
    _controller.close();
  }
}