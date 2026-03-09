import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/trade_history_provider.dart';
import 'view_trade.dart';

class TradeHistoryScreen extends ConsumerWidget {
  const TradeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trades = ref.watch(tradeHistoryProvider);
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            "Trade History",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index];
              return Dismissible(
                key: Key(trade.entryTime.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref.read(tradeHistoryProvider.notifier).deleteTrade(index);
                },
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: trade.isBuy ? Colors.green : Colors.red,
                      child: Text(
                        trade.type,
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    title: Text("\$${trade.entry} ==> \$${trade.exitPrice}"),
                    subtitle:
                        Text("SL: ${trade.stopLoss}  TP: ${trade.takeProfit}"),
                    trailing: Column(
                      children: [
                        Text(
                          "\$${trade.pnl.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: trade.pnl >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Lot: ${trade.lotSize}"),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewTradePage(trade: trade),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
