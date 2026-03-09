import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../model/candle.dart';

class BinanceFuturesSocketService {
  late WebSocketChannel _channel;

  void connect({
    required String symbol,
    required String interval,
    required Function(Candle candle) onUpdate,
  }) {
    final url =
        'wss://fstream.binance.com/ws/${symbol.toLowerCase()}@kline_$interval';
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      final k = data['k'];
      final candle = Candle(
        time: DateTime.fromMillisecondsSinceEpoch(k['t']),
        open: double.parse(k['o']),
        high: double.parse(k['h']),
        low: double.parse(k['l']),
        close: double.parse(k['c']),
        volume: double.parse(k['v']),
      );
      onUpdate(candle);
    });
  }

  void dispose() {
    _channel.sink.close();
  }
}