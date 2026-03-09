import 'package:dio/dio.dart';
import 'package:gold_signal/core/constants/trading_constants.dart';
import '../model/candle.dart';

class BinanceApiService {
  final Dio dio = Dio();
  String baseUrl = TradingConstants.binanceApi;
  String symbol = TradingConstants.binanceSymbol;

  //Fetch XAUUSDT futures candles
  Future<List<Candle>> getCandles(String interval, {int limit = 1000}) async {
    try {
      final response = await dio.get(baseUrl, queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit,
      });
      final data = response.data as List;
      List<Candle> candles = data
          .map<Candle>(
            (kline) => Candle(
                time: DateTime.fromMillisecondsSinceEpoch(kline[0]),
                open: double.parse(kline[1]),
                high: double.parse(kline[2]),
                low: double.parse(kline[3]),
                close: double.parse(kline[4]),
                volume: double.parse(kline[5])),
          )
          .toList();
     
      return candles;
    } catch (e) {
      throw Exception('Error Fetching Binance Candles : $e');
    }
  }
}
