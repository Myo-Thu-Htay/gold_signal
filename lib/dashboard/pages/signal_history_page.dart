import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gold_signal/core/signal_engine/provider/signal_validator_provider.dart';
import '../../core/signal_engine/model/trade_signal.dart';

class SignalHistoryPage extends ConsumerStatefulWidget {
  const SignalHistoryPage({super.key});

  @override
  ConsumerState<SignalHistoryPage> createState() => _SignalHistoryPageState();
}

class _SignalHistoryPageState extends ConsumerState<SignalHistoryPage> {
  @override
  Widget build(BuildContext context) {
    List<TradeSignal> signals = ref.watch(signalValidatorProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signal History'),
        centerTitle: true,
      ),
      body: signals.isEmpty
          ? const Center(child: Text("No signal history available"))
          : ListView.builder(
              itemCount: signals.length,
              itemBuilder: (context, index) {
                final signal = signals[index];
                return Dismissible(
                  key: Key(signal.entry.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref
                        .read(signalValidatorProvider.notifier)
                        .removeSignal(signal);
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      onTap: () {
                        // Show detailed signal info on tap
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                'Signal Details',
                                style: TextStyle(
                                    color: signal.isBuy
                                        ? Colors.green
                                        : Colors.red),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Date: ${signal.generatedAt.toLocal().toString()}'),
                                  Text(
                                      'Entry Price: ${signal.entry.toStringAsFixed(2)}'),
                                  Text(
                                      'Stop Loss: ${signal.stopLoss.toStringAsFixed(2)}'),
                                  Text(
                                      'Take Profit: ${signal.takeProfit.toStringAsFixed(2)}'),
                                  Text(
                                      'Lot Size: ${signal.lotSize.toStringAsFixed(2)}'),
                                  Text(
                                      'Confidence: ${(signal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)}%'),
                                  Text(
                                    'Status: ${signal.status.toString().split('.').last.toUpperCase()}',
                                    style: TextStyle(
                                      color: signal.status == SignalStatus.tpHit
                                          ? Colors.green
                                          : signal.status == SignalStatus.slHit
                                              ? Colors.red
                                              : signal.status ==
                                                      SignalStatus.expired
                                                  ? Colors.grey
                                                  : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor:
                            signal.isBuy ? Colors.green : Colors.red,
                        child: Icon(
                          signal.isBuy
                              ? Icons.arrow_outward
                              : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        signal.reason.toString(),
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Type: ${signal.isBuy ? 'BUY' : 'SELL'} | Confidence: ${(signal.confidence.abs() / 20 * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        signal.status == SignalStatus.tpHit
                            ? 'Win'
                            : signal.status == SignalStatus.slHit
                                ? 'Loss'
                                : signal.status == SignalStatus.active
                                    ? 'Active'
                                    : signal.status == SignalStatus.expired
                                        ? 'Expired'
                                        : 'Pending',
                        style: TextStyle(
                          color: signal.status == SignalStatus.tpHit
                              ? Colors.green
                              : signal.status == SignalStatus.slHit
                                  ? Colors.red
                                  : signal.status == SignalStatus.active
                                      ? Colors.blue
                                      : signal.status == SignalStatus.expired
                                          ? Colors.black
                                          : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
