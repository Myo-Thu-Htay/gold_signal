import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/dashboard/service/controller_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../signal_engine/model/candle.dart';
import '../../../signal_engine/provider/market_provider.dart';
import '../../../signal_engine/services/signal_service.dart';
import '../service/candle_stream_service.dart';

class TrendWidget extends ConsumerStatefulWidget {
  final List<Candle> trend;

  const TrendWidget({super.key, required this.trend});

  @override
  ConsumerState<TrendWidget> createState() => _TrendWidgetState();
}

class _TrendWidgetState extends ConsumerState<TrendWidget> {
  List<Candle> _candles = [];
  final signalService = SignalService();
  StreamSubscription<Candle>? candleStream;
  late TrackballBehavior trackballBehavior;
  final GlobalKey<SfCartesianChartState> _chartKey = GlobalKey();
  final Controller controller = Controller();
  @override
  void initState() {
    super.initState();
    _candles = [...widget.trend];
    _startSocket();
    trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
    );
  }

  @override
  void didUpdateWidget(covariant TrendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trend != widget.trend) {
      setState(() {
        _candles = [...widget.trend];
      });
    }
  }

  void _startSocket() {
    final socketService = CandleStreamService();
    final tf = ref.read(selectedTimeframeProvider);
    socketService.start(tf);
    candleStream = socketService.stream.listen((candle) {
      onCandleUpdate(candle);      
    });
  }

  void onCandleUpdate(Candle candle) {
    final list = [..._candles];
    if (list.isNotEmpty && list.last.time == candle.time) {
      list[list.length - 1] = candle;
    } else {
      list.add(candle);
      if (list.length > 300) {
        list.removeAt(0);
      }
    }
    _candles = list;
    controller.initialCandles(_candles);
    setState(() {});
  }

  @override
  void dispose() {
    candleStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedTrend = _candles.length > 300
        ? _candles.sublist(_candles.length - 300)
        : _candles;
    final lastCandle = sortedTrend.isNotEmpty ? sortedTrend.last : null;
    final lastClose = lastCandle?.close ?? 0.0;
    final volume = lastCandle?.volume ?? 0.0;
    final ma10 = signalService.calculateMA(sortedTrend, 10);
    final rsiValue =
        sortedTrend.isNotEmpty ? signalService.calculateRSI(sortedTrend) : 50.0;
    double minPrice =
        sortedTrend.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double maxPrice =
        sortedTrend.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    DateTime lastTime = lastCandle!.time;
    DateTime futureTime = lastTime.add(Duration(hours: 5));
    int startIndex = sortedTrend.length > 100 ? sortedTrend.length - 100 : 0;
    double open = lastCandle.open;
    double high = lastCandle.high;
    double low = lastCandle.low;
    double close = lastCandle.close;
    return Column(
      children: [
        Flexible(
          flex: 3,
          child: Stack(
            children: [
              SfCartesianChart(
                key: _chartKey,
                trackballBehavior: trackballBehavior,
                annotations: [
                  CartesianChartAnnotation(
                    region: AnnotationRegion.chart,
                    coordinateUnit: CoordinateUnit.point,
                    clip: ChartClipBehavior.hide,
                    horizontalAlignment: ChartAlignment.far,
                    x: lastCandle.time.add(Duration(days: 1)),
                    y: lastClose,
                    widget: Container(
                      decoration: BoxDecoration(
                        color: lastCandle.close >= lastCandle.open
                            ? Colors.green.withValues(alpha: 0.7)
                            : Colors.red.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '\$${lastClose.toStringAsFixed(2)}',
                        style: TextStyle(
                          // color: lastCandle.close >= lastCandle.open
                          //     ? Colors.green
                          //     : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                primaryXAxis: DateTimeAxis(
                  minimum: sortedTrend.first.time,
                  maximum: futureTime,
                  initialVisibleMinimum: sortedTrend[startIndex + 10].time,
                  initialVisibleMaximum: futureTime,
                  enableAutoIntervalOnZooming: false,
                  intervalType: DateTimeIntervalType.minutes,
                  dateFormat: DateFormat('dd,MM,yy HH:mm:ss'),
                  majorGridLines: MajorGridLines(width: 0),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                ),
                primaryYAxis: NumericAxis(
                  minimum: minPrice,
                  maximum: maxPrice,
                  anchorRangeToVisiblePoints: true,
                  numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
                  opposedPosition: true,
                  decimalPlaces: 2,
                  majorGridLines: MajorGridLines(width: 0.5),
                  rangePadding: ChartRangePadding.round,
                  plotBands: [
                    PlotBand(
                      isVisible: true,
                      start: lastClose,
                      end: lastClose,
                      borderColor: lastCandle.close >= lastCandle.open
                          ? Colors.green
                          : Colors.red,
                      borderWidth: 1,
                      dashArray: [6, 4],
                      shouldRenderAboveSeries: true,
                    ),
                  ],
                ),
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: true,
                  enablePanning: true,
                  enableDoubleTapZooming: true,
                  zoomMode: ZoomMode.x,
                ),
                series: <CartesianSeries<Candle, DateTime>>[
                  CandleSeries<Candle, DateTime>(
                    // onRendererCreated: (controller) => _seriesController = controller,
                    initialSelectedDataIndexes: [sortedTrend.length - 100],
                    animationDuration: 0,
                    dataSource: sortedTrend,
                    enableSolidCandles: true,
                    enableTooltip: true,
                    xValueMapper: (value, index) => value.time,
                    lowValueMapper: (value, index) => value.low,
                    highValueMapper: (value, index) => value.high,
                    openValueMapper: (value, index) => value.open,
                    closeValueMapper: (value, index) => value.close,
                    width: 0.8,
                    showIndicationForSameValues: true,
                    spacing: 0.08,
                    borderWidth: 1,
                  ),
                ],
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'O: ${open.toStringAsFixed(2)}  H: ${high.toStringAsFixed(2)}  L: ${low.toStringAsFixed(2)}  C: ${close.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'RSI: ${rsiValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'MA(10): ${ma10.last.close.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Vol: ${volume.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
