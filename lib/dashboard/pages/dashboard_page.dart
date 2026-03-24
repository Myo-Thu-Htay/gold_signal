import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/core/signal_engine/model/trade_signal.dart';
import '../../core/signal_engine/model/timeframe.dart';
import '../../core/signal_engine/provider/market_provider.dart';
import '../../core/signal_engine/provider/signal_provider.dart';
import '../provider/market_stream_provider.dart';
import '../provider/trend_provider.dart';
import '../widgets/trend_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(signalProvider);
    final candlesAsync = ref.watch(binanceCandlesProvider);
    return Scaffold(
      appBar: AppBar(
        /// PRICE PANEL
        title: _pricePanel(ref),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Column(
          children: [
            /// TREND PANEL
            _trendPanel(ref),

            /// CHART
            Expanded(
              child: candlesAsync.when(
                data: (candles) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TrendWidget(trend: candles)),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                    const Center(child: Text("Error loading chart data")),
              ),
            ),

            /// SIGNAL CARD
            /// Only show if we have a valid signal (entry != 0)
            /// This prevents showing a "HOLD" card when we have no signal data yet
            /// The card itself will handle showing "HOLD SIGNAL" if entry == 0
            /// This way we only show the card when we have actual signal data to display
            /// If signalAsync is still loading or has an error, the card won't show at all
            if (signal != null)
              SizedBox(height: 266, child: _signalPanel(signal)),
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
            const Text("Gold Signal"),
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
                ref.read(
                    marketStreamProvider); // Restart the market stream with the new timeframe
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(
            "Trend: $trend",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const Spacer(),
          Text(
            "Signal: ${(signal?.status == SignalStatus.active && signal?.isBuy == true) ? 'BUY' : (signal?.status == SignalStatus.active && signal?.isBuy == false) ? 'SELL' : 'HOLD'}",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  /// SIGNAL
  Widget _signalPanel(TradeSignal signal) {
    final isBuy = signal.isBuy;
    return Card(
      color: (isBuy && signal.entry != 0)
          ? Colors.green
          : (!isBuy && signal.entry != 0)
              ? Colors.red
              : Colors.grey,
      //margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              signal.status == SignalStatus.active && signal.isBuy == true
                  ? "BUY SIGNAL"
                  : signal.status == SignalStatus.active &&
                          signal.isBuy == false
                      ? "SELL SIGNAL"
                      : "HOLD SIGNAL",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status:', style: const TextStyle(color: Colors.white)),
                  Text(signal.status.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
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
                  Text('1:${signal.rr.abs().toStringAsFixed(0)}',
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
}
