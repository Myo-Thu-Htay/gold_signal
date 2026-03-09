import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../signal_engine/model/candle.dart';
import '../../../signal_engine/provider/market_provider.dart';
import '../models/trade_model.dart';
import '../provider/trade_history_provider.dart';
import '../widgets/timepicker_widget.dart';

class ViewTradePage extends ConsumerStatefulWidget {
  final Trade trade;

  const ViewTradePage({super.key, required this.trade});

  @override
  ConsumerState<ViewTradePage> createState() => _ViewTradePageState();
}

class _ViewTradePageState extends ConsumerState<ViewTradePage> {
  bool isBuy = true;
  DateTime entryTime = DateTime.now().toUtc();
  DateTime exitTime = DateTime.now().toUtc();
  final entryController = TextEditingController();
  final slController = TextEditingController();
  final tpController = TextEditingController();
  final lotController = TextEditingController();
  final exitPrice = TextEditingController();
  String result = "TP";

  double pnlPreview = 0;

  void calculatePreview(bool isBuy) async {
    final entry = double.tryParse(entryController.text);
    final sl = double.tryParse(slController.text);
    final tp = double.tryParse(tpController.text);
    final lot = double.tryParse(lotController.text);
    final exitManual = double.tryParse(exitPrice.text);

    if (entry == null || sl == null || tp == null || lot == null) return;

    double exit = 0;
    List<Candle> candles = await ref.read(binanceCandlesProvider.future);
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      if (result == "TP") {
        exit = tp;
      } else if (result == "SL") {
        exit = sl;
      } else if (result == "Manual") {
        exit = exitManual!;
      } else {
        if (isBuy) {
          lastCandle.low <= sl ? exit = sl : exit = lastCandle.close;
          lastCandle.high >= tp ? exit = tp : exit = lastCandle.close;
        } else {
          lastCandle.high >= sl ? exit = sl : exit = lastCandle.close;
          lastCandle.low <= tp ? exit = tp : exit = lastCandle.close;
        }
      }
    }

    final pnl = isBuy ? (exit - entry) * lot * 100 : (entry - exit) * lot * 100;

    setState(() {
      pnlPreview = pnl;
    });
  }

  Future<void> pickTime(bool isEntry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isEntry ? entryTime : exitTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    final Duration? time = await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => TimePickerWidget(
            initialTime: TimeOfDay.now(),
            onTimeChanged: (t) => Navigator.pop(context, t)));

    if (time == null) return;

    final finalDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.inHours,
      time.inMinutes % 60,
      time.inSeconds % 60,
    );

    setState(() {
      if (isEntry) {
        entryTime = finalDate;
      } else {
        exitTime = finalDate;
      }
    });
  }

  void addTrade(bool isOpen, bool isBuy) async {
    final entry = double.tryParse(entryController.text);
    final sl = double.tryParse(slController.text);
    final tp = double.tryParse(tpController.text);
    final lot = double.tryParse(lotController.text);
    final exitManual = double.tryParse(exitPrice.text);

    if (entry == null || sl == null || tp == null || lot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid values")),
      );
      return;
    }

    double exit = 0;
    List<Candle> candles = await ref.read(binanceCandlesProvider.future);
    if (candles.isNotEmpty) {
      final lastCandle = candles.last;
      if (result == "TP") {
        exit = tp;
      } else if (result == "SL") {
        exit = sl;
      } else if (result == "Manual") {
        exit = exitManual!;
      } else {
        ref
            .watch(tradeHistoryProvider.notifier)
            .checkTradeAutoClose(lastCandle.close);
        if (isBuy) {
          lastCandle.low <= sl ? exit = sl : exit = lastCandle.close;
          lastCandle.high >= tp ? exit = tp : exit = lastCandle.close;
        } else {
          lastCandle.high >= sl ? exit = sl : exit = lastCandle.close;
          lastCandle.low <= tp ? exit = tp : exit = lastCandle.close;
        }
      }
    }

    ref.read(tradeHistoryProvider.notifier).addManualTrade(
          isBuy: isBuy,
          entry: entry,
          exit: exit,
          sl: sl,
          tp: tp,
          lot: lot,
          entryTime: entryTime,
          exitTime: exitTime,
          isOpen: isOpen,
        );

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Trade Added")),
    );
  }

  @override
  void dispose() {
    entryController.clear();
    slController.clear();
    tpController.clear();
    lotController.clear();
    exitPrice.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trade History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref
                  .read(tradeHistoryProvider.notifier)
                  .deleteTradeByTime(widget.trade.entryTime);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: widget.trade.isWin
                        ? Colors.green
                        : widget.trade.isOpen
                            ? Colors.blue
                            : Colors.red,
                    width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("XAUUSD "),
                      const SizedBox(width: 10),
                      Text(widget.trade.type),
                      const SizedBox(width: 10),
                      Text("Lot: ${widget.trade.lotSize}"),
                      const SizedBox(width: 20),
                      Text(
                        widget.trade.isWin
                            ? "TP Hit"
                            : widget.trade.isOpen
                                ? "Open"
                                : "SL Hit",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.trade.isWin
                                ? Colors.green
                                : widget.trade.isOpen
                                    ? Colors.blue
                                    : Colors.red),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(widget.trade.entry.toString()),
                      const SizedBox(width: 10),
                      Text("==>"),
                      const SizedBox(width: 10),
                      Text(widget.trade.exitPrice.toString()),
                      const SizedBox(width: 30),
                      Text(
                        '\$${widget.trade.pnl.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.trade.pnl >= 0
                                ? Colors.green
                                : Colors.red),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("SL: "),
                      const SizedBox(width: 10),
                      Text(widget.trade.stopLoss.toString()),
                      const SizedBox(width: 20),
                      Text("TP: "),
                      const SizedBox(width: 10),
                      Text(widget.trade.takeProfit.toString()),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Entry Time: "),
                      const SizedBox(width: 10),
                      Text(widget.trade.entryTime.toString()),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Exit Time: "),
                      const SizedBox(width: 10),
                      Text(widget.trade.exitTime.toString()),
                    ],
                  ),
                ],
              ),
            ),
            (result != "TP" || result != "SL")
                ? ExpansionTile(
                    title: const Text("Edit Trade"),
                    children: [
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stop loss';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        controller: slController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Stop Loss",
                        ),
                        onChanged: (_) => calculatePreview(isBuy),
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter take profit';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        controller: tpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Take Profit",
                        ),
                        onChanged: (_) => calculatePreview(isBuy),
                      ),
                      result == "Manual"
                          ? TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter exit price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                              controller: exitPrice,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: "Exit Price"),
                              onChanged: (_) => calculatePreview(isBuy),
                            )
                          : const SizedBox(),
                      const SizedBox(height: 10),
                      result != "Open"
                          ? TextButton(
                              onPressed: () => pickTime(false),
                              child: Text(
                                "Exit Time: ${exitTime.toString().substring(0, 16)}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(height: 10),
                      Text(
                        "PnL Preview: \$${pnlPreview.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: pnlPreview >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () => result == "Open"
                            ? addTrade(true, isBuy)
                            : addTrade(false, isBuy),
                        child: const Text("Save Trade"),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
