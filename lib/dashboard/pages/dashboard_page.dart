import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/signal_engine/services/signal_service.dart';
import '../../signal_engine/model/timeframe.dart';
import '../../signal_engine/provider/market_provider.dart';
import '../../signal_engine/provider/signal_provider.dart';
import '../widgets/trend_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candlesAsync = ref.watch(binanceCandlesProvider);
    final signalAsync = ref.watch(signalProvider);
    final selectedTF = ref.watch(selectedTimeframeProvider);
    final bCandlesAsync = ref.watch(getBinanceCandles);

    return Scaffold(
      appBar: AppBar(
        //PRICE PANEL 
        title: _pricePanel(ref,candlesAsync,selectedTF),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// PRICE PANEL
          //_pricePanel(ref, candlesAsync, selectedTF),

          /// TREND PANEL
          _trendPanel(signalAsync, bCandlesAsync),

          /// CHART
          Expanded(
            child: _chartPanel(candlesAsync, signalAsync),
          ),

          /// SIGNAL CARD
          _signalPanel(signalAsync),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// PRICE
  Widget _pricePanel(
      WidgetRef ref, AsyncValue candlesAsync, Timeframe selectedTF) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.black,
        child: candlesAsync.when(
          data: (candle) {
            return Row(
              children: [
                Text(
                  "XAUUSD",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const Spacer(),
                DropdownButton<Timeframe>(
                  dropdownColor: Colors.black,
                  style: TextStyle(color: Colors.white),
                  value: selectedTF,
                  items: Timeframe.values.map((tf) {
                    return DropdownMenuItem(
                      value: tf,
                      child:
                          Text(tf.label, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    ref.read(selectedTimeframeProvider.notifier).state = value!;
                    // Trigger signal refresh
                    ref.invalidate(binanceCandlesProvider);
                    ref.invalidate(signalProvider);
                   
                  },
                ),
                const Spacer(),
                Text(
                  candle.isNotEmpty
                      ? candle.last.close.toStringAsFixed(2)
                      : "0.00",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: candle.isNotEmpty &&
                            candle.last.close >= candle.last.open
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            );
          },
          loading: () => const Text("Loading..."),
          error: (e, st) => const Text("Error"),
        ));
  }

  /// TREND
  Widget _trendPanel(AsyncValue signalAsync, AsyncValue bCandlesAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.grey[200],
      child: bCandlesAsync.when(
        data: (candle) {
          final SignalService scoreService = SignalService();
          final score = scoreService.calculateConfidence(candle);
          final quality = scoreService.quality(score);
          return signalAsync.when(
            data: (signal) {
              final trend = signal.isBuy ? "Bullish" : "Bearish";
              return Row(
                children: [
                  Text(
                    "Trend: $trend",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Spacer(),
                  Text(
                    "Signal Quality: $quality",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              );
            },
            loading: () => const Text("Loading..."),
            error: (e, st) => const Text("Error"),
          );
        },
        loading: () => const Text("Loading..."),
        error: (e, st) => const Text("Error"),
      ),
    );
  }

  /// CHART
  Widget _chartPanel(AsyncValue candlesAsync, AsyncValue signalAsync) {
    return candlesAsync.when(
      data: (candles) {
        final signal = signalAsync.asData?.value;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return TrendWidget(
                trend: candles,
                isBuySignal: signal?.isBuy ?? false,
                isHoldSignal: signal?.entry == 0,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text("Error: $e"),
    );
  }

  /// SIGNAL
  Widget _signalPanel(AsyncValue signalAsync) {
    return signalAsync.when(
      data: (signal) {
        final isBuy = signal.isBuy;
        return Card(
          color: (isBuy && signal.entry != 0)
              ? Colors.green
              : (!isBuy && signal.entry != 0)
                  ? Colors.red
                  : Colors.grey,
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  (isBuy && signal.entry != 0)
                      ? "BUY SIGNAL"
                      : (!isBuy && signal.entry != 0)
                          ? "SELL SIGNAL"
                          : "HOLD SIGNAL",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _row("Entry", signal.entry),
                _row("Stop Loss", signal.stopLoss),
                _row("Take Profit", signal.takeProfit),
                _row("Lot Size", signal.lotSize),
                _row("RR", signal.riskReward),
                _row(
                  "Confidence",
                  (signal.confidence / 10).toDouble(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, st) => const SizedBox(),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
