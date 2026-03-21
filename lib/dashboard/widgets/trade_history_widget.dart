import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_strings.dart';
import '../provider/controller_provider.dart';
import '../provider/setting_provider.dart';
import '../provider/trade_history_provider.dart';
import '../pages/trade_view_page.dart';
import '../provider/account_provider.dart';

class TradeHistoryScreen extends ConsumerWidget {
  const TradeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trades = ref.watch(tradeHistoryProvider);
    final controller = ref.watch(controllerProvider);
    final candles = controller.candles;
    final settingAsync = ref.watch(settingsProvider);
    return settingAsync.when(
      data: (settings) => SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppStrings.text('tradeHistory', settings.languageCode),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            trades.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child:
                          Text("No trades yet. Start trading to see history!"),
                    ),
                  )
                : ListView.builder(
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
                            title: ValueListenableBuilder(
                                valueListenable: candles,
                                builder: (context, value, child) {
                                  return Text(
                                      "\$${trade.entry.toStringAsFixed(2)} ==> \$ ${trade.isOpen ? value.last.close.toStringAsFixed(2) : trade.isWin ? trade.takeProfit.toStringAsFixed(2) : (!trade.isWin && trade.exitPrice != null) ? trade.exitPrice!.toStringAsFixed(2) : trade.stopLoss.toStringAsFixed(2)}");
                                }),
                            subtitle: Text(
                                "SL: ${trade.stopLoss.toStringAsFixed(2)}  TP: ${trade.takeProfit.toStringAsFixed(2)}"),
                            trailing: Column(
                              children: [
                                ValueListenableBuilder(
                                    valueListenable: controller.livePrice,
                                    builder: (context, value, child) {
                                      ValueNotifier pnl = ValueNotifier(0.0);
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
                                      controller.calculateAccBalance(
                                          ref.read(accountProvider).balance,
                                          pnl.value);
                                      return Text(
                                        "\$${pnl.value.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: pnl.value >= 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }),
                                Text("Lot: ${trade.lotSize}"),
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
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text("Error loading settings: $error")),
      ),
    );
  }
}
