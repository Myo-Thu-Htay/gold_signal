import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EquityCurveWidget extends StatelessWidget {
  final List<double> equityCurve;

  const EquityCurveWidget({
    super.key,
    required this.equityCurve,
  });

  @override
  Widget build(BuildContext context) {
    if (equityCurve.isEmpty) {
      return const Center(
        child: Text("No trades yet"),
      );
    }
    return SfCartesianChart(
      annotations: [
        CartesianChartAnnotation(
          widget: Text(
            "\$${equityCurve.last.toStringAsFixed(2)}",
            style: TextStyle(
                color: equityCurve.last >= equityCurve.first
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          coordinateUnit: CoordinateUnit.point,
          x: DateTime.now()
              .toLocal()
              .add(Duration(seconds: equityCurve.length + 120)),// Place annotation at the end of the curve
          y: equityCurve.last,
        )
      ],
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.Md(),
        intervalType: DateTimeIntervalType.minutes,
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        numberFormat: NumberFormat.simpleCurrency(decimalDigits: 0),
      ),
      series: <CartesianSeries<double, DateTime>>[
        ColumnSeries<double, DateTime>(
          dataSource: equityCurve,
          xValueMapper: (value, index) =>
              DateTime.now().toLocal().add(Duration(minutes: index)),
          yValueMapper: (value, index) => value,
        )
      ],
    );
  }
}
