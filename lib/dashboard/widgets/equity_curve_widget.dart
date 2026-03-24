import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../provider/equity_chart_provider.dart';

class EquityCurveWidget extends ConsumerStatefulWidget {
  const EquityCurveWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EquityCurveWidgetState();
}

class _EquityCurveWidgetState extends ConsumerState<EquityCurveWidget> {
   ValueNotifier<List<EquityData>> equityCurve = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
   List<EquityData> equity = ref.watch(equityChartProvider);
    equityCurve.value = equity;
    if (equityCurve.value.isEmpty) {
      return const Center(
        child: Text("No trades yet"),
      );
    }
    if(kDebugMode){
      print("Equity Curve Data: ${equityCurve.value.map((e) => {'time': e.time, 'equity': e.equity}).toList()}");
    }
    return ValueListenableBuilder(
      valueListenable: equityCurve,
      builder: (context, value, child) {
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(
            dateFormat: DateFormat.Md(),
            intervalType: DateTimeIntervalType.days,
          ),
          primaryYAxis: NumericAxis(
            opposedPosition: true,
            numberFormat: NumberFormat.simpleCurrency(decimalDigits: 0),
          ),
          series: <CartesianSeries>[
            ColumnSeries<EquityData, DateTime>(
              dataSource: value,
              xValueMapper: (data, index) => data.time,
              yValueMapper: (data, index) => data.equity,
              pointColorMapper: (data, index) => data.color,
              dataLabelSettings: const DataLabelSettings(
                  isVisible: true, labelAlignment: ChartDataLabelAlignment.top),
              dataLabelMapper: (data, index) =>
                  "\$${data.equity.toStringAsFixed(2)}",
              width: 0.2,
              spacing: 0.1,
            )
          ],
        );
      }
    );
  }
}
