import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../signal_engine/provider/equity_curve_provider.dart';
import '../provider/trade_history_provider.dart';
import '../widgets/equity_curve_widget.dart';
import '../widgets/trade_stats_widget.dart';
import 'view_trade.dart';

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equityCurve = ref.watch(equityCurveProvider);
    final trades = ref.watch(tradeHistoryProvider);
    final openTrades = trades.where((t) => t.isOpen).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio & PnL"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(equityCurveProvider);
              ref.invalidate(tradeHistoryProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Flexible(child: const TradeStatsWidget()),
          const SizedBox(height: 16),
          Flexible(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Card(
                color: Colors.blueGrey.shade100,
                margin: const EdgeInsets.all(16),
                child: EquityCurveWidget(
                    equityCurve: equityCurve), // Draw equity curve
              ),
            ),
          ),
          openTrades.isEmpty
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      "No open trades",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : Flexible(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: openTrades.length,
                      itemBuilder: (context, index) {
                        final trade = openTrades[index];
                        return Dismissible(
                          key: Key(trade.entryTime.toString()),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            ref
                                .read(tradeHistoryProvider.notifier)
                                .deleteTrade(index);
                          },
                          child: Card(
                            child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      trade.isBuy ? Colors.green : Colors.red,
                                  child: Text(
                                    trade.type,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                                title: Text(
                                    "Entry: ${trade.entry}  Exit: ${trade.exitPrice}"),
                                subtitle: Text(
                                    "Lot: ${trade.lotSize}  Time: ${trade.entryTime.toLocal()}"),
                                trailing: Text(
                                  "\$${trade.pnl.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: trade.pnl >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ViewTradePage(trade: trade),
                                    ),
                                  );
                                }),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
