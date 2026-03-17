import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/equity_curve_provider.dart';
import '../provider/controller_provider.dart';
import '../provider/trade_history_provider.dart';
import '../widgets/equity_curve_widget.dart';
import '../widgets/trade_stats_widget.dart';
import 'trade_view_page.dart';

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equityCurve = ref.watch(equityCurveProvider);
    final trades = ref.watch(tradeHistoryProvider);
    final openTrades = trades.where((t) => t.isOpen).toList();
    final controller = ref.watch(controllerProvider);
    final candles = controller.candles;
    final pnl = ValueNotifier(0.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio & PnL"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(equityCurveProvider);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: const TradeStatsWidget(),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Card(
              color: Colors.blueGrey.shade100,
              margin: const EdgeInsets.all(16),
              child: EquityCurveWidget(
                  equityCurve: equityCurve), // Draw equity curve
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                              child: ValueListenableBuilder(
                                  valueListenable: controller.livePrice,
                                  builder: (context, value, child) {
                                    if (trades.isNotEmpty) {
                                      pnl.value = controller.calculatePreview(
                                        candles.value,
                                        trade.isBuy,
                                        trade.entry,
                                        trade.stopLoss,
                                        trade.takeProfit,
                                        trade.lotSize,
                                        value,
                                        trade.isOpen
                                            ? "Open"
                                            : trade.isWin
                                                ? "TP"
                                                : "SL",
                                      );
                                    }
                                    return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: trade.isBuy
                                              ? Colors.green
                                              : Colors.red,
                                          child: Text(
                                            trade.type,
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        title: Text(
                                            "\$${trade.entry.toStringAsFixed(2)}  ==> \$${value.toStringAsFixed(2)}"),
                                        subtitle: Text(
                                            "SL: ${trade.stopLoss.toStringAsFixed(2)}  TP: ${trade.takeProfit.toStringAsFixed(2)}"),
                                        trailing: Column(
                                          children: [
                                            Text(
                                              "\$${pnl.value.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color: pnl.value >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text("Lot: ${trade.lotSize}")
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewTradePage(trade: trade),
                                            ),
                                          );
                                        });
                                  }),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
