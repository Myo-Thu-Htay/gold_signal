import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../core/signal_engine/model/candle.dart';
import '../../core/signal_engine/services/signal_service.dart';
import '../provider/controller_provider.dart';
import '../service/controller_service.dart';

class TrendWidget extends ConsumerStatefulWidget {
  final List<Candle> trend;

  const TrendWidget({super.key, required this.trend});

  @override
  ConsumerState<TrendWidget> createState() => _TrendWidgetState();
}

class _TrendWidgetState extends ConsumerState<TrendWidget> {
  final SignalService signalService = SignalService();
  late TrackballBehavior trackballBehavior;
  late Controller controller;
  final GlobalKey<SfCartesianChartState> chartKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    controller = ref.read(controllerProvider);
    controller.initialCandles([...widget.trend]);
    trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
    );
  }

  double _calculateYPosition(
    double min,
    double max,
    double price,
    BuildContext context,
  ) {
    final height = MediaQuery.of(context).size.height *
        0.3561; // adjust based on your chart height
    final percent = (price - min) / (max - min);

    return height - (percent * height);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Candle>>(
      valueListenable: controller.candles,
      builder: (context, candles, _) {
        if (candles.isEmpty) {
          return const Center(child: Text("No Data"));
        }

        /// 🔹 Limit candles (performance + clarity)
        final sortedTrend = candles.length > 300
            ? candles.sublist(candles.length - 300)
            : candles;

        /// 🔹 Visible range (last 100 candles)
        final visibleCandles = sortedTrend.length > 100
            ? sortedTrend.sublist(sortedTrend.length - 100)
            : sortedTrend;

        final lastCandle = sortedTrend.last;
        final lastClose = lastCandle.close;
        final volume = lastCandle.volume;

        /// 🔹 Indicators
        final ma10 = signalService.calculateMA(sortedTrend, 10);
        final rsi = signalService.calculateRSI(sortedTrend);

        /// 🔹 SAFE Min/Max calculation (FIXED 🔥)
        double minPrice =
            visibleCandles.map((c) => c.low).reduce((a, b) => a < b ? a : b);

        double maxPrice =
            visibleCandles.map((c) => c.high).reduce((a, b) => a > b ? a : b);

        /// 🔹 Padding (better UI)
        final padding = (maxPrice - minPrice) * 0.1;

        final chartMin = minPrice - padding;
        final chartMax = maxPrice + padding;

        /// 🔹 Time
        final lastTime = lastCandle.time;
        final futureTime = lastTime.add(const Duration(hours: 5));

        return Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  SfCartesianChart(
                    trackballBehavior: trackballBehavior,
                    key: chartKey,

                    /// 🔹 Axis
                    primaryXAxis: DateTimeAxis(
                      minimum: visibleCandles.first.time,
                      maximum: futureTime,
                      initialVisibleMinimum: visibleCandles.first.time,
                      initialVisibleMaximum: futureTime,
                      intervalType: DateTimeIntervalType.minutes,
                      dateFormat: DateFormat('dd MMM HH:mm'),
                      majorGridLines: const MajorGridLines(width: 0),
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                    ),

                    primaryYAxis: NumericAxis(
                      minimum: chartMin,
                      maximum: chartMax,
                      opposedPosition: true,
                      decimalPlaces: 2,
                      numberFormat:
                          NumberFormat.simpleCurrency(decimalDigits: 2),
                      majorGridLines: const MajorGridLines(width: 0.5),

                      /// 🔹 Current price line
                      plotBands: [
                        PlotBand(
                          isVisible: true,
                          start: lastClose,
                          end: lastClose,
                          borderColor: lastCandle.close >= lastCandle.open
                              ? Colors.green
                              : Colors.red,
                          borderWidth: 1,
                          dashArray: const [6, 4],
                        ),
                      ],
                    ),

                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      enableDoubleTapZooming: true,
                      zoomMode: ZoomMode.x,
                    ),

                    /// 🔹 Candle Series
                    series: <CandleSeries<Candle, DateTime>>[
                      CandleSeries<Candle, DateTime>(
                        dataSource: sortedTrend,
                        xValueMapper: (c, _) => c.time,
                        lowValueMapper: (c, _) => c.low,
                        highValueMapper: (c, _) => c.high,
                        openValueMapper: (c, _) => c.open,
                        closeValueMapper: (c, _) => c.close,
                        animationDuration: 0,
                        enableSolidCandles: true,
                        width: 0.8,
                        spacing: 0.05,
                        borderWidth: 1,
                      ),
                    ],
                  ),

                  /// 🔹 OHLC Info
                  Positioned(
                    top: 10,
                    left: 20,
                    child: Text(
                      'O: ${lastCandle.open.toStringAsFixed(2)}  '
                      'H: ${lastCandle.high.toStringAsFixed(2)}  '
                      'L: ${lastCandle.low.toStringAsFixed(2)}  '
                      'C: ${lastCandle.close.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),

                  /// 🔹 Price Label
                  Positioned(
                    right: 20,
                    top: _calculateYPosition(
                        chartMin, chartMax, lastClose, context),
                    child: Row(
                      children: [
                        Text(
                          "--",
                          style: TextStyle(
                            color: lastCandle.close >= lastCandle.open
                                ? Colors.green.withAlpha(200)
                                : Colors.red.withAlpha(200),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: lastCandle.close >= lastCandle.open
                                ? Colors.green.withAlpha(200)
                                : Colors.red.withAlpha(200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\$${lastClose.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            /// 🔹 Indicators Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'RSI: ${rsi.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MA(10): ${ma10.last.close.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vol: ${volume.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
