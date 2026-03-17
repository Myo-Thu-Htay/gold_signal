import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/signal_engine/model/trade_signal.dart';
import '../../../signal_engine/model/timeframe.dart';
import '../../../signal_engine/provider/market_provider.dart';
import '../../../signal_engine/provider/signal_provider.dart';
import '../provider/trend_provider.dart';
import '../widgets/trend_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(signalProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold Signal"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            /// PRICE PANEL
            _pricePanel(ref),

            /// TREND PANEL
            _trendPanel(ref),

            /// CHART
            Expanded(
              child: _chartPanel(ref),
            ),

            /// SIGNAL CARD
            /// Only show if we have a valid signal (entry != 0)
            /// This prevents showing a "HOLD" card when we have no signal data yet
            /// The card itself will handle showing "HOLD SIGNAL" if entry == 0
            /// This way we only show the card when we have actual signal data to display
            /// If signalAsync is still loading or has an error, the card won't show at all
            if (signal != null && signal.entry != 0) _signalPanel(signal),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// PRICE
  Widget _pricePanel(WidgetRef ref) {
    final candlesAsync = ref.watch(binanceCandlesProvider);
    final selectedTF = ref.watch(selectedTimeframeProvider);
    return candlesAsync.when(
      data: (candle) {
        return Row(
          children: [
            Text(
              "XAUUSD",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const Spacer(),
            DropdownButton<Timeframe>(
              value: selectedTF,
              items: Timeframe.values.map((tf) {
                return DropdownMenuItem(
                  value: tf,
                  child: Text(
                    tf.label,
                    style: TextStyle(
                        color: tf == selectedTF ? Colors.blue : Colors.indigo),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(selectedTimeframeProvider.notifier).state = value!;
              },
            ),
          ],
        );
      },
      loading: () => const Text("Loading..."),
      error: (e, st) => const Text("Error"),
    );
  }

  /// TREND
  Widget _trendPanel(WidgetRef ref) {
    final trend = ref.watch(trendProvider);
    final signal = ref.watch(signalProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text(
            "Trend: $trend",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const Spacer(),
          Text(
            "Signal: ${(signal?.isBuy == true) ? 'BUY' : (signal?.isBuy == false) ? 'SELL' : 'HOLD'}",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  /// CHART
  Widget _chartPanel(WidgetRef ref) {
    final candlesAsync = ref.watch(binanceCandlesProvider);
    return candlesAsync.when(
      data: (candles) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: TrendWidget(
            trend: candles,
          ),
        );
      },
      loading: () => const Text("Loading..."),
      error: (e, st) => const Text("Error"),
    );
  }
}

/// SIGNAL
Widget _signalPanel(TradeSignal signal) {
  final isBuy = signal.isBuy;
  final risk = (signal.entry - signal.stopLoss).abs();
  final reward = (signal.takeProfit - signal.entry).abs();
  final rr = reward / risk;
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
            isBuy ? "BUY SIGNAL" : "SELL SIGNAL",
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RR:', style: const TextStyle(color: Colors.white)),
                Text('1:${rr.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confidence', style: const TextStyle(color: Colors.white)),
                Text(
                    "${(signal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)} %",
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ),
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
